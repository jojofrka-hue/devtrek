import http from 'node:http';

const PORT = Number(process.env.PORT ?? 8787);
const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY;
const MODEL = process.env.ANTHROPIC_MODEL ?? 'claude-3-5-haiku-latest';
const MAX_BODY_BYTES = 16 * 1024;
const MAX_REQUESTS_PER_MINUTE = 20;

const hits = new Map();

function rateLimited(ip) {
  const now = Date.now();
  const windowStart = now - 60_000;
  const timestamps = (hits.get(ip) ?? []).filter((t) => t > windowStart);
  timestamps.push(now);
  hits.set(ip, timestamps);
  return timestamps.length > MAX_REQUESTS_PER_MINUTE;
}

function json(res, status, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks = [];
    req.on('data', (chunk) => {
      size += chunk.length;
      if (size > MAX_BODY_BYTES) {
        reject(new Error('payload-too-large'));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => {
      try {
        resolve(JSON.parse(Buffer.concat(chunks).toString('utf8') || '{}'));
      } catch {
        reject(new Error('invalid-json'));
      }
    });
    req.on('error', reject);
  });
}

function buildPrompt({ language, question, userAnswer, correctAnswer, code }) {
  const arabic = language === 'ar';
  const lines = [
    arabic
      ? 'أنت مساعد تعليمي لطيف داخل تطبيق لتعلم البرمجة. اشرح خطأ الطالب بالعربية الفصحى المبسطة.'
      : 'You are a friendly teaching assistant inside a programming-learning app. Explain the student mistake in simple English.',
    arabic
      ? 'كن مختصراً (3 إلى 5 جمل)، ركّز على سبب الخطأ وكيف يتذكّر القاعدة لاحقاً، ولا تكتب الحل كاملاً إن كان الطالب يستطيع استنتاجه.'
      : 'Be concise (3-5 sentences), focus on why the answer is wrong and how to remember the rule, and do not just dump the solution if the student can infer it.',
    '',
    `${arabic ? 'السؤال' : 'Question'}: ${question}`,
    `${arabic ? 'إجابة الطالب' : "Student's answer"}: ${userAnswer || '—'}`,
    `${arabic ? 'الإجابة الصحيحة' : 'Correct answer'}: ${correctAnswer}`,
  ];
  if (code) lines.push(`${arabic ? 'الكود' : 'Code'}:\n${code}`);
  return lines.join('\n');
}

async function explain(payload) {
  const { language, question, userAnswer, correctAnswer, code } = payload ?? {};
  if (!ANTHROPIC_API_KEY) {
    const error = new Error('missing-api-key');
    error.status = 500;
    throw error;
  }
  if (typeof question !== 'string' || typeof correctAnswer !== 'string') {
    const error = new Error('bad-request');
    error.status = 400;
    throw error;
  }

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 350,
      messages: [
        {
          role: 'user',
          content: buildPrompt({
            language,
            question,
            userAnswer,
            correctAnswer,
            code,
          }),
        },
      ],
    }),
  });

  if (!response.ok) {
    const detail = await response.text();
    console.error('Anthropic error', response.status, detail.slice(0, 500));
    const error = new Error('upstream-error');
    error.status = 502;
    throw error;
  }

  const data = await response.json();
  const text = (data.content ?? [])
    .filter((part) => part.type === 'text')
    .map((part) => part.text)
    .join('\n')
    .trim();

  if (!text) {
    const error = new Error('empty-response');
    error.status = 502;
    throw error;
  }
  return text;
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    });
    res.end();
    return;
  }

  if (req.method === 'GET' && req.url === '/health') {
    json(res, 200, { ok: true, configured: Boolean(ANTHROPIC_API_KEY), model: MODEL });
    return;
  }

  if (req.method !== 'POST' || req.url !== '/explain') {
    json(res, 404, { ok: false, error: 'not-found' });
    return;
  }

  const ip = req.socket.remoteAddress ?? 'unknown';
  if (rateLimited(ip)) {
    json(res, 429, { ok: false, error: 'too-many-requests' });
    return;
  }

  try {
    const payload = await readBody(req);
    const explanation = await explain(payload);
    json(res, 200, { explanation });
  } catch (error) {
    const status = error.status ?? 400;
    if (status >= 500) console.error(error.message);
    json(res, status, { ok: false, error: error.message });
  }
});

server.listen(PORT, () => {
  console.log(`Coding Quest AI proxy listening on http://localhost:${PORT}`);
  if (!ANTHROPIC_API_KEY) {
    console.warn('ANTHROPIC_API_KEY is not set — /explain will return 500.');
  }
});

# Coding Quest AI proxy

The Flutter app never contains an API key. It calls this small Node server, and
the server is the only place that talks to Anthropic.

## Run

```bash
cd server
export ANTHROPIC_API_KEY=sk-ant-...     # PowerShell: $env:ANTHROPIC_API_KEY="..."
node index.js
```

No dependencies are needed (Node 18+ has `fetch`). The server listens on
`http://localhost:8787`.

## Endpoints

- `GET /health` → `{ ok, configured, model }`
- `POST /explain`

```json
{
  "language": "ar",
  "question": "What does this print?",
  "userAnswer": "3",
  "correctAnswer": "4",
  "code": "int x = 2; cout << x + 2;"
}
```

Response: `{ "explanation": "..." }`.

## Notes

- In the Flutter app open **Settings → AI server URL** and set the address the
  app can reach:
  - Android emulator: `http://10.0.2.2:8787`
  - iOS simulator / desktop / web: `http://localhost:8787`
  - Physical phone: `http://<your-computer-LAN-IP>:8787` (same Wi-Fi network)
- The proxy has a 16 KB body cap and a simple per-IP rate limit (20 req/min).
- Keep `ANTHROPIC_API_KEY` out of source control. `.env.example` shows the
  expected variable names; this server reads the environment directly.

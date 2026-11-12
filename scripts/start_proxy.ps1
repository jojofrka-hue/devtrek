# Starts the AI proxy in the background (idempotent).
# Prefers Node when installed, otherwise uses the Dart proxy server.
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$serverDir = Join-Path $root 'server'
$pidFile = Join-Path $serverDir '.proxy.pid'
$logFile = Join-Path $serverDir '.proxy.log'
$errFile = Join-Path $serverDir '.proxy.err.log'

function Test-Proxy {
    # Raw TCP check: unaffected by system proxy settings and IPv4/IPv6
    # localhost differences that can break Invoke-WebRequest here.
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $connect = $client.ConnectAsync('127.0.0.1', 8787)
        if (-not $connect.Wait(1000)) { return $false }
        $stream = $client.GetStream()
        $stream.ReadTimeout = 1500
        $request = "GET /health HTTP/1.1`r`nHost: 127.0.0.1`r`nConnection: close`r`n`r`n"
        $bytes = [Text.Encoding]::ASCII.GetBytes($request)
        $stream.Write($bytes, 0, $bytes.Length)
        $reader = New-Object IO.StreamReader($stream)
        $statusLine = $reader.ReadLine()
        return $statusLine -match ' 200 '
    } catch {
        return $false
    } finally {
        $client.Close()
    }
}

if (Test-Proxy) {
    Write-Host '[dev] AI proxy is already running on http://localhost:8787'
    exit 0
}

$envFile = Join-Path $serverDir '.env'
if (-not (Test-Path $envFile)) {
    Copy-Item (Join-Path $serverDir '.env.example') $envFile
    Write-Warning "Created server\.env from .env.example - put your real ANTHROPIC_API_KEY in it for AI explanations."
}

Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
        $name = $matches[1]
        $value = $matches[2].Trim().Trim('"').Trim("'")
        Set-Item -Path "Env:$name" -Value $value
    }
}

$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) {
    $exe = $node.Source
    $arguments = @('index.js')
    $runtime = 'Node'
} else {
    $dart = Get-Command dart -ErrorAction SilentlyContinue
    if (-not $dart) {
        throw 'Neither Node.js nor Dart was found. Install Node.js or add the Flutter SDK bin folder to PATH.'
    }
    # `dart` on PATH is flutter\bin\dart.bat, whose cmd wrapper exits right
    # after spawning the real VM. Use the SDK executable so the recorded pid is
    # the process that actually listens on the port.
    $dartExe = Join-Path (Split-Path $dart.Source -Parent) 'cache\dart-sdk\bin\dart.exe'
    $exe = if (Test-Path $dartExe) { $dartExe } else { $dart.Source }
    $arguments = @('proxy_dart.dart')
    $runtime = 'Dart'
}

$process = Start-Process -FilePath $exe `
    -ArgumentList $arguments `
    -WorkingDirectory $serverDir `
    -WindowStyle Hidden -PassThru `
    -RedirectStandardOutput $logFile `
    -RedirectStandardError $errFile

Set-Content -Path $pidFile -Value $process.Id -Encoding ascii

for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 500
    if (Test-Proxy) {
        Write-Host "[dev] $runtime AI proxy started (pid $($process.Id)) on http://localhost:8787"
        exit 0
    }
    if ($process.HasExited) { break }
}

if (-not $process.HasExited) { Stop-Process -Id $process.Id -Force }
Remove-Item $pidFile -ErrorAction SilentlyContinue
Write-Error "AI proxy failed to start. Log: $logFile"
if (Test-Path $logFile) { Get-Content $logFile -Tail 20 | Write-Host }
if (Test-Path $errFile) { Get-Content $errFile -Tail 20 | Write-Host }
exit 1

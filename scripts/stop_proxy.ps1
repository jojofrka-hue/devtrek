# Stops only the proxy process started by start_proxy.ps1 (pid file based).
$root = Split-Path -Parent $PSScriptRoot
$serverDir = Join-Path $root 'server'
$pidFile = Join-Path $serverDir '.proxy.pid'

if (-not (Test-Path $pidFile)) {
    Write-Host '[dev] No AI proxy pid file; nothing to stop.'
    exit 0
}

$proxyPid = 0
[int]::TryParse((Get-Content $pidFile -Raw).Trim(), [ref]$proxyPid) | Out-Null
$process = if ($proxyPid -gt 0) { Get-Process -Id $proxyPid -ErrorAction SilentlyContinue } else { $null }

if ($process) {
    Stop-Process -Id $proxyPid -Force
    Write-Host "[dev] AI proxy stopped (pid $proxyPid)."
} else {
    Write-Host '[dev] AI proxy was not running.'
}

Remove-Item $pidFile -ErrorAction SilentlyContinue

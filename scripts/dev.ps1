# Runs the AI proxy and Flutter together; stops the proxy when Flutter exits.
# Usage: powershell -ExecutionPolicy Bypass -File scripts\dev.ps1 [-Device windows] [-Release]
param(
    [string]$Device = 'windows',
    [switch]$Release
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$startScript = Join-Path $PSScriptRoot 'start_proxy.ps1'
$stopScript = Join-Path $PSScriptRoot 'stop_proxy.ps1'

if ($Device -eq 'windows') {
    & (Join-Path $PSScriptRoot 'prepare_windows.ps1')
}

& $startScript
if ($LASTEXITCODE -ne 0) {
    throw 'Could not start the AI proxy; Flutter was not launched.'
}

Push-Location $root
try {
    $flutterArgs = @('run', '-d', $Device)
    if ($Release) { $flutterArgs += '--release' }
    & flutter @flutterArgs
} finally {
    Pop-Location
    & $stopScript
}

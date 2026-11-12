$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$flutter = Get-Command flutter -ErrorAction Stop

Push-Location -LiteralPath $root
try {
    Write-Host "[windows] Preparing project: $root"
    Write-Host '[windows] Cleaning old build files and CMake cache...'
    # Keep .dart_tool: deleting it makes the VS Code analysis server report
    # false "errors exist" right before launch and block F5 with a dialog.
    foreach ($directory in @('build')) {
        $path = Join-Path $root $directory
        if (Test-Path -LiteralPath $path) {
            try {
                Remove-Item -LiteralPath $path -Recurse -Force -ErrorAction Stop
            } catch {
                throw "Cannot remove $path. Close the running app/debug session, then try F5 again. $($_.Exception.Message)"
            }
        }
    }

    Write-Host '[windows] Restoring packages for the current project path...'
    & $flutter.Source pub get
    if ($LASTEXITCODE -ne 0) {
        throw 'flutter pub get failed. Resolve the error above before starting the debugger.'
    }
    Write-Host '[windows] Ready. Flutter will generate CMake files and launch coding_quest.'
} finally {
    Pop-Location
}

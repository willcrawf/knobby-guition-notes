# Compile upstream Knobby firmware with arduino-cli (no upload).
# Expects a local clone of knobby-mtg/knobby-mtg-life-counter (see env.ps1).
# ASCII-only.
param(
  [string]$BuildPath = ""
)

. "$PSScriptRoot\env.ps1"

$root = Assert-KnobbyRoot
Assert-ArduinoCli | Out-Null

$sketch = Get-FirmwareSketch $root
if (-not $BuildPath) {
  $BuildPath = Join-Path $NotesRoot "build\knobby"
}
New-Item -ItemType Directory -Force -Path $BuildPath | Out-Null

Write-Host "KNOBBY_ROOT: $root"
Write-Host "FQBN:        $KnobbyFqbn"
Write-Host "FlashMode:   $($env:KNOBBY_FLASH_MODE)  (override: `$env:KNOBBY_FLASH_MODE = 'qio')"
Write-Host "Sketch:      $sketch"
Write-Host "Build dir:   $BuildPath"
Write-Host ""

Invoke-ArduinoCli compile `
  --fqbn $KnobbyFqbn `
  --build-path $BuildPath `
  $sketch

Write-Host ""
Write-Host "BUILD OK (compile only - no device was flashed)."
Write-Host "Artifacts: $BuildPath"
Write-Host "Upload next: .\scripts\upload-knobby.ps1 -Port COMx"
Write-Host "  (confirm ESP32-S3 first; see .\scripts\list-ports.ps1)"

# Upload a built (or just-compiled) Knobby sketch to a confirmed ESP32-S3 COM port.
# ASCII-only.
param(
  [Parameter(Mandatory = $true)]
  [string]$Port,

  # Default: re-run esptool chip-id and require ESP32-S3 before upload.
  [switch]$SkipChipConfirm,

  # Optional: compile into this build path before upload (same as build-knobby.ps1).
  [switch]$Build,

  [string]$BuildPath = ""
)

. "$PSScriptRoot\env.ps1"

$root = Assert-KnobbyRoot
Assert-ArduinoCli | Out-Null

$sketch = Join-Path $root "knobby"
if (-not $BuildPath) {
  $BuildPath = Join-Path $NotesRoot "build\knobby"
}

# Normalize Port (accept COM3 or com3)
if ($Port -notmatch '^(?i)COM\d+$') {
  throw "Port must look like COM3 (got '$Port'). Do not guess - run scripts\list-ports.ps1 and chip-id first."
}
$Port = $Port.ToUpperInvariant()

Write-Host "KNOBBY_ROOT: $root"
Write-Host "FQBN:        $KnobbyFqbn"
Write-Host "FlashMode:   $($env:KNOBBY_FLASH_MODE)"
Write-Host "Port:        $Port"
Write-Host ""

if (-not $SkipChipConfirm) {
  Confirm-Esp32S3Port -Port $Port
  Write-Host ""
} else {
  Write-Host "WARNING: -SkipChipConfirm set. Ensure $Port is ESP32-S3 (not the secondary ESP32)."
  Write-Host ""
}

if ($Build) {
  New-Item -ItemType Directory -Force -Path $BuildPath | Out-Null
  Write-Host "Compiling before upload..."
  Invoke-ArduinoCli compile `
    --fqbn $KnobbyFqbn `
    --build-path $BuildPath `
    $sketch
  Write-Host ""
}

Write-Host "Uploading to $Port ..."
$uploadArgs = @(
  "upload",
  "--fqbn", $KnobbyFqbn,
  "-p", $Port
)
if (Test-Path $BuildPath) {
  $uploadArgs += @("--input-dir", $BuildPath)
}
$uploadArgs += $sketch

Invoke-ArduinoCli @uploadArgs

Write-Host ""
Write-Host "UPLOAD OK on $Port"
Write-Host "If the unit fails to boot after a successful upload, rebuild with:"
Write-Host "  `$env:KNOBBY_FLASH_MODE = 'qio'"
Write-Host "  .\scripts\build-knobby.ps1"
Write-Host "  .\scripts\upload-knobby.ps1 -Port $Port"
Write-Host "See docs\FLASH_MODE.md"

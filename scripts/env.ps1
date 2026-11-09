# Shared settings for Knobby companion scripts (Windows PowerShell).
# ASCII-only. This notes repo does NOT vendor Knobby source.
$ErrorActionPreference = "Stop"

$NotesRoot = Split-Path -Parent $PSScriptRoot

# Upstream Knobby clone. Override with $env:KNOBBY_ROOT if needed.
# Expected layout: sibling of this notes repo, or any path you set.
#   git clone https://github.com/knobby-mtg/knobby-mtg-life-counter.git
if (-not $env:KNOBBY_ROOT) {
  $candidate = Join-Path (Split-Path -Parent $NotesRoot) "knobby-mtg-life-counter"
  if (Test-Path (Join-Path $candidate "knobby")) {
    $env:KNOBBY_ROOT = $candidate
  }
}

$KnobbyRoot = $env:KNOBBY_ROOT

# ESP32 Arduino core 3.3.x encodes external NOR flash clock inside FlashMode.
# This is flash timing, NOT a GPIO / pin-map setting.
#   qio120 = QIO 120MHz - first try for this GUITION family (manufacturer Arduino Tools)
#   qio    = QIO 80MHz  - upstream Knobby Makefile/CI; use if boot fails after qio120
# Override: $env:KNOBBY_FLASH_MODE = "qio"
# See docs/FLASH_MODE.md.
if (-not $env:KNOBBY_FLASH_MODE) { $env:KNOBBY_FLASH_MODE = "qio120" }

$KnobbyFqbn = "esp32:esp32:esp32s3:FlashSize=16M,PSRAM=opi,USBMode=hwcdc,CDCOnBoot=cdc,FlashMode=$($env:KNOBBY_FLASH_MODE),PartitionScheme=custom"

# arduino-cli on PATH, or override with $env:ARDUINO_CLI (full path to exe).
function Get-ArduinoCliPath {
  if ($env:ARDUINO_CLI -and (Test-Path $env:ARDUINO_CLI)) {
    return $env:ARDUINO_CLI
  }
  $cmd = Get-Command arduino-cli -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  return $null
}

function Assert-ArduinoCli {
  $path = Get-ArduinoCliPath
  if (-not $path) {
    throw "arduino-cli not found. Install it and add to PATH, or set `$env:ARDUINO_CLI to the exe path."
  }
  return $path
}

function Invoke-ArduinoCli {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$CliArgs)
  $cli = Assert-ArduinoCli
  & $cli @CliArgs
  if ($LASTEXITCODE -ne 0) { throw "arduino-cli failed ($LASTEXITCODE): $($CliArgs -join ' ')" }
}

function Assert-KnobbyRoot {
  if (-not $KnobbyRoot) {
    throw @"
Knobby source not found.

Clone upstream next to this notes repo (or set KNOBBY_ROOT):

  cd $(Split-Path -Parent $NotesRoot)
  git clone https://github.com/knobby-mtg/knobby-mtg-life-counter.git

Then re-run, or:

  `$env:KNOBBY_ROOT = 'C:\path\to\knobby-mtg-life-counter'
"@
  }
  $sketch = Join-Path $KnobbyRoot "knobby"
  if (-not (Test-Path $sketch)) {
    throw "Knobby sketch folder missing at $sketch (KNOBBY_ROOT=$KnobbyRoot)."
  }
  return $KnobbyRoot
}

function Get-EspToolCommand {
  # Prefer esptool on PATH; fall back to python -m esptool.
  $cmd = Get-Command esptool -ErrorAction SilentlyContinue
  if ($cmd) { return @{ Exe = $cmd.Source; Prefix = @() } }
  $py = Get-Command python -ErrorAction SilentlyContinue
  if ($py) { return @{ Exe = $py.Source; Prefix = @("-m", "esptool") } }
  $py3 = Get-Command python3 -ErrorAction SilentlyContinue
  if ($py3) { return @{ Exe = $py3.Source; Prefix = @("-m", "esptool") } }
  return $null
}

function Confirm-Esp32S3Port {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Port
  )

  $tool = Get-EspToolCommand
  if (-not $tool) {
    throw "esptool not found (need esptool on PATH or python -m esptool). Cannot confirm chip type."
  }

  Write-Host "Confirming chip on $Port (must be ESP32-S3)..."
  $args = @()
  $args += $tool.Prefix
  $args += @("--port", $Port, "chip-id")

  $output = & $tool.Exe @args 2>&1 | Out-String
  Write-Host $output

  if ($LASTEXITCODE -ne 0) {
    throw "esptool chip-id failed on $Port (exit $LASTEXITCODE). Check cable, power switch ON, and port."
  }

  if ($output -match 'ESP32-S3') {
    Write-Host "Chip confirm OK: ESP32-S3 on $Port"
    return
  }

  if ($output -match 'ESP32') {
    throw @"
Chip on $Port looks like classic ESP32, not ESP32-S3.
Do not flash Knobby here. Flip the USB-C cable 180 degrees, re-run scripts\list-ports.ps1,
and confirm chip-id again. COM numbers are not trustworthy on this dual-MCU knob.
"@
  }

  throw "Could not confirm ESP32-S3 on $Port from chip-id output. Aborting upload."
}

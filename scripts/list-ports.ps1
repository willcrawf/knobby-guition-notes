# List serial ports and hint which may be ESP32-S3 vs the secondary ESP32.
# Docs-first helper for GUITION JC3636K518-style knobs. Confirm with esptool chip-id.

Write-Host "==> arduino-cli board list (if installed)"
if (Get-Command arduino-cli -ErrorAction SilentlyContinue) {
  arduino-cli board list
} else {
  Write-Host "arduino-cli not on PATH - skipping"
}

Write-Host ""
Write-Host "==> Win32 PnP / COM hints"
Get-CimInstance Win32_PnPEntity |
  Where-Object { $_.Name -match 'COM\d+' -or $_.Name -match 'USB Serial|USB JTAG|CH340|CP210|ESP32' } |
  Select-Object Name, DeviceID |
  Format-Table -AutoSize

Write-Host ""
Write-Host "Interpretation (verify on your unit):"
Write-Host "- ESP32-S3 native USB CDC/JTAG (often VID 303A) -> preferred for Knobby"
Write-Host "- USB-SERIAL / CH340 / CP210x                  -> often the secondary ESP32; do NOT flash Knobby there"
Write-Host ""
Write-Host "Confirm before flashing, e.g.:"
Write-Host "  esptool --port COMx chip-id"
Write-Host "If tools report classic ESP32 instead of ESP32-S3, flip USB-C 180 degrees and retry."
Write-Host "Device power switch must be ON."

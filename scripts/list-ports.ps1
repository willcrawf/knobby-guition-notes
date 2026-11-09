# List serial ports and remind: chip-detect ESP32-S3; do not trust COM number.
# Docs-first helper for GUITION JC3636K518-style knobs. Confirm with esptool chip-id.
# ASCII-only.

Write-Host "==> Reminder"
Write-Host "Do NOT trust the COM number. This knob has two USB data paths on one USB-C plug."
Write-Host "Always chip-detect ESP32-S3 before flashing. If you get classic ESP32, flip the cable 180 degrees."
Write-Host "Device power switch must be ON."
Write-Host ""

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
Write-Host "You want ESP32-S3. Classic ESP32 => flip USB-C 180 degrees and retry."
Write-Host "See docs\WINDOWS_USB.md"

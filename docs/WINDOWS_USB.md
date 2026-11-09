# Windows: identify the ESP32-S3 port

This GUITION knob family has **two** USB data paths on one USB-C connector: main **ESP32-S3** (display / Knobby) and a second **ESP32**. Flashing the wrong chip will not install Knobby where you expect — and can overwrite the co-processor if you are not careful.

## Rules of thumb

1. **Do not trust the COM number.** It changes between PCs, hubs, and cable flips.
2. Prefer a port whose PnP name looks like **USB JTAG/serial** (Espressif / VID **303A**).
3. Always confirm with **esptool chip-id** (or equivalent) before upload.
4. If the chip is classic **ESP32**, flip USB-C **180°** and check again.

## Quick checks

### Option A — helper script

From this repo (PowerShell):

```powershell
.\scripts\list-ports.ps1
```

### Option B — inline commands

```powershell
arduino-cli board list

Get-CimInstance Win32_PnPEntity |
  Where-Object { $_.Name -match 'COM\d+|USB Serial|USB JTAG|CH340|CP210|ESP32' } |
  Select-Object Name, DeviceID |
  Format-Table -AutoSize
```

Then, for each candidate COM port:

```powershell
# Replace COMx — requires esptool on PATH (or python -m esptool)
esptool --port COMx chip-id
```

You want a response that clearly identifies **ESP32-S3**. Also useful: `esptool --port COMx flash-id` (expect ~16 MB on this family).

## Interpreting what you see

| What Windows / tools show | Likely meaning | Action |
|---------------------------|----------------|--------|
| USB JTAG/serial, VID 303A, chip-id = ESP32-S3 | Main MCU | Use this for Knobby |
| CH340 / CP210 / generic USB-SERIAL, chip-id = ESP32 | Secondary MCU | Do **not** flash Knobby here |
| chip-id = ESP32 when you expected S3 | Wrong USB-C orientation (common) | Flip cable 180°, re-run chip-id |
| No COM ports | Power off, bad cable, or data-blocked cable | Power switch ON; try another cable/port |

## Before you flash

- Device power switch on the bottom should be **ON**.
- Prefer a direct USB port over a flaky hub when first bringing the board up.
- Keep a full 16 MB S3 backup before the first erase/upload (see README recovery section).

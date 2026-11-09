# Flash mode: `qio` vs `qio120`

## What `FlashMode` changes

On ESP32 Arduino core **3.3.x**, the board option `FlashMode` sets both SPI I/O width and the **external NOR flash clock**:

| FQBN value | Meaning |
|------------|---------|
| `FlashMode=qio` | Quad I/O, **80 MHz** (Arduino-ESP32 default for many `esp32s3` boards; upstream Knobby) |
| `FlashMode=qio120` | Quad I/O, **120 MHz** |

This is **CPU ↔ onboard flash** timing (for example a W25Q128 next to the S3). It is **not**:

- the ST77916 display QSPI bus
- a GPIO / `board_k518` pin assignment
- proof that “pins matched, so 120 MHz is required”

## Evidence (strength matters)

| Source | Setting | How to treat it |
|--------|---------|-----------------|
| Manufacturer Arduino Tools screenshot for the demo | **QIO 120 MHz** | Best *Arduino-build* hint for this family |
| Upstream Knobby `Makefile` / CI | `FlashMode=qio` → **80 MHz** | Known working for Knobby’s shipped builds |
| Manufacturer flash download tool UI for the factory S3 bin | **80 MHz** QIO | About **programming** the stock merged image, not Arduino FQBN proof |
| Pin match to `board_k518` | N/A | Says nothing about flash clock |

## Recommended A/B order

1. Build and flash with **`FlashMode=qio120`** (match manufacturer Arduino screenshot).
2. If the upload reports success but the unit will not boot usefully (boot loop, silent brick, serial garbage, dead UI with no life), rebuild with **`FlashMode=qio`** and flash again.
3. If serial is alive but the panel stays blank, treat that as display/backlight bring-up next — not another flash-clock guess first.

## Example FQBNs

First try (this board family preference):

```text
esp32:esp32:esp32s3:FlashSize=16M,PSRAM=opi,USBMode=hwcdc,CDCOnBoot=cdc,FlashMode=qio120,PartitionScheme=custom
```

Fallback (upstream Knobby):

```text
esp32:esp32:esp32s3:FlashSize=16M,PSRAM=opi,USBMode=hwcdc,CDCOnBoot=cdc,FlashMode=qio,PartitionScheme=custom
```

## Companion scripts

Windows helpers in this repo default to `FlashMode=qio120`:

```powershell
.\scripts\build-knobby.ps1
.\scripts\upload-knobby.ps1 -Port COMx
```

Force the upstream 80 MHz path:

```powershell
$env:KNOBBY_FLASH_MODE = "qio"
.\scripts\build-knobby.ps1
.\scripts\upload-knobby.ps1 -Port COMx
```

Shared FQBN construction lives in [`scripts/env.ps1`](../scripts/env.ps1).

## Note on write-time vs runtime settings

Some Espressif upload paths still print programmer defaults such as `dio` / `80m` in `flash_args` even when the sketch was built with a different `FlashMode`. Use boot behavior and a confirmed S3 port as the real A/B test; do not over-read a single log line in isolation.

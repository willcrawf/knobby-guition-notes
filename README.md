# Knobby on GUITION JC3636K518

Notes for running the open-source [Knobby](https://github.com/knobby-mtg/knobby-mtg-life-counter) Magic: The Gathering life counter on a GUITION complete round knob (JC3636K518 / JC3636K518C-I-YR1 style).

This repo is **documentation only**. It does not ship Knobby source, factory flash dumps, or manufacturer media.

## Compatibility (read this first)

**Expected:** Knobby’s built-in `board_k518` pin profile matches this hardware family.

- **Source-compared:** manufacturer demo pins (`pincfg.h`) line up with Knobby `board_k518` for display, touch, encoder, backlight, battery ADC, and boot button.
- **Device-tested on one unit:** after flashing to the confirmed ESP32-S3 port, serial showed `Probing JC3636K518... found!` plus CST816 / ST77916 init. That is **one tested device**, not universal proof for every listing suffix or PCB revision.

Flash clock (`qio` vs `qio120`) is a separate choice from pins — see [Flash mode](#flash-mode-qio-vs-qio120).

## Table of contents

1. [Hardware family](#hardware-family)
2. [Upstream Knobby](#upstream-knobby)
3. [Windows: pick the correct MCU](#windows-pick-the-correct-mcu)
4. [Flash mode (`qio` vs `qio120`)](#flash-mode-qio-vs-qio120)
5. [Build / upload with arduino-cli](#build--upload-with-arduino-cli)
6. [Knobby UX tip (Players vs Track)](#knobby-ux-tip-players-vs-track)
7. [Recovery (high level)](#recovery-high-level)
8. [More detail](#more-detail)

## Hardware family

Typical GUITION **JC3636K518** / **JC3636K518C-I-YR1**-style complete knob:

| Piece | What to expect |
|-------|----------------|
| Main MCU | ESP32-S3 (often ESP32-S3R8 in docs) |
| Second MCU | Classic ESP32 (audio / USB roles) — leave alone unless you intentionally flash it |
| Flash | 16 MB external NOR |
| PSRAM | 8 MB OPI |
| Display | ST77916, 360×360, QSPI |
| Touch | CST816 / CST816S (I²C) |
| Input | Rotary encoder on the S3 |

Listing names vary (`I_W`, `I-YR1`, “1.85 inch”, occasional wrong 320×320 tables). Prefer manufacturer PDF + demo code (**360×360**) over marketplace tables when they disagree.

Knobby does not need a pin-map fork for K518-class hardware based on the source comparison above.

## Upstream Knobby

- Source / Makefile: [knobby-mtg/knobby-mtg-life-counter](https://github.com/knobby-mtg/knobby-mtg-life-counter)
- Browser installer: [knobby-mtg.github.io/knobby-mtg-life-counter](https://knobby-mtg.github.io/knobby-mtg-life-counter/)

Clone or install from upstream. This notes repo is not a fork.

## Windows: pick the correct MCU

**Do not trust the COM number.** The same cable can expose either MCU depending on USB-C orientation.

1. Plug in with the device power switch **ON**.
2. List ports (`arduino-cli board list`, Device Manager, or [`scripts/list-ports.ps1`](scripts/list-ports.ps1)).
3. Confirm with **esptool `chip-id`** on the candidate COM port.
4. Flash only when the chip is **ESP32-S3**.

Hints:

- ESP32-S3 often appears as **USB JTAG/serial** (Espressif VID **303A**).
- If tools report classic **ESP32** (not S3), flip the USB-C plug **180°** and re-check `chip-id`.
- Do not flash Knobby to a CH340 / CP210 / “USB-SERIAL” port that is really the secondary ESP32.

Full walkthrough: [`docs/WINDOWS_USB.md`](docs/WINDOWS_USB.md).

## Flash mode (`qio` vs `qio120`)

**Pins ≠ flash clock.** Matching `board_k518` does not pick the external NOR clock rate.

On Arduino-ESP32 **3.3.x**, `FlashMode` encodes Quad I/O **and** flash frequency:

| FQBN value | Meaning |
|------------|---------|
| `FlashMode=qio120` | QIO, **120 MHz** |
| `FlashMode=qio` | QIO, **80 MHz** (upstream Knobby Makefile / CI) |

Manufacturer Arduino Tools screenshot for this family highlights **QIO 120 MHz**. Upstream Knobby uses `FlashMode=qio` (80 MHz). Factory download-tool UIs that show **80 MHz QIO** are about programming the stock merged bin — not Arduino FQBN proof.

**Recommendation for this board family:** try **`qio120` first**. If upload succeeds but the unit fails to boot (loop, dead UI, no useful serial), rebuild and flash with **`qio`**.

Details: [`docs/FLASH_MODE.md`](docs/FLASH_MODE.md).

## Build / upload with arduino-cli

Use Knobby’s custom partitions and the same core options as upstream, optionally swapping flash mode:

```text
esp32:esp32:esp32s3:FlashSize=16M,PSRAM=opi,USBMode=hwcdc,CDCOnBoot=cdc,FlashMode=qio120,PartitionScheme=custom
```

Upstream default (80 MHz) is the same string with `FlashMode=qio`.

Example (after cloning Knobby and installing its libraries — see upstream README / CONTRIBUTING):

```powershell
# Identify the S3 port first (see docs/WINDOWS_USB.md)
$port = "COMx"   # replace with the confirmed ESP32-S3 port

$fqbn = "esp32:esp32:esp32s3:FlashSize=16M,PSRAM=opi,USBMode=hwcdc,CDCOnBoot=cdc,FlashMode=qio120,PartitionScheme=custom"

arduino-cli compile --fqbn $fqbn knobby
arduino-cli upload  --fqbn $fqbn -p $port knobby
```

If boot fails after a successful upload, change `FlashMode=qio120` to `FlashMode=qio` and compile/upload again.

## Knobby UX tip (Players vs Track)

Defaults can look like a single-seat life counter when **Players=4** and **Track=1** — only one seat is shown.

For a 4-way Commander view:

1. Set **Track = 4**
2. Set **Life = 40**
3. **Long-press Apply** so the layout sticks

“Players” is how many players exist; “Track” is how many seats the UI shows at once.

## Recovery (high level)

1. **Before first flash**, keep a full **16 MB** backup of the ESP32-S3 flash (`esptool read-flash 0x0 0x1000000 …`). Store it somewhere safe outside this repo.
2. Manufacturer packages for this family typically include **`ESP32_S3_1.85KNOB.bin`** to program at **`0x0`** for S3 restore (Espressif flash download tool, ChipType ESP32-S3).
3. There is a separate factory image for the **secondary ESP32** — only use it if you overwrote that chip on purpose.
4. This notes repo intentionally **does not** include factory bins or full-flash dumps.

## More detail

| Doc | Topic |
|-----|--------|
| [`docs/WINDOWS_USB.md`](docs/WINDOWS_USB.md) | Port identification, VID hints, cable flip |
| [`docs/FLASH_MODE.md`](docs/FLASH_MODE.md) | `qio` vs `qio120`, evidence strength, A/B order |
| [`scripts/list-ports.ps1`](scripts/list-ports.ps1) | Optional Windows helper to list COM / USB hints |

## What this repo is not

- Not a Knobby source fork
- Not App Select / launcher WIP
- Not manufacturer zip contents, TF card media, or `factory-esp32s3-fullflash-*.bin` dumps
- Not a guarantee that every JC3636K518 listing revision behaves identically

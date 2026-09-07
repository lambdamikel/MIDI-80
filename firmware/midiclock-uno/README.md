# MIDI/80 External Clock Box

An Arduino Uno with a MIDI shield that converts incoming **MIDI beat
clock** into the **parallel port step pulses** TRACKER already
understands in external clock mode (`'`), so a DAW, drum machine or
groovebox can drive a TRS-80 running TRACKER.

## Why a separate box

TRACKER cannot recover an incoming MIDI clock itself. Profiling its main
loop in the trs80gp bus trace showed a **~27 ms contiguous work block
per step** during which it never reads the MIDI/80 FIFO. At 120 BPM an
`F8` arrives every 20.8 ms, so at least one clock per step always lands
inside a blind window. The FIFO preserves the *bytes*, but it destroys
their *arrival times* — and clock recovery needs timestamps, not counts.

A dedicated ATmega328 does nothing else, so it timestamps every byte
within microseconds. Measured on the Arduino's own clock: **sd 0.15 ms**
over 48 steps, against TRACKER's own ~4.4 ms clock jitter.

TRACKER sends clock well (see 1.99 / 2.00) precisely because it *knows*
when its own step happened. It receives badly for the same reason
inverted. This box handles the direction TRACKER is bad at.

## Hardware

| | |
| --- | --- |
| Board | Arduino Uno (or any 16 MHz ATmega328 — 31250 baud divides exactly, `UBRR = 31`, zero error) |
| Shield | LinkSprite MIDI Shield, SparkFun MIDI Shield, or any shield using the hardware UART |
| Flash used | 2606 bytes (8%), 203 bytes RAM |

The Uno is **5 V**, so it drives the TRS-80's TTL printer-port input
directly with no level shifting. A 3.3 V board would work
(TTL V<sub>IH</sub> is 2.0 V) but is less comfortable.

## Wiring

Mirrors the TRS-80-to-TRS-80 sync cable described in the main README,
with the Arduino standing in for the primary machine:

| Arduino | | TRS-80 Centronics |
| --- | --- | --- |
| `GND` | → | pin 2 (`GND`) |
| `D8` | →  220–470 Ω  → | pin 21 (`BUSY`) |

The series resistor is cheap insurance against a mis-wire. TRACKER
edge-detects the whole printer status byte:

```
ld a,(hl)        ; whole printer status byte
xor b            ; ANY change = advance one step
jr nz, nextstep
```

so this box only has to **toggle** the line once per step. One edge =
one step; the level itself carries no meaning and never needs resetting.

## Usage

1. On the TRS-80: press `'` to arm external clock, then `P` (pattern) or
   `!` (song). TRACKER freezes, waiting for edges.
2. Start your DAW or drum machine. Its `FA` starts the box toggling and
   TRACKER runs locked to it. `FC` stops it again.

`D13` blinks once per tracker step, so you can confirm the box is
receiving clock before connecting anything to the TRS-80.

### Divisor jumpers

MIDI clock is 24 ppqn and a TRACKER step is a 16th note, so the default
is ÷6. Jumper the pins to `GND`; `INPUT_PULLUP` means **no jumpers
fitted gives the default**.

| D9 | D10 | Divisor | One step = |
| --- | --- | --- | --- |
| open | open | 6 | 16th note *(default)* |
| GND | open | 3 | 32nd note |
| open | GND | 12 | 8th note |
| GND | GND | 24 | quarter note |

## Building and uploading

```sh
arduino-cli compile --fqbn arduino:avr:uno .
arduino-cli upload -p /dev/ttyUSB0 --fqbn arduino:avr:uno .
```

**The shield must be switched OFF (or lifted off) to upload.** MIDI
shields of this family use the hardware UART on `D0`/`D1`, which is
shared with the USB converter, so the bootloader cannot be reached while
MIDI is connected. The symptom is `avrdude: not in sync: resp=0x00`.
Switch back ON afterwards or the sketch receives nothing.

For the same reason there is **no USB serial debugging** available in
normal use: `Serial.print()` would corrupt the MIDI line, since TX goes
to the MIDI OUT jack. Debug via the LED.

## Verification

Tested on real hardware by feeding synthetic MIDI over USB with the
shield's switch off (which connects `D0`/`D1` to the USB converter
instead of the MIDI jacks), using a `-DTEST_ECHO` build that reports
every step back to the host for machine counting:

| Check | Result |
| --- | --- |
| Divider: 144 clocks → 24 steps | PASS |
| `FA` / `FC` transport markers | PASS |
| Clocks while stopped → nothing | PASS |
| Note + `FE` active sensing while stopped → nothing | PASS |
| Notes / `FE` **interleaved** with clock | PASS |
| MMC Stop halts stepping | PASS |
| MMC Play re-arms | PASS |
| 48 steps: mean 124.99 ms, **sd 0.15 ms** | expected 125.00 ms at 120 BPM |

The timing figure is an *upper bound* — it includes host scheduling and
USB buffering jitter that do not exist on a real MIDI cable.

That test run caught a real bug: `F0` and `F7` are not buffered, so a
minimal MMC message leaves **four** payload bytes, not five, and the
original `sysexLen >= 5` guard meant MMC was never recognised at all.
Watching the activity LED would have shown "it blinks, it stops" and
looked perfectly correct.

`TEST_ECHO` is compiled out of the production build, which is byte for
byte identical before and after it was added (2606 bytes), and was
confirmed silent on TX.

## Known limitation

The parallel protocol is **edge-only and carries no transport**, so this
box cannot *start* a stopped TRACKER — you must press `P` yourself
first. Fixing that needs a second signal line on the TRS-80 side
(`BUSY` is taken; `PAPER EMPTY`, `SELECT` and `FAULT` are candidates)
plus masking TRACKER's `xor` to a single bit, since today *any* status
bit changing would false-trigger a step.

## Parser notes

System Real Time bytes (≥ `0xF8`) are handled **before anything else**
and never touch parser state, because the MIDI spec explicitly permits
them inside another message — including inside SysEx. `0xFE` active
sensing, which some gear sends continuously, is ignored. Channel data,
running status and unknown SysEx are all discarded.

---

*(C) 2026 LambdaMikel + Claude — GPL 3*

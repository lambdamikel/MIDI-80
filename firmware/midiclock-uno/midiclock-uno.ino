/*
 * MIDI/80 External Clock Box  -  Arduino Uno + LinkSprite MIDI Shield
 * ------------------------------------------------------------------
 *
 * Turns incoming MIDI beat clock into the parallel-port step pulses that
 * TRACKER already understands in external clock mode ('), so a DAW or a
 * drum machine can drive a TRS-80 running TRACKER.
 *
 * Why a separate box at all:
 *
 *   TRACKER cannot recover an incoming MIDI clock itself. Profiling its
 *   main loop showed a ~27 ms contiguous work block per step during
 *   which it never reads the MIDI/80 FIFO. At 120 BPM an F8 arrives
 *   every 20.8 ms, so at least one clock per step always lands inside a
 *   blind window: the FIFO preserves the bytes but destroys their
 *   arrival times, and clock recovery needs timestamps. A dedicated
 *   ATmega328 does nothing else, so it timestamps every byte within a
 *   few microseconds - three to four orders of magnitude better.
 *
 * How TRACKER receives it (see the MIDI/80 README, external clock):
 *
 *   listenextclock:  ld a,(hl)   ; whole printer status byte
 *                    xor b       ; ANY change = advance one step
 *                    jr nz, nextstep
 *
 *   It edge-detects, so this box only has to TOGGLE the line once per
 *   tracker step. One edge = one step; the level itself means nothing.
 *
 * Wiring, mirroring the TRS-80 to TRS-80 sync cable:
 *
 *   Arduino GND         -> TRS-80 Centronics GND   (pin 2)
 *   Arduino PIN_CLOCK   -> TRS-80 Centronics BUSY  (pin 21)
 *
 *   A 220-470 ohm resistor in series with the clock line is cheap
 *   insurance against a mis-wire. The Uno is 5 V, so it drives the
 *   TRS-80's TTL input directly with no level shifting.
 *
 * Usage:
 *
 *   1. On the TRS-80, press ' to arm external clock, then P (or !).
 *      TRACKER freezes, waiting for edges.
 *   2. Start your DAW / drum machine. Its FA starts this box toggling
 *      and TRACKER runs locked to it. FC stops it again.
 *
 *   NOTE: the parallel protocol is edge-only and carries no transport,
 *   so this box cannot START a stopped TRACKER - you must press P
 *   first. Adding that would need a second signal line on the TRS-80
 *   side plus masking its xor to a single bit.
 *
 * NOTE ON DEBUGGING: the MIDI shield uses the hardware UART (D0/D1), so
 * Serial.print() would corrupt the MIDI line and there is no USB serial
 * console available while the shield is fitted. Debug via the LED.
 * Most such shields also have a PROG/RUN switch that must be in PROG to
 * upload a sketch, because D0/D1 are shared with the USB converter.
 *
 * (C) 2026 LambdaMikel + Claude   -   GPL 3
 */

/* ---- pin assignment ------------------------------------------------
 * VERIFY these against your shield's silkscreen. D0/D1 are the MIDI
 * UART. Many MIDI shields also claim D2-D4 (buttons) and D6/D7 (LEDs),
 * so the pins below were chosen to stay clear of those.
 */
const uint8_t PIN_CLOCK    = 8;   // -> TRS-80 BUSY, one toggle per step
const uint8_t PIN_LED      = 13;  // on-board LED, one blink per step
const uint8_t PIN_DIV_A    = 9;   // divisor jumpers to GND, or leave open
const uint8_t PIN_DIV_B    = 10;

/* ---- MIDI System Real Time ---------------------------------------- */
const uint8_t MIDI_CLOCK    = 0xF8;
const uint8_t MIDI_START    = 0xFA;
const uint8_t MIDI_CONTINUE = 0xFB;
const uint8_t MIDI_STOP     = 0xFC;

const uint8_t MIDI_SYSEX_START = 0xF0;
const uint8_t MIDI_SYSEX_END   = 0xF7;

/* MMC:  F0 7F <device> 06 <command> F7 */
const uint8_t MMC_STOP = 0x01;
const uint8_t MMC_PLAY = 0x02;
const uint8_t MMC_DEFERRED_PLAY = 0x03;
const uint8_t MMC_PAUSE = 0x09;

/* ---- test instrumentation ------------------------------------------
 * Compiled out entirely unless built with -DTEST_ECHO. In normal use the
 * UART's TX line goes to the MIDI OUT jack, so nothing may ever be
 * written to it. With the shield's switch OFF, however, TX reaches the
 * USB converter instead, which lets a host verify the divider and
 * measure this box's own timing without anyone watching an LED.
 */
#ifdef TEST_ECHO
  #define TESTLOG(x)  Serial.println(x)
#else
  #define TESTLOG(x)
#endif

/* ---- state --------------------------------------------------------- */
uint8_t  clockDivisor = 6;      // MIDI is 24 ppqn; a TRACKER step is a
                                // 16th note, so 24/4 = 6 clocks per step
uint8_t  clockCount   = 0;
bool     running      = false;
bool     clockLevel   = false;

/* Some masters free-run: they stream F8 from an internal clock and never
 * send FA/FB/FC at all. A Korg microKORG on INT clock does exactly this -
 * measured here as 55 F8 per second (~138 BPM) with zero transport bytes
 * in 45 seconds. Waiting for a Start would ignore a perfectly good clock.
 *
 * So: if the master has NEVER sent a transport message, treat a steady
 * run of clocks as "running". Once any transport byte has been seen we
 * obey transport strictly for the rest of the session, which keeps
 * proper start/stop behaviour with sequencers that do send it. */
const uint8_t FREERUN_CLOCKS = 24;   /* one quarter note before assuming */

bool     seenTransport = false;
uint8_t  freeRunCount  = 0;

bool     inSysex      = false;
uint8_t  sysexBuf[8];
uint8_t  sysexLen     = 0;

unsigned long ledOffAt = 0;     // non-blocking LED pulse

/* --------------------------------------------------------------------
 * Read the divisor jumpers. Both open (the default, no jumpers fitted)
 * gives /6, i.e. one TRACKER step per 16th note.
 */
uint8_t readDivisor()
{
  bool a = (digitalRead(PIN_DIV_A) == LOW);   // INPUT_PULLUP: LOW = fitted
  bool b = (digitalRead(PIN_DIV_B) == LOW);

  if (!a && !b) return 6;    // 16th notes  (default)
  if ( a && !b) return 3;    // 32nd notes
  if (!a &&  b) return 12;   // 8th notes
  return 24;                 // quarter notes
}

/* --------------------------------------------------------------------
 * One tracker step: flip the line. TRACKER advances on the edge, so the
 * level carries no meaning and never needs resetting.
 */
inline void emitStep()
{
  clockLevel = !clockLevel;
  digitalWrite(PIN_CLOCK, clockLevel ? HIGH : LOW);

  digitalWrite(PIN_LED, HIGH);
  ledOffAt = millis() + 8;

  TESTLOG(micros());   /* step timestamp, for host side verification */
}

/* --------------------------------------------------------------------
 * A completed SysEx message. We only care about MMC transport, which
 * lets an MMC-only master (one sending no beat clock) at least stop us.
 */
void handleSysex()
{
  /* F0 and F7 are not stored, so a minimal MMC message
   *     F0 7F <device> 06 <command> F7
   * leaves exactly four bytes in the buffer: 7F, device, 06, command. */
  if (sysexLen >= 4 &&
      sysexBuf[0] == 0x7F &&        /* universal real time */
      sysexBuf[2] == 0x06)          /* MMC command         */
  {
    switch (sysexBuf[3]) {
      case MMC_STOP:
        running       = false;
        seenTransport = true;
        freeRunCount  = 0;
        break;
      case MMC_PLAY:
      case MMC_DEFERRED_PLAY:
        /* MMC carries no timing, so we cannot generate steps from it.
         * Arm ourselves; actual stepping still needs F8 to arrive. */
        running = true;
        clockCount = 0;
        break;
      case MMC_PAUSE:
        running       = false;
        seenTransport = true;
        freeRunCount  = 0;
        break;
      default:
        break;
    }
  }
}

/* --------------------------------------------------------------------
 * Byte dispatch.
 *
 * System Real Time bytes (>= 0xF8) are single bytes that the MIDI spec
 * explicitly permits INSIDE another message - including inside SysEx -
 * so they are handled first and never disturb the parser state.
 */
void handleByte(uint8_t b)
{
  if (b >= 0xF8) {
    switch (b) {

      case MIDI_CLOCK:
        if (!running && !seenTransport) {
          if (++freeRunCount >= FREERUN_CLOCKS) {
            running       = true;      /* free-running master detected */
            freeRunCount  = 0;
            clockCount    = 0;
            TESTLOG("F");
          }
        }
        if (running) {
          /* Toggle on counts 0, div, 2*div ... so that the first step
           * after FA lands on the downbeat rather than a division later. */
          if (clockCount == 0) emitStep();
          if (++clockCount >= clockDivisor) clockCount = 0;
        }
        break;

      case MIDI_START:
        running       = true;
        clockCount    = 0;       /* next F8 is the downbeat */
        seenTransport = true;
        TESTLOG("S");
        break;

      case MIDI_CONTINUE:
        running       = true;    /* resume, keep the phase */
        seenTransport = true;
        TESTLOG("C");
        break;

      case MIDI_STOP:
        running       = false;
        seenTransport = true;
        freeRunCount  = 0;
        TESTLOG("X");
        break;

      default:
        /* 0xFE active sensing, 0xFF reset: ignore. Active sensing in
         * particular arrives constantly from some gear. */
        break;
    }
    return;
  }

  if (b == MIDI_SYSEX_START) {
    inSysex  = true;
    sysexLen = 0;
  } else if (b == MIDI_SYSEX_END) {
    if (inSysex) handleSysex();
    inSysex = false;
  } else if (inSysex) {
    if (sysexLen < sizeof(sysexBuf)) sysexBuf[sysexLen++] = b;
  }
  /* everything else - notes, controllers, running status - is ignored */
}

void setup()
{
  pinMode(PIN_CLOCK, OUTPUT);
  digitalWrite(PIN_CLOCK, LOW);
  pinMode(PIN_LED, OUTPUT);
  digitalWrite(PIN_LED, LOW);

  pinMode(PIN_DIV_A, INPUT_PULLUP);
  pinMode(PIN_DIV_B, INPUT_PULLUP);
  clockDivisor = readDivisor();

  /* 31250 baud divides exactly at 16 MHz (UBRR = 31, zero error) */
  Serial.begin(31250);

  /* three quick blinks: alive, and the divisor was latched */
  for (uint8_t i = 0; i < 3; i++) {
    digitalWrite(PIN_LED, HIGH); delay(60);
    digitalWrite(PIN_LED, LOW);  delay(60);
  }

  TESTLOG("B");
}

void loop()
{
  /* Drain everything available before doing anything else. A byte takes
   * 320 us at 31250 baud and this loop runs in a microsecond or two, so
   * the queue is normally empty and each byte is acted on within a few
   * microseconds of arriving. */
  while (Serial.available() > 0) {
    handleByte((uint8_t) Serial.read());
  }

  if (ledOffAt && (long)(millis() - ledOffAt) >= 0) {
    digitalWrite(PIN_LED, LOW);
    ledOffAt = 0;
  }
}

"""Build a TRACKER song file (the LDOS "DUMP" image) and a matching .MID.

The tracker saves its whole data segment verbatim, so a song file is just a
byte image of everything from `datastart` to `dataend` in tracker7.asm.
Offsets below were taken from the assembler symbol table; see LAYOUT.

Cells hold a character, which is what you see on the grid:
  note      chr(midi_note + DISPMIDINOTEOFFSET)   ($61, so note 0 -> 'a')
  rest      the ruler character for that step, from `data` in the source
Anything <= 'a' counts as a rest, which is why note 0 is unusable.

Steps are 16th notes; 4 steps to a quarter, 16 to a bar. A page holds up to
8 bars = 128 steps, split into tracks1 (steps 0-63) and tracks2 (64-127),
6 tracks of 64 bytes each.
"""

import struct

# ---- layout of the saved image -------------------------------------------
TOTAL         = 22645          # datalength
PAGELEN       = 798
NPAGES        = 26             # patterns A..Z
NTRACKS       = 6
NSTEPS        = 128            # 8 bars * 16

OFF_STARTMARK = 0              # 'START-OF-FILE-MARKER'
OFF_STATUSBUF = 20             # 2*64, transient - redrawn after load
OFF_INSTR     = 148            # GM program per track (global, not per page)
OFF_LASTCUR   = 154
OFF_LASTCURPOS= 155            # word
OFF_CURY      = 160
OFF_SONGDATA  = 1012           # 64 pattern letters, '.' = stop, '*' = loop
OFF_SONGCUR   = 1076
OFF_SONGPOS   = 1077
OFF_CURPAT    = 1078
OFF_TOPAT     = 1079
OFF_NEXTPAT   = 1080
OFF_PAGE      = 1081           # the working page (a copy of pages[curpat])
OFF_PAGES     = 1879           # 26 * PAGELEN
OFF_ENDMARK   = 22627          # 'END-OF-FILE-MARKER'

# ---- offsets inside one page ---------------------------------------------
P_DELAYC, P_TEMPO, P_NUMBARS, P_NUMTICKS, P_GRIDRES, P_QUANTPAT = range(6)
P_DRUMNOS, P_CHANNELS, P_VELOCITY, P_GATES = 6, 12, 18, 24
P_TRACKS1, P_TRACKS2 = 30, 414

NOTEOFF  = 0x61                # DISPMIDINOTEOFFSET
RULER    = "!...-...+...-..."  # `data`: one bar of grid, repeated

# The loader reads 88 records of 256 bytes and stops, so the tail of the
# image never comes back. Patterns past this point would load corrupt.
LOAD_LIMIT   = 88 * 256
SAFE_PATTERNS = (LOAD_LIMIT - OFF_PAGES) // PAGELEN     # = 25, i.e. A..Y

# ---- measured tempo calibration -----------------------------------------
# TRACKER derives its BPM readout from  step = (3346 + tempo*112) * 16  T,
# but that model is only right at the fast end. Measured in trs80gp on a
# Model III by tracing the port 8 writes of a reference voice at tempo
# 40/80/120/160/200, the real step period is linear in tempo to within
# 0.08%, with a noticeably shallower slope:
#
#   tempo    model T    actual T   ratio    BPM shown / actual
#      40     125216      124724   0.996      242.9 / 243.8
#      80     196896      186690   0.948      154.5 / 162.9
#     120     268576      248444   0.925      113.2 / 122.4
#     160     340256      310236   0.912       89.4 /  98.0
#     200     411936      372528   0.904       73.8 /  81.6
#
# So the readout is honest around tempo 40 and reads up to ~10% slow at
# tempo 200; the machine always plays at or faster than it claims. These
# constants let a song be written for the tempo it will really play at.
# Emulator measured, not yet checked against real hardware.
CAL_A, CAL_B = 62778.0, 1547.9

def step_tstates(tempo):
    return CAL_A + CAL_B * tempo

def tempo_for(bpm, model=3):
    """Tempo byte whose ACTUAL playback lands nearest `bpm`."""
    clk = 2027520 if model == 3 else 1774080
    want = 60.0 / (bpm * 4) * clk
    return max(1, min(255, int(round((want - CAL_A) / CAL_B))))


_NAMES = {'c':0,'d':2,'e':4,'f':5,'g':7,'a':9,'b':11}

def n(name):
    """'c4' -> 60, 'f#3' -> 54, 'eb5' -> 75. Also passes ints through."""
    if isinstance(name, int):
        return name
    s = name.strip().lower()
    v = _NAMES[s[0]]; i = 1
    while i < len(s) and s[i] in '#b':
        v += 1 if s[i] == '#' else -1
        i += 1
    return v + (int(s[i:]) + 1) * 12


class Pattern:
    """One tracker page: 6 tracks x up to 128 steps."""

    def __init__(self, tempo=100, numbars=8, gridres=4,
                 channels=(0, 1, 2, 3, 4, 9),
                 velocity=(127,) * 6, gates=(8,) * 6,
                 drumnos=(36, 38, 40, 51, 44, 46), quantpat=0b11111100):
        self.tempo, self.numbars, self.gridres = tempo, numbars, gridres
        self.channels, self.velocity, self.gates = list(channels), list(velocity), list(gates)
        self.drumnos, self.quantpat = list(drumnos), quantpat
        self.nsteps = numbars * 16
        self.cells = [[None] * NSTEPS for _ in range(NTRACKS)]

    def put(self, track, step, note):
        """Place one note. Track and step are 0-based."""
        if not 0 <= step < self.nsteps:
            raise ValueError("step %d outside pattern (%d steps)" % (step, self.nsteps))
        note = n(note)
        if not 1 <= note <= 158:
            raise ValueError("note %d out of encodable range 1..158" % note)
        self.cells[track][step] = note
        return self

    def line(self, track, start, stride, notes):
        """Place `notes` from `start`, every `stride` steps. None/'-' skips."""
        for i, note in enumerate(notes):
            if note is not None and note != '-':
                self.put(track, start + i * stride, note)
        return self

    def hits(self, track, note, steps):
        """Place the same note on every step in `steps` (for drums)."""
        for s in steps:
            self.put(track, s, note)
        return self

    def repeat(self, track, span, times):
        """Copy steps [0,span) forward `times`-1 more times."""
        for r in range(1, times):
            for s in range(span):
                v = self.cells[track][s]
                if v is not None and s + r * span < self.nsteps:
                    self.cells[track][s + r * span] = v
        return self

    def bpm(self, model=3):
        """What TRACKER's own BPM readout will show for this tempo byte."""
        k = 1900800 if model == 3 else 1663200
        return k / (3346 + self.tempo * 112)

    def real_bpm(self, model=3):
        """What the machine actually plays, from CAL_A/CAL_B (see above)."""
        clk = 2027520 if model == 3 else 1774080
        return 60.0 / (step_tstates(self.tempo) / clk * 4)

    def encode(self):
        """-> 798 bytes."""
        p = bytearray(PAGELEN)
        p[P_TEMPO]    = self.tempo
        p[P_NUMBARS]  = self.numbars
        p[P_NUMTICKS] = (self.numbars * 16) & 0xFF
        p[P_GRIDRES]  = self.gridres
        p[P_QUANTPAT] = self.quantpat
        for i in range(NTRACKS):
            p[P_DRUMNOS + i]  = self.drumnos[i]
            p[P_CHANNELS + i] = self.channels[i]
            p[P_VELOCITY + i] = self.velocity[i]
            p[P_GATES + i]    = self.gates[i]
        for t in range(NTRACKS):
            for s in range(NSTEPS):
                v = self.cells[t][s]
                c = (v + NOTEOFF) if v is not None else ord(RULER[s % 16])
                base = P_TRACKS1 if s < 64 else P_TRACKS2
                p[base + t * 64 + (s % 64)] = c
        return bytes(p)


class Song:
    def __init__(self, arrangement, patterns, instruments=(1, 2, 3, 4, 5, 1),
                 title=""):
        self.arrangement = arrangement      # e.g. "AABB*" - '*' loops, '.' stops
        self.patterns = patterns            # {'A': Pattern, ...}
        self.instruments = list(instruments)
        self.title = title
        for L in arrangement:
            if L in '.*':
                continue
            if L not in patterns:
                raise ValueError("arrangement references pattern %r which is not defined" % L)
            if ord(L) - 65 >= SAFE_PATTERNS:
                raise ValueError("pattern %s falls past the loader's %d byte read" % (L, LOAD_LIMIT))

    def check(self):
        """Warn about notes whose gate runs off the end of the pattern.

        The tracker wraps a note-off around to the top of the pattern rather
        than letting it ring, so such a note is cut at the start of the next
        pattern instead of sustaining. Keeping gates inside the pattern makes
        the .MID and the TRS-80 agree.
        """
        warn = []
        for L, pat in sorted(self.patterns.items()):
            for t in range(NTRACKS):
                g = pat.gates[t]
                for s in range(pat.nsteps):
                    if pat.cells[t][s] is not None and s + g > pat.nsteps:
                        warn.append("pattern %s track %d step %d: gate %d wraps"
                                    % (L, t + 1, s, g))
        return warn

    def build_dump(self):
        """-> the 22645 byte song file."""
        d = bytearray(TOTAL)
        d[OFF_STARTMARK:OFF_STARTMARK + 20] = b'START-OF-FILE-MARKER'
        d[OFF_ENDMARK:OFF_ENDMARK + 18]     = b'END-OF-FILE-MARKER'
        for i in range(OFF_STATUSBUF, OFF_STATUSBUF + 128):
            d[i] = 0x20
        for i in range(NTRACKS):
            d[OFF_INSTR + i] = self.instruments[i]

        d[OFF_LASTCUR] = ord('.')
        struct.pack_into('<H', d, OFF_LASTCURPOS, 0x3C00 + 3 * 64)
        d[OFF_CURY] = 3

        song = self.arrangement.ljust(64, '.')[:64]
        d[OFF_SONGDATA:OFF_SONGDATA + 64] = song.encode('latin-1')

        first = next(c for c in self.arrangement if c not in '.*')
        d[OFF_CURPAT] = ord(first)
        d[OFF_TOPAT]  = ord(first)

        # empty pages still need a valid grid, or the display shows garbage
        blank = Pattern().encode()
        for i in range(NPAGES):
            d[OFF_PAGES + i * PAGELEN: OFF_PAGES + (i + 1) * PAGELEN] = blank
        for L, pat in self.patterns.items():
            i = ord(L) - 65
            d[OFF_PAGES + i * PAGELEN: OFF_PAGES + (i + 1) * PAGELEN] = pat.encode()

        # The working page must match pages[curpat]: starting playback calls
        # putpat first, which would otherwise overwrite that pattern with it.
        i = ord(first) - 65
        d[OFF_PAGE:OFF_PAGE + PAGELEN] = d[OFF_PAGES + i * PAGELEN: OFF_PAGES + (i + 1) * PAGELEN]
        assert len(d) == TOTAL
        return bytes(d)

    # ---- MIDI export -----------------------------------------------------
    def write_mid(self, path, model=3, ppq=96, loops=1):
        """Write the arrangement as a type 1 MIDI file.

        Uses the tracker's own tempo formula so the file plays at the speed
        the TRS-80 would produce, including its slight machine dependence.
        """
        step_ticks = ppq // 4          # a step is a 16th
        order = [c for c in self.arrangement if c not in '.*']
        if '*' in self.arrangement:
            order = order * loops

        # tempo track
        tempo_ev = []
        t = 0
        last_bpm = None
        for L in order:
            pat = self.patterns[L]
            b = pat.real_bpm(model)
            if b != last_bpm:
                tempo_ev.append((t, b))
                last_bpm = b
            t += pat.nsteps * step_ticks
        tmeta = bytearray()
        prev = 0
        for tick, bpm in tempo_ev:
            tmeta += _vlq(tick - prev)
            us = int(round(60_000_000 / bpm))
            tmeta += b'\xFF\x51\x03' + us.to_bytes(3, 'big')
            prev = tick
        if self.title:
            tmeta = _vlq(0) + b'\xFF\x03' + bytes([len(self.title)]) + \
                    self.title.encode('latin-1') + tmeta
        tmeta += _vlq(0) + b'\xFF\x2F\x00'
        tracks = [bytes(tmeta)]

        for tr in range(NTRACKS):
            ev = []      # (tick, order, status, d1, d2)
            base = 0
            ch_used = None
            for L in order:
                pat = self.patterns[L]
                ch = pat.channels[tr]
                if ch != ch_used:
                    ev.append((base, 0, 0xC0 | ch, self.instruments[tr], None))
                    ch_used = ch
                vel, g = pat.velocity[tr], pat.gates[tr]
                for s in range(pat.nsteps):
                    v = pat.cells[tr][s]
                    if v is None:
                        continue
                    on = base + s * step_ticks
                    off = base + min(s + g, pat.nsteps) * step_ticks
                    ev.append((on, 1, 0x90 | ch, v, vel))
                    ev.append((off, -1, 0x80 | ch, v, 0))
                base += pat.nsteps * step_ticks
            ev.sort(key=lambda e: (e[0], e[1]))
            buf = bytearray()
            prev = 0
            for tick, _, st, d1, d2 in ev:
                buf += _vlq(tick - prev)
                buf += bytes([st, d1]) if d2 is None else bytes([st, d1, d2])
                prev = tick
            buf += _vlq(0) + b'\xFF\x2F\x00'
            tracks.append(bytes(buf))

        with open(path, 'wb') as f:
            f.write(b'MThd' + (6).to_bytes(4, 'big') +
                    (1).to_bytes(2, 'big') + len(tracks).to_bytes(2, 'big') +
                    ppq.to_bytes(2, 'big'))
            for tk in tracks:
                f.write(b'MTrk' + len(tk).to_bytes(4, 'big') + tk)


def _vlq(v):
    if v < 0:
        raise ValueError("negative delta %d - events out of order" % v)
    out = bytearray([v & 0x7F])
    v >>= 7
    while v:
        out.insert(0, 0x80 | (v & 0x7F))
        v >>= 7
    return bytes(out)

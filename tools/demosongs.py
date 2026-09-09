"""Three demo songs for the MIDI/80 TRACKER.

Each builds a "DUMP" file (what TRACKER's L key loads) plus a matching .MID
rendered with the tracker's own tempo formula, so the two should agree.

Tempo bytes come from mksong.tempo_for(), which uses the MEASURED step
period. TRACKER's BPM readout now uses the same relation, so what a song
displays and what it plays finally agree.
Gates use only the values the UI can produce: 1, 2, 4, 8, 16.

  usage: python3 demosongs.py <output-dir>
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mksong import Pattern, Song, n, tempo_for


# =========================================================================
# 1. BOOGIE - a 12 bar blues in C. Pattern A is the first 8 bars, B the
#    last 4, so A+B is one full chorus.
# =========================================================================
def boogie():
    T = tempo_for(140)
    # boogie bass figure: root, 3rd, 5th, 6th, b7, 6th, 5th, 3rd in eighths
    FIG = {'C': ['c2','e2','g2','a2','a#2','a2','g2','e2'],
           'F': ['f2','a2','c3','d3','d#3','d3','c3','a2'],
           'G': ['g2','b2','d3','e3','f3','e3','d3','b2']}
    # comping: 3rd and b7 of each seventh chord, hit on beats 2 and 4
    STAB = {'C': ('e4','a#4'), 'F': ('a4','d#5'), 'G': ('b4','f5')}

    def build(chords, numbars, lead=None):
        p = Pattern(tempo=T, numbars=numbars, gridres=4,
                    channels=(0, 1, 2, 3, 9, 9),
                    velocity=(112, 88, 88, 104, 127, 78),
                    gates=(2, 4, 4, 2, 1, 1))
        for bar, ch in enumerate(chords):
            b = bar * 16
            p.line(0, b, 2, FIG[ch])                      # bass, eighths
            lo, hi = STAB[ch]
            for s in (4, 12):                             # comp on 2 and 4
                p.put(1, b + s, lo)
                p.put(2, b + s, hi)
            p.hits(4, 36, [b + 0, b + 8])                 # kick on 1 and 3
            p.hits(4, 38, [b + 4, b + 12])                # snare on 2 and 4
            p.hits(5, 42, [b + s for s in range(0, 16, 2)])   # closed hat, eighths
        if lead:
            for step, note in lead:
                p.put(3, step, note)
        return p

    # a C blues-scale riff, answered an octave of attitude higher
    riff_a = [(32,'c4'),(34,'d#4'),(36,'f4'),(38,'f#4'),(40,'g4'),(44,'a#4'),(46,'g4'),
              (48,'f4'),(52,'d#4'),(56,'c4'),(60,'a#3')]
    riff_b = [(96,'g4'),(98,'a#4'),(100,'c5'),(104,'a#4'),(106,'g4'),(108,'f4'),
              (112,'d#4'),(116,'f4'),(120,'c4')]
    A = build(['C','C','C','C','F','F','C','C'], 8, riff_a + riff_b)
    # turnaround: G F C C
    riff_t = [(0,'d5'),(2,'c5'),(4,'a#4'),(8,'g4'),(16,'a4'),(18,'g4'),(20,'f4'),
              (24,'d#4'),(32,'c4'),(36,'d#4'),(40,'f4'),(44,'f#4'),(48,'g4'),(56,'c4')]
    B = build(['G','F','C','C'], 4, riff_t)
    # intro chorus with no lead, then three choruses with it
    A0 = build(['C','C','C','C','F','F','C','C'], 8)
    B0 = build(['G','F','C','C'], 4)
    return Song("CDABABAB.", {'A': A, 'B': B, 'C': A0, 'D': B0},
                instruments=(33, 16, 16, 30, 0, 0), title="MIDI-80 Boogie")


# =========================================================================
# 2. SEQUENCE - a Berlin school 16th note sequencer piece in A minor.
#    This is the one that shows off 2.00's timing: every step is a 16th.
# =========================================================================
def sequence():
    T = tempo_for(120)
    ARP = {'Am': ['a3','c4','e4','a4','c5','a4','e4','c4'],
           'F':  ['f3','a3','c4','f4','a4','f4','c4','a3'],
           'C':  ['c3','e3','g3','c4','e4','c4','g3','e3'],
           'G':  ['g3','b3','d4','g4','b4','g4','d4','b3']}
    ROOT = {'Am': 'a1', 'F': 'f1', 'C': 'c2', 'G': 'g1'}
    PAD  = {'Am': 'a4', 'F': 'a4', 'C': 'g4', 'G': 'b4'}
    CHORDS = ['Am','Am','F','F','C','C','G','G']

    def build(seq2=False, drums=False, pad=False, lead=None, half=False):
        p = Pattern(tempo=T, numbars=8, gridres=4,
                    channels=(0, 1, 2, 3, 4, 9),
                    velocity=(104, 84, 118, 70, 100, 120),
                    gates=(1, 1, 2, 16, 4, 1))
        for bar, ch in enumerate(CHORDS):
            b = bar * 16
            p.line(0, b, 1, ARP[ch])                  # 16ths, first half
            p.line(0, b + 8, 1, ARP[ch])              # ... and repeat
            if seq2:                                  # 16-over-3 polyrhythm
                notes = ARP[ch]
                for i, s in enumerate(range(0, 16, 3)):
                    p.put(1, b + s, n(notes[i % len(notes)]) + 12)
            p.hits(2, n(ROOT[ch]), [b + 0, b + 6, b + 8, b + 14])   # bass pulse
            if pad:
                p.put(3, b, PAD[ch])
            if drums:
                step = 8 if half else 4
                p.hits(5, 36, [b + s for s in range(0, 16, step)])  # kick
                p.hits(5, 42, [b + s for s in range(2, 16, 4)])     # offbeat hat
                if not half:
                    p.hits(5, 38, [b + 4, b + 12])                  # snare
        if lead:
            for step, note in lead:
                p.put(4, step, note)
        return p

    melody = [(0,'a4'),(8,'c5'),(16,'e5'),(28,'d5'),(32,'c5'),(40,'a4'),
              (48,'f4'),(56,'a4'),(64,'g4'),(72,'e4'),(80,'c5'),(88,'b4'),
              (96,'d5'),(104,'b4'),(112,'g4'),(120,'a4')]
    A = build()                                   # sequence alone
    B = build(drums=True, half=True)              # half time drums come in
    C = build(seq2=True, drums=True, pad=True)    # full
    D = build(seq2=True, drums=True, pad=True, lead=melody)
    E = build(seq2=True, half=True, pad=True)     # breakdown
    return Song("ABCDECD*", {'A': A, 'B': B, 'C': C, 'D': D, 'E': E},
                instruments=(81, 80, 38, 89, 82, 0), title="MIDI-80 Sequence")


# =========================================================================
# 3. DRUMS - all six tracks on channel 10, i.e. the original six voice
#    drum machine. Four bar patterns chained into an arrangement.
# =========================================================================
def drums():
    T = tempo_for(125)
    KICK, SNARE, CHAT, OHAT, CLAP, CRASH, RIDE = 36, 38, 42, 46, 39, 49, 51
    LTOM, MTOM, HTOM = 45, 47, 50

    def page(velocity=(127, 120, 78, 96, 108, 100)):
        return Pattern(tempo=T, numbars=4, gridres=4,
                       channels=(9,) * 6, velocity=velocity, gates=(1,) * 6,
                       drumnos=(KICK, SNARE, CHAT, OHAT, CLAP, CRASH))

    # --- A: the basic beat -------------------------------------------
    A = page()
    for bar in range(4):
        b = bar * 16
        A.hits(0, KICK,  [b + 0, b + 6, b + 8])
        A.hits(1, SNARE, [b + 4, b + 12])
        A.hits(2, CHAT,  [b + s for s in range(0, 16, 2) if s != 14])
        A.hits(3, OHAT,  [b + 14])
    A.hits(5, CRASH, [0])

    # --- B: busier kick, clap doubling the backbeat ------------------
    B = page()
    for bar in range(4):
        b = bar * 16
        B.hits(0, KICK,  [b + 0, b + 3, b + 6, b + 8, b + 11])
        B.hits(1, SNARE, [b + 4, b + 12])
        B.hits(2, CHAT,  [b + s for s in range(0, 16, 2) if s != 14])
        B.hits(3, OHAT,  [b + 14])
        B.hits(4, CLAP,  [b + 4, b + 12])

    # --- C: fill, tom run in the last bar ----------------------------
    C = page()
    for bar in range(3):
        b = bar * 16
        C.hits(0, KICK,  [b + 0, b + 6, b + 8])
        C.hits(1, SNARE, [b + 4, b + 12])
        C.hits(2, CHAT,  [b + s for s in range(0, 16, 2) if s != 14])
        C.hits(3, OHAT,  [b + 14])
    b = 48
    C.hits(0, KICK, [b + 0, b + 8])
    C.hits(1, SNARE, [b + 4, b + 6])
    C.hits(4, LTOM, [b + 10, b + 11])
    C.hits(4, MTOM, [b + 12, b + 13])
    C.hits(4, HTOM, [b + 14, b + 15])

    # --- D: breakdown, hats and ride only ----------------------------
    D = page(velocity=(127, 120, 64, 88, 96, 84))
    for bar in range(4):
        b = bar * 16
        D.hits(2, CHAT, [b + s for s in range(0, 16, 2)])
        D.hits(5, RIDE, [b + 0, b + 8])
        if bar >= 2:
            D.hits(0, KICK, [b + 0, b + 8])
    return Song("AABACAABDCAB*", {'A': A, 'B': B, 'C': C, 'D': D},
                instruments=(0,) * 6, title="MIDI-80 Drums")


SONGS = [("BOOGIE", boogie), ("SEQUENCE", sequence), ("DRUMS", drums)]

if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out, exist_ok=True)
    for name, fn in SONGS:
        s = fn()
        warn = s.check()
        dump = s.build_dump()
        open(os.path.join(out, name + ".DUMP"), 'wb').write(dump)
        s.write_mid(os.path.join(out, name + ".mid"), loops=2)
        pats = sorted(s.patterns)
        bars = sum(s.patterns[c].numbars for c in s.arrangement if c not in '.*')
        p0 = s.patterns[pats[0]]
        print("%-9s %d bytes  patterns %s  arrangement %-14s %3d bars  "
              "plays %.1f BPM (M3) / %.1f (M1), reads BPM:%d"
              % (name, len(dump), ",".join(pats), s.arrangement, bars,
                 p0.real_bpm(3), p0.real_bpm(1), p0.bpm(3)))
        for w in warn:
            print("           WARNING: " + w)

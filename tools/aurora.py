"""AURORA - a Berlin school piece for the MIDI/80 TRACKER.

Tangerine Dream around Phaedra and Ricochet: a sequencer that never stops,
a second one running at a different length so the two drift in and out of
phase, harmony that moves about four times slower than you expect, and
everything else arriving and leaving over the top of it.

In D minor. Eight bars of 16th notes per pattern, nine patterns, and the
arrangement loops.

  usage: python3 tools/aurora.py <output-dir>
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mksong import Pattern, Song, n, tempo_for

T = tempo_for(116)

# --- the harmony ---------------------------------------------------------
# Four bars of D minor before anything moves at all; that stillness is the
# whole point of the style. Then Bb, F, C and back.
CHORDS = ['Dm', 'Dm', 'Dm', 'Dm', 'Bb', 'Bb', 'F', 'C']
STATIC = ['Dm'] * 8

# --- the sequence --------------------------------------------------------
# Eight notes, played as straight 16ths and repeated twice a bar. The shape
# is an ascending arpeggio that turns over at the top, so the ear hears a
# loop rather than a scale.
SEQ = {
    'Dm': ['d3', 'a3', 'd4', 'f4', 'a4', 'f4', 'd4', 'a3'],
    'Bb': ['a#2', 'f3', 'a#3', 'd4', 'f4', 'd4', 'a#3', 'f3'],
    'F':  ['f2', 'c3', 'f3', 'a3', 'c4', 'a3', 'f3', 'c3'],
    'C':  ['c3', 'g3', 'c4', 'e4', 'g4', 'e4', 'c4', 'g3'],
}
# The counter-sequencer takes a sparser set an octave up.
SEQ2 = {'Dm': ['d5', 'f5', 'a5', 'f5'], 'Bb': ['a#4', 'd5', 'f5', 'd5'],
        'F':  ['c5', 'f5', 'a5', 'f5'], 'C':  ['g4', 'c5', 'e5', 'c5']}
ROOT = {'Dm': 'd1', 'Bb': 'a#1', 'F': 'f1', 'C': 'c2'}
PAD  = {'Dm': 'd4', 'Bb': 'a#3', 'F': 'c4', 'C': 'e4'}


def build(chords=None, seq2=False, bass=False, pad=False, drums=False,
          half=False, lead=None, sparse=False):
    """One page. Every layer is optional, which is how the piece is built."""
    p = Pattern(tempo=T, numbars=8, gridres=4,
                channels=(0, 1, 2, 3, 4, 9),
                velocity=(106, 88, 118, 64, 96, 118),
                #        seq  seq2 bass pad  lead drums
                gates=(1, 2, 14, 16, 12, 1))
    chords = chords or CHORDS

    for bar, ch in enumerate(chords):
        b = bar * 16
        notes = SEQ[ch]
        if sparse:
            # the opening: every other note, so the sequence arrives in pieces
            for i in range(0, 8, 2):
                p.put(0, b + i, notes[i])
                p.put(0, b + 8 + i, notes[i])
        else:
            p.line(0, b, 1, notes)              # 16ths, first half of the bar
            p.line(0, b + 8, 1, notes)          # ... and again
        if bass:
            p.put(2, b, ROOT[ch])
        if pad:
            p.put(3, b, PAD[ch])
        if drums:
            p.hits(5, 36, [b] if half else [b, b + 8])              # kick
            p.hits(5, 42, [b + s for s in range(2, 16, 4)])          # hat
            if not half:
                p.hits(5, 38, [b + 4, b + 12])                       # snare
                p.hits(5, 46, [b + 14])                              # open hat

    # The second sequencer runs on a five step cycle against a sixteen step
    # bar, so it takes five bars to come back round - the two patterns drift
    # apart and meet again, which is the sound this style is built on.
    if seq2:
        i = 0
        for step in range(0, 128, 5):
            ch = chords[step // 16]
            cell = SEQ2[ch]
            p.put(1, step, cell[i % len(cell)])
            i += 1

    if lead:
        for step, note in lead:
            p.put(4, step, note)
    return p


# A slow line over the top - whole and half notes, nothing hurried.
LEAD_A = [(0, 'd5'), (16, 'f5'), (32, 'e5'), (48, 'd5'),
          (64, 'a#4'), (80, 'd5'), (96, 'c5'), (112, 'a4')]
LEAD_B = [(0, 'a5'), (24, 'g5'), (32, 'f5'), (56, 'e5'),
          (64, 'f5'), (88, 'd5'), (96, 'e5'), (104, 'g5'), (116, 'a5')]


def aurora():
    A = build(STATIC, sparse=True)                                  # the sequence assembles
    B = build(STATIC)                                               # ... complete, still static
    C = build(STATIC, bass=True)                                    # the bass pedal enters
    D = build(bass=True)                                            # the harmony finally moves
    E = build(bass=True, seq2=True, pad=True)                       # counter-sequencer + pad
    F = build(bass=True, seq2=True, pad=True, drums=True, half=True)  # drums, half time
    G = build(bass=True, seq2=True, pad=True, drums=True)           # full
    H = build(bass=True, seq2=True, pad=True, drums=True, lead=LEAD_A)
    I = build(bass=True, seq2=True, pad=True, drums=True, lead=LEAD_B)
    J = build(bass=True, seq2=True, pad=True)                       # drums drop out
    K = build(STATIC, bass=True, pad=True, sparse=True)             # back to the opening
    return Song("ABCDEFGHIGJK*",
                {'A': A, 'B': B, 'C': C, 'D': D, 'E': E, 'F': F,
                 'G': G, 'H': H, 'I': I, 'J': J, 'K': K},
                #            seq  seq2 bass pad  lead  drums
                instruments=(81,  80,  39,  89,  52,   0),
                title="MIDI-80 Aurora")


if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else '.'
    os.makedirs(out, exist_ok=True)
    s = aurora()
    for w in s.check():
        print("  warning: " + w)
    dump = s.build_dump()
    open(os.path.join(out, 'AURORA.DUMP'), 'wb').write(dump)
    s.write_mid(os.path.join(out, 'AURORA.mid'))
    pats = sorted(s.patterns)
    bars = sum(s.patterns[c].numbars for c in s.arrangement if c not in '.*')
    p0 = s.patterns[pats[0]]
    print("AURORA  %d bytes  patterns %s  arrangement %s  %d bars  tempo %d -> %d BPM"
          % (len(dump), ",".join(pats), s.arrangement, bars, p0.tempo, p0.bpm()))

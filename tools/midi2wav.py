"""Render a .MID to a .WAV with a small built-in synth.

There is no soundfont on this machine, so this is a rough GM-flavoured
approximation - enough to hear whether a song works, not a substitute for a
real module. With fluidsynth and a GM soundfont installed you would get a
much better rendering:

    fluidsynth -F out.wav /usr/share/sounds/sf2/FluidR3_GM.sf2 song.mid

usage: python3 midi2wav.py song.mid out.wav [seconds]
"""
import sys, struct, math
import numpy as np

SR = 44100

def vlq(d, i):
    v = 0
    while True:
        b = d[i]; i += 1; v = (v << 7) | (b & 0x7F)
        if not b & 0x80:
            return v, i

def parse(path):
    """-> (events, ppq) with events as (seconds, status, d1, d2)."""
    d = open(path, 'rb').read()
    assert d[:4] == b'MThd'
    fmt, ntrk, ppq = struct.unpack('>HHH', d[8:14])
    i = 14; raw = []
    for _ in range(ntrk):
        ln = struct.unpack('>I', d[i+4:i+8])[0]
        body = d[i+8:i+8+ln]; i += 8 + ln
        t = 0; j = 0; run = None
        while j < len(body):
            dt, j = vlq(body, j); t += dt
            b = body[j]
            if b == 0xFF:
                j += 1; typ = body[j]; j += 1; n, j = vlq(body, j)
                raw.append((t, 'meta', typ, body[j:j+n])); j += n; continue
            if b & 0x80:
                run = b; j += 1
            nd = 1 if (run & 0xF0) in (0xC0, 0xD0) else 2
            raw.append((t, 'ch', run, body[j:j+nd])); j += nd
    raw.sort(key=lambda e: e[0])
    # tempo map -> seconds
    out = []; bpm = 120.0; prev = 0; sec = 0.0
    for t, kind, a, b in raw:
        sec += (t - prev) / ppq * 60.0 / bpm; prev = t
        if kind == 'meta':
            if a == 0x51:
                bpm = 60_000_000 / int.from_bytes(b, 'big')
        else:
            out.append((sec, a, b[0], b[1] if len(b) > 1 else 0))
    return out

def env(n, a, d, s, r, sus):
    """ADSR over n samples; sus is the sustain length in samples."""
    a, d, r = max(1, int(a*SR)), max(1, int(d*SR)), max(1, int(r*SR))
    e = np.zeros(n)
    k = min(a, n); e[:k] = np.linspace(0, 1, k)
    if k < n:
        m = min(d, n-k); e[k:k+m] = np.linspace(1, s, m)
        if k+m < n:
            hold = min(max(0, sus-k-m), n-k-m)
            e[k+m:k+m+hold] = s
            j = k+m+hold
            if j < n:
                e[j:] = s * np.linspace(1, 0, n-j) ** 2
    return e

def tone(prog, freq, dur, sus, vel):
    n = max(1, int(dur*SR))
    t = np.arange(n) / SR
    ph = 2*np.pi*freq*t
    def saw(k=1): return 2*((freq*k*t) % 1.0) - 1
    def sq(k=1):  return np.sign(np.sin(ph*k))
    if prog < 8:                       # piano
        w = np.sin(ph) + .5*np.sin(2*ph) + .25*np.sin(3*ph)
        e = env(n, .004, .35, .35, .25, sus)
    elif 16 <= prog < 24:              # organ
        w = np.sin(ph) + .6*np.sin(2*ph) + .4*np.sin(4*ph) + .25*np.sin(6*ph)
        e = env(n, .012, .05, .92, .06, sus)
    elif 24 <= prog < 32:              # guitar
        w = np.tanh(2.2*(saw()*.7 + np.sin(ph)*.5))
        e = env(n, .003, .25, .5, .18, sus)
    elif 32 <= prog < 40:              # bass
        w = np.sin(ph) + .35*np.sin(2*ph) + .18*saw()
        e = env(n, .004, .18, .6, .12, sus)
    elif 88 <= prog < 96:              # pad
        w = saw()*.5 + saw(1.005)*.5 + np.sin(ph)*.4
        e = env(n, .35, .3, .8, .6, sus)
    elif prog >= 80:                   # synth lead
        w = sq() * .45 + saw() * .55
        e = env(n, .006, .12, .72, .1, sus)
    else:
        w = np.sin(ph); e = env(n, .01, .2, .6, .15, sus)
    return w * e * (vel/127.0) * .28

def drum(note, vel):
    def noise(d, hp=0.0):
        n = int(d*SR); x = np.random.RandomState(note).randn(n)
        if hp:                          # cheap one pole high pass
            b = math.exp(-2*math.pi*hp/SR); y = np.zeros(n); acc = 0.0
            for i in range(0, n, 64):
                blk = x[i:i+64]; y[i:i+64] = blk - acc; acc = acc*b + blk.mean()*(1-b)
            x = y
        return x
    if note == 36:                                    # kick
        n = int(.28*SR); t = np.arange(n)/SR
        f = 120*np.exp(-t*28) + 43
        w = np.sin(2*np.pi*np.cumsum(f)/SR) * np.exp(-t*11)
    elif note in (38, 40):                            # snare
        n = int(.20*SR); t = np.arange(n)/SR
        w = (noise(.20)*.8 + np.sin(2*np.pi*190*t)*.5) * np.exp(-t*22)
    elif note == 39:                                  # clap
        n = int(.22*SR); t = np.arange(n)/SR
        w = noise(.22, 900) * (np.exp(-t*32) + .5*np.exp(-((t-.012)*260)**2))
    elif note == 42:                                  # closed hat
        n = int(.055*SR); t = np.arange(n)/SR
        w = noise(.055, 7000) * np.exp(-t*95)
    elif note == 46:                                  # open hat
        n = int(.34*SR); t = np.arange(n)/SR
        w = noise(.34, 6500) * np.exp(-t*9)
    elif note in (45, 47, 50):                        # toms
        n = int(.30*SR); t = np.arange(n)/SR
        base = {45: 110, 47: 150, 50: 200}[note]
        f = base*np.exp(-t*9) + base*.62
        w = (np.sin(2*np.pi*np.cumsum(f)/SR) + noise(.30)*.12) * np.exp(-t*10)
    elif note in (49, 51, 57):                        # crash / ride
        n = int(1.1*SR); t = np.arange(n)/SR
        w = noise(1.1, 5200) * np.exp(-t*(2.6 if note == 49 else 5.0))
    else:
        n = int(.12*SR); t = np.arange(n)/SR
        w = noise(.12, 3000)*np.exp(-t*30)
    return w * (vel/127.0) * .40

def render(path, out, limit=None):
    ev = parse(path)
    if limit:
        ev = [e for e in ev if e[0] <= limit]
    total = int((max(e[0] for e in ev) + 2.0) * SR)
    buf = np.zeros(total + SR)
    prog = {}
    live = {}
    for sec, st, d1, d2 in ev:
        ch, kind = st & 0x0F, st & 0xF0
        if kind == 0xC0:
            prog[ch] = d1
        elif kind == 0x90 and d2:
            live[(ch, d1)] = (sec, d2)
        elif kind in (0x80, 0x90):
            k = live.pop((ch, d1), None)
            if k is None:
                continue
            t0, vel = k
            i0 = int(t0*SR)
            if ch == 9:
                w = drum(d1, vel)
            else:
                dur = max(.06, sec - t0) + .35
                w = tone(prog.get(ch, 0), 440.0*2**((d1-69)/12.0), dur,
                         int(max(.05, sec-t0)*SR), vel)
            buf[i0:i0+len(w)] += w
    peak = np.abs(buf).max()
    if peak > 0:
        buf = buf / max(peak, 1.0) * .89 if peak > .89 else buf
    pcm = np.clip(buf, -1, 1)
    data = (pcm*32767).astype('<i2').tobytes()
    with open(out, 'wb') as f:
        f.write(b'RIFF' + struct.pack('<I', 36+len(data)) + b'WAVEfmt ' +
                struct.pack('<IHHIIHH', 16, 1, 1, SR, SR*2, 2, 16) +
                b'data' + struct.pack('<I', len(data)))
        f.write(data)
    return len(buf)/SR, peak

if __name__ == "__main__":
    lim = float(sys.argv[3]) if len(sys.argv) > 3 else None
    dur, peak = render(sys.argv[1], sys.argv[2], lim)
    print("%s -> %s  %.1f s, peak %.2f" % (sys.argv[1], sys.argv[2], dur, peak))

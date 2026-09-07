# `ldoswrite.py` — insert files into an LDOS disk image

Adds files to an existing bootable LDOS floppy image, in place, with no
emulator and no Wine. Written because the documented tool for this job —
`trswrite.exe` from Matthew Reed's TRSTOOLS — is a Windows binary whose
original download site (`trs-80emulators.com`) is now a parked domain,
and the mirror at trs-80.com blocks scripted downloads.

```sh
python3 tools/ldoswrite.py IN.DSK OUT.DSK  path/to/file.cmd=NAME/EXT  [more...]
```

Example — the disks in this repository were built with:

```sh
python3 tools/ldoswrite.py MIDI2.DSK TRACKER.DSK \
    zout/tracker6.cmd=TRACKER6/CMD \
    zout/tracker7.cmd=TRACKER7/CMD
hxcfe -finput:TRACKER.DSK -foutput:TRACKER_DSK.hfe -conv:HXC_HFE
```

Handles **JV3** (Model III, 40x18x256) and **JV1** (Model I, 35x10x256);
`hxcfe` from [HxCFloppyEmulator](https://github.com/jfdelnero/HxCFloppyEmulator)
reads both natively and produces the `.hfe` for Gotek/HxC.

## The LDOS on-disk format, as verified against real disks

Everything below was reverse-engineered from the existing `MIDI2.DSK`
and checked against LDOS's own `DIR` output.

**GAT** (directory track, sector 0) — one byte per track, one bit per
granule, **0 = free**. Model III has 3 granules/track of 6 sectors;
Model I has 2 granules/track of 5 sectors.

**Directory entry** (32 bytes):

| Offset | Meaning |
| --- | --- |
| 0 | flags; bit 4 = in use, bit 3 = invisible |
| 1 | month |
| 2 | `(day << 3) \| (year - 1980)` |
| 3 | EOF offset within the last record |
| 4 | LRL (0 means 256) |
| 5–12 | filename, space padded |
| 13–15 | extension |
| 16–19 | password hashes (`96 42 96 42` = none) |
| 20–21 | ERN, the record count |
| 22–29 | up to 4 extents, `FF` terminates |

**Extent** = `(track, (granule_offset << 5) | (granule_count - 1))`.

**HIT** (directory track, sector 1) — the hash index. The layout is
*transposed*: `index = entry * 32 + (dir_sector - 2)`. The hash is

```
h = 0;  for each of the 11 bytes of NAME+EXT:  h ^= c;  h = rol8(h)
if h == 0: h = 1
```

Both the hash and the transposed indexing were confirmed against all 24
pre-existing entries on `MIDI2.DSK` — 24/24 match, no stray bytes.

## Verification

Files written by this tool were checked three ways: read back from the
image byte-for-byte against the source (identical, including a
fragmented 4-extent case), listed correctly by LDOS's own `DIR` with the
right record counts and dates, and actually **run** on both a Model III
and a Model I under emulation — including from the converted `.hfe`.

# 
# This fork is the commandline version of "Python MIDI > BIN Converter" by Michael Wessel 
# You can use it with Linux/Windows/Mac to convert MIDI files in batch mode.
#
# Python MIDI -> BIN Converter for the Amstrad CPC 
# (C) 2022 by Michael Wessel, aka LambdaMikel
# Version 1.1
#
# License: GPL-3.0
# https://github.com/lambdamikel/BluePillCPC/blob/main/LICENSE
# See https://github.com/lambdamikel/BluePillCPC
#
# Purpose: Given a .MID MIDI song input file, generate a set of 16 KB
# .BIN files suitable for playback by the playback.bin MIDI playback
# program for the Amstrad CPC. This program supports MIDI playback
# from these .BIN files over the Ultimate CPC MIDI Card, LambdaSpeak 3
# and FS, as well as the Willy Soundcard with an S2P.
#

import os
import mido
import argparse
import mido.ports
from mido import MetaMessage

messages = []

parser = argparse.ArgumentParser(
    prog='python midi2bin_converter.py',
    description='Example: python midi2bin_converter.py midifile.mid [outputdir: default=midibin] [playback_factor: default=300 (higher value is slower playback)] [max_bin_files: default=2]')

parser.add_argument("midifile", nargs=1, default="", type=str)
parser.add_argument("outputdir", nargs='?', default="midibin", type=str)
parser.add_argument("playback_factor", nargs='?', default="300", type=int)
parser.add_argument("max_bin_files", nargs='?', default="2", type=int)
args = parser.parse_args()

# Use commandline parameters
midifile=''.join(args.midifile)
outputdir=''.join(args.outputdir)
playback_factor=args.playback_factor
max_bin_files=args.max_bin_files

print ("\nStart converting midi file ...")
print ("Source midifile:  ",midifile)
print ("Output directory: ",outputdir)
print ("Playback factor:  ",playback_factor)
print ("Max number of 16k BIN files to create: ", max_bin_files)

# Get midi file
midifilename = midifile.split(".")[0]
midifilebasename = os.path.basename(midifilename)

# BIN converter function
def convert_to_bin(messages):

    print ("\nConverting to bin ...")

    cur = 0
    file_count = 0
    file = None

    isExist = os.path.exists(outputdir)
    if not isExist:
        os.makedirs(outputdir)
   
    last_time = -1
    
    for msg in messages:

        time1 = msg.time

        #if last_time == -1:
        #    last_time = time1
            #delta = int((time1 - last_time)*50)

        delta = round(time1 * float(playback_factor))

        #print(delta)

        #last_time = time1

        hex_bytes = msg.hex().split()

        for byte in hex_bytes:

            if cur % 0x4000 == 0:
                if file:
                    file.close()
                    if file_count == 2:
                        exit()
                file = open(outputdir + "/" + midifilebasename + str(file_count) + ".bin", "wb")
                print ("Output file: " + outputdir + "/" + midifilebasename + str(file_count) + ".bin")
                file_count += 1

            lenlo = delta & 255
            lenhi = (delta & (255 << 8)) >> 8
            if lenhi > 0 or lenlo == 255:
                #print(f"Warning - out of range: {lenhi, lenlo}. Clipping to 254!")
                lenlo = 254

            #triple_bytes = bytes([int(lenlo), int(lenhi), int(byte, 16)])
            pair_bytes = bytes([int(lenlo), int(byte, 16)])
            file.write(pair_bytes)

            cur += 2
            delta = 0
    
    # End program
    exit()

# Stream MIDI data to variable
def utf8len(s):
    return len(s.encode('utf-8'))

filename = midifile
mid = mido.MidiFile(filename)
    
print ("Progress ", end="", flush=True)
messages = []
for msg in mid.play():
    messages.append(msg)
    # Print progress ...
    print (".", end="", flush=True)
    msgstring=''.join(str(e) for e in messages)
    # Check length of messages var and proceed with converting
    if utf8len(msgstring) >= max_bin_files * 129120:
        messages.append(MetaMessage('end_of_track'))
        print(str(utf8len(msgstring)) + " done! \n")
        convert_to_bin(messages)
convert_to_bin(messages)
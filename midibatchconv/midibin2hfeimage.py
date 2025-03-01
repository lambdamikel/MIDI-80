#
# Python MIDI-BIN to HFE-Image Batch Converter 
# (C) 2025 by Juergen Wich, aka Retroguy
# Version 0.5
#
# License: GPL-3.0
# https://github.com/lambdamikel/MIDI-80/blob/main/LICENSE
# See https://github.com/lambdamikel/MIDI-80
#
# Purpose: This script takes MIDI .bin files, compiles them together 
# with a small playback tool with the zmac Z80 cross assembler and 
# creates LDOS images from them. The image files are then converted to 
# create HxC disk images (.hfe). These images can then be executed e.g. 
# with the Gotek Floppy Emulator or HxC Floppy Emulator on the TRS-80. 
# midibin2hfeimage.py uses two Windows tools (trswrite.exe and zmac.exe), 
# which require a Wine installation under Linux. The command line tool 
# hxcfe is also required. You can install the Linux or the Windows version of hxcfe.

import os
import shutil
import fileinput
import re
import pathlib
import subprocess
import argparse
from sys import platform

# Change the following in- and output sub-folder for your needs.
MIDIBINDIR="midibin"      # provide .bin files here
ASMDIR="asmfiles"         # temp folger for asm file processing
CMDDIR="cmdfiles"         # temp folder for cmd file processing
DMKDIR="dmkfiles"         # temp folder for dmk file processing
HFEDIR="hfefiles"         # output folder for .hfe Images

# These are the template files 
ASMTEMPLATE1="canyon_asm.m1.template"
ASMTEMPLATE3="canyon_asm.m3.template"
M1LDOSIMAGE="blank-boot-trs80-m1-ldos.dmk"
M3LDOSIMAGE="blank-boot-trs80-m3-ldos.dmk"

parser = argparse.ArgumentParser(
    prog='python midibin2hfeimage.py',
    description='Example: python midibin2hfeimage.py [TRS80_MODEL: default=1, 3] ')

parser.add_argument("TRS80_MODEL", nargs='?', default="1", type=int)
args = parser.parse_args()

if args.TRS80_MODEL == 1:
    LDOSIMAGE=M1LDOSIMAGE
    ASMTEMPLATE=ASMTEMPLATE1
elif args.TRS80_MODEL == 3:
    LDOSIMAGE=M3LDOSIMAGE
    ASMTEMPLATE=ASMTEMPLATE3
else:
    LDOSIMAGE=M1LDOSIMAGE
    ASMTEMPLATE=ASMTEMPLATE1


# Let's start converting the files!

# Check environment
SCRIPTPATH=os.getcwd()
if platform == "linux" or platform == "linux2":
    try:
        # Is Wine installed on Linux?
        wineinstalled=subprocess.run(['wine', '--help'], stdout=subprocess.DEVNULL)
        if wineinstalled.returncode != 0:
            raise ValueError("cannot execute wine")
    except:
        print("Can not execute Windows execution layer 'wine'. Wine is needed on Linux to execute trswrite.exe and zmac.exe. Please install wine!")
        exit(1)

    # On Linux you can use either the Linux or the Windows version of hxcfe tool
    if os.path.isfile('hxcfe'):
        HXCFE="hxcfe"
    elif os.path.isfile('hxcfe.exe'):
        HXCFE="hxcfe.exe"
    
    TOOLS= [HXCFE, "trswrite.exe", "zmac.exe"]
    for TOOL in TOOLS:
        try:
            if not os.path.isfile(TOOL):
                raise ValueError("file not found")
        except:
            print(f"Please install { TOOL } for Linux to your script folder!")
            exit(1)

elif platform == "win32":
    HXCFE="hxcfe.exe"
    TOOLS= [HXCFE, "trswrite.exe", "zmac.exe"]
    for TOOL in TOOLS:
        try:
            if not os.path.isfile(TOOL):
                raise ValueError("file not found")
        except:
            print(f"Please install { TOOL } for Windows to your script folder!")
            exit(1)


# Copy asm template and replace text of title and incbin
print ("\nCreating .asm files from .bin files")
if not os.path.isdir(ASMDIR):
   os.makedirs(ASMDIR)

with os.scandir(MIDIBINDIR) as filenames:
    for filename in filenames:
        if filename.name.lower().endswith('0.bin'):
            ASMFILE=os.path.splitext(filename.name)[0][:-1]+".asm"
            SONGNAME=os.path.splitext(filename.name)[0][:-1]
            shutil.copy(ASMTEMPLATE, os.path.join(ASMDIR, ASMFILE))

            with fileinput.FileInput(os.path.join(ASMDIR, ASMFILE), inplace=True) as file:
                for line in file:
                    line=re.sub(r"^title2.*", f"title2          defb  '    SONGNAME: { SONGNAME }', ENTER", line) 
                    print(line, end='')
            with fileinput.FileInput(os.path.join(ASMDIR, ASMFILE), inplace=True) as file:
                MIDIBINFILE="incbin "+repr(os.path.join(MIDIBINDIR, filename.name))
                for line in file: 
                    line=re.sub(r";;incbin.*RINGOF0.BIN\"", MIDIBINFILE, line)
                    print(line, end='')

with os.scandir(MIDIBINDIR) as filenames:
    for filename in filenames:
        if filename.name.lower().endswith('1.bin'):
            ASMFILE=os.path.splitext(filename.name)[0][:-1]+".asm"
            SONGNAME=os.path.splitext(filename.name)[0][:-1]

            with fileinput.FileInput(os.path.join(ASMDIR, ASMFILE), inplace=True) as file:
                for line in file:
                    MIDIBINFILE="incbin "+repr(os.path.join(MIDIBINDIR, filename.name))
                    line=re.sub(r";;incbin.*RINGOF1.BIN\"", MIDIBINFILE, line) 
                    print(line, end='')

# Compile .asm files with zmac
print("\nStarting zmac assembler processing ...")
asm = list(pathlib.Path(ASMDIR).glob('*.asm'))
NUMBEROFASMFILES = len(asm)

# Delete zout temp folder before starting compile process
try:
    shutil.rmtree("zout/")
except OSError as e:
    print(f'{e.strerror} ... Creating directory: zout')

# Compile asm files
with os.scandir(ASMDIR) as asmfilenames:
    for asmfilename in asmfilenames:
        if asmfilename.name.endswith('.asm'):
            subprocess.call([os.path.join(SCRIPTPATH,'zmac.exe'), asmfilename])
            cmd = list(pathlib.Path('zout').glob('*.cmd'))
            NUMBEROFZOUTCMDFILES = len(cmd)
            print (f"{ str(NUMBEROFZOUTCMDFILES) } files of { str(NUMBEROFASMFILES) } processed ...")

# Copy compiled .cmd files from zout to cmddir            
print(f"\nCopying .cmd files to { CMDDIR }..")
if not os.path.isdir(CMDDIR):
   os.makedirs(CMDDIR)

cmdfiles = list(pathlib.Path('zout').glob('*.cmd'))
for cmdfile in cmdfiles:
    if os.path.isfile(cmdfile):
        shutil.copy(cmdfile, CMDDIR)
   
# Create .dmk image files from template and copy .cmd file to image with trswrite.exe
print("\nAdding .cmd file to dmk image ...")
if not os.path.isdir(DMKDIR):
   os.makedirs(DMKDIR)

with os.scandir(CMDDIR) as filenames:
    for filename in filenames:
        DMKFILE=os.path.splitext(filename.name)[0]+".dmk"
        shutil.copy(LDOSIMAGE, os.path.join(DMKDIR, DMKFILE))
        print(f"Adding: { filename.name } >> { DMKDIR }/{ DMKFILE }.dmk")
        # Copy cmd file to MIDISONG.CMD so the LDOS AUTO function can load the song automatically
        shutil.copy(filename, 'MIDISONG.CMD')
        subprocess.call([os.path.join(SCRIPTPATH,'trswrite.exe'), '-o', os.path.join(DMKDIR, DMKFILE), 'MIDISONG.CMD'])
        
# Convert .dmk file to .hfe with hxcfe commandline tool
print("\nConverting .dmk to .hfe ...")
if not os.path.isdir(HFEDIR):
   os.makedirs(HFEDIR)

with os.scandir(DMKDIR) as filenames:
    for filename in filenames:
        HFEFILE=os.path.splitext(filename.name)[0]+".hfe"
        subprocess.call([os.path.join(SCRIPTPATH,HXCFE), f"-finput:{ os.path.join(DMKDIR, filename.name) }", f"-foutput:{ os.path.join(HFEDIR, HFEFILE) }", "-conv:HXC_HFE"])

hfe = list(pathlib.Path(HFEDIR).glob('*.hfe'))

NUMBEROFHFEFILES = len(hfe)
print(f"\n{ NUMBEROFHFEFILES } hfe image files created. Have fun!")

# Done!

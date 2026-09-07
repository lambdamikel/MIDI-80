"""Insert a file into an LDOS 5.1 disk image (JV3 Model III / JV1 Model I).

Formats verified by reverse-engineering the existing MIDI2.DSK:
  GAT      one byte per track, bit per granule, 0 = free
  extent   (track, (granule_offset << 5) | (granule_count - 1)), FF terminates
  HIT      index = entry*32 + (dir_sector-2); value = hash, validated 24/24
  hash     h ^= c; h = rol8(h)  over the 11 byte NAME+EXT, 0 -> 1
"""
import sys, os

SZ={0:256,1:128,2:1024,3:512}

class Img:
    def __init__(self, path):
        self.path=path
        self.d=bytearray(open(path,'rb').read())
        if len(self.d)==89600:                      # JV1: 35 x 10 x 256
            self.kind='jv1'; self.spt=10; self.gpt=2; self.tracks=35
            self.sectors={(t,s):((t*10+s)*256,256) for t in range(35) for s in range(10)}
        else:                                       # JV3
            self.kind='jv3'; self.spt=18; self.gpt=3; self.tracks=40
            self.sectors={}; off=0x2200
            for i in range(2901):
                t,s,f=self.d[i*3],self.d[i*3+1],self.d[i*3+2]
                if t==0xFF: continue
                n=SZ[f&3]; self.sectors[(t,s)]=(off,n); off+=n
        self.spg = self.spt//self.gpt               # sectors per granule
        self.dirtrack = self.rd(0,0)[2]
    def rd(self,t,s):
        o,n=self.sectors[(t,s)]; return self.d[o:o+n]
    def wr(self,t,s,data):
        o,n=self.sectors[(t,s)]
        assert len(data)<=n
        # NOTE: slice length must be n, not len(data). Assigning n bytes into a
        # shorter slice GROWS the bytearray and shifts every following sector.
        self.d[o:o+n] = bytes(data) + bytes(n-len(data))
    def save(self,path):
        open(path,'wb').write(bytes(self.d))

def ldos_hash(nm):
    h=0
    for c in nm:
        h ^= c; h=((h<<1)|(h>>7))&0xFF
    return h or 1

def free_granules(img):
    gat=img.rd(img.dirtrack,0)
    out=[]
    for t in range(img.tracks):
        for g in range(img.gpt):
            if not (gat[t]>>g)&1: out.append((t,g))
    return out

def add_file(img, name, ext, data, month=9, day=7, year=1985):
    name=name.upper().ljust(8)[:8]; ext=ext.upper().ljust(3)[:3]
    nm=(name+ext).encode('latin-1')

    # ---- allocate granules ------------------------------------------
    gran_bytes = img.spg*256
    ngran = (len(data)+gran_bytes-1)//gran_bytes
    free = free_granules(img)
    if len(free) < ngran: raise SystemExit("not enough free granules")
    chosen = free[:ngran]

    # ---- write the data ---------------------------------------------
    pos=0
    for (t,g) in chosen:
        for s in range(g*img.spg,(g+1)*img.spg):
            img.wr(t,s,data[pos:pos+256]); pos+=256

    # ---- build extents (merge runs contiguous in track+granule) ------
    ext_list=[]
    for (t,g) in chosen:
        if ext_list:
            lt,lg,cnt = ext_list[-1]
            # next granule position after the run
            nt,ng = lt,lg+cnt
            while ng>=img.gpt: ng-=img.gpt; nt+=1
            if (nt,ng)==(t,g) and cnt<32:
                ext_list[-1]=(lt,lg,cnt+1); continue
        ext_list.append((t,g,1))
    if len(ext_list)>4: raise SystemExit("needs >4 extents (%d); disk too fragmented"%len(ext_list))

    # ---- mark the GAT ------------------------------------------------
    gat=bytearray(img.rd(img.dirtrack,0))
    for (t,g) in chosen: gat[t] |= (1<<g)
    img.wr(img.dirtrack,0,bytes(gat))

    # ---- find a free directory slot ----------------------------------
    slot=None
    for s in range(2,2+16):
        if (img.dirtrack,s) not in img.sectors: break
        blk=img.rd(img.dirtrack,s)
        for e in range(8):
            if not (blk[e*32] and blk[e*32]&0x10):
                slot=(s,e); break
        if slot: break
    if not slot: raise SystemExit("no free directory slot")
    s,e = slot

    # ---- build the entry ---------------------------------------------
    ern = (len(data)+255)//256
    eof = len(data)%256
    ent=bytearray(32)
    ent[0]=0x10                                  # in use, visible
    ent[1]=month
    ent[2]=((day&0x1f)<<3) | ((year-1980)&0x07)
    ent[3]=eof
    ent[4]=0x00                                  # LRL 0 == 256
    ent[5:13]=name.encode('latin-1')
    ent[13:16]=ext.encode('latin-1')
    ent[16:20]=bytes([0x96,0x42,0x96,0x42])      # no password
    ent[20]=ern & 0xFF; ent[21]=(ern>>8)&0xFF
    i=22
    for (t,g,c) in ext_list:
        ent[i]=t; ent[i+1]=((g&7)<<5)|((c-1)&0x1f); i+=2
    for j in range(i,32): ent[j]=0xFF

    blk=bytearray(img.rd(img.dirtrack,s))
    blk[e*32:(e+1)*32]=ent
    img.wr(img.dirtrack,s,bytes(blk))

    hit=bytearray(img.rd(img.dirtrack,1))
    hit[e*32+(s-2)] = ldos_hash(nm)
    img.wr(img.dirtrack,1,bytes(hit))

    print("  + %s/%s  %d bytes, ERN=%d eof=%02x, %d granule(s), extents=%s, dir s=%d e=%d, hit[%d]=%02x"
          %(name.strip(),ext,len(data),ern,eof,ngran,
            ["T%d G%d x%d"%(t,g,c) for t,g,c in ext_list],s,e,e*32+(s-2),ldos_hash(nm)))

if __name__=="__main__":
    src, dst = sys.argv[1], sys.argv[2]
    img=Img(src)
    print("%s: %s, dir track %d, %d sectors/granule, %d free granules"
          %(os.path.basename(src),img.kind,img.dirtrack,img.spg,len(free_granules(img))))
    for spec in sys.argv[3:]:
        hostpath,trsname = spec.split('=')
        n,x = trsname.split('/')
        add_file(img,n,x,open(hostpath,'rb').read())
    img.save(dst)
    print("  wrote %s"%dst)

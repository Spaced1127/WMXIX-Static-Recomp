# Port notes - WWE WrestleMania XIX (GW9E78)

Observations from the retail DOL, kept separate from STATE.md so the state file
stays short.

## Engine

Yuke's wrestling engine, same lineage as *WrestleMania X8* and the *Day of
Reckoning* titles. The DOL ships **retail debug strings** (never stripped), which
gives us named subsystems without a symbol map.

Nintendo SDK libraries in use (inferred from string table and boot code):

- `OS` - standard `__start` at `0x80003154`, `OSInit`, arena init, reset thread.
- `DVD` - `DVDCheckDisk`, "The Disc Cover is open.", "Start resume from DVD Error".
- `PAD` / `SI` - "The Controller in Controller Socket%s has been removed."
- `CARD` - "memory card is unmounted".
- `GX` / `VI` - `CRender)init RenderMode`, EFB pipelines.
- `AR` / `ARAM` - "error : Already moved to ARAM." Audio streaming to Aux RAM.
- `AI` / `AX` - `sound.msx` mixer, CRI ADX (`.yag/.ymg/.ycg/.yad`) banks.
- `DEMO` - `DEMOInit: invalid TV format`.
- `THP` - `.mpq` movie containers in `thp/`, played through the THP player.

## Useful debug strings (grep targets in logs and disassembly)

```text
Begin Initialize Game...
End Initialize Game.
End Exit Game.
Begin Initialize Demo...
End Initialize Demo.
End of Application
Press Reset Button!
start process for software reset
DVDCheckDisk = %d
all sound is stoped
pad mortor is stopedn
memory card is unmounted
fade out finish
OS Protection Error!
Address:    Back Chain LR Save
read background error.
Illigal process before finish to load a data.(in CBgRead::~CBgRead() )
The Disc Cover is open.
Please insert the WRESTLEMANIA XIX Game Disc.
NOW LOADING
dvd error locked.
Start resume from DVD Error
End Of DVD Error
buffer size error!
effect generate error!
not enough memory!!
ERROR)attribute data error!
ERROR)animation data error!
error : Already moved to ARAM.
replay data error!
CObjList)delete %d objects.
DEMOInit: invalid TV format
CRender)init RenderMode.
CRender)init Mem.
```

## Content layout on disc

| Path | Contents |
|---|---|
| `2d/` | 2D UI textures and layout |
| `bg/` | background/environment assets |
| `edit_data/` | create-a-wrestler data |
| `Entrance/` | entrance animations |
| `font/` | fonts |
| `help/` | help screens |
| `menu/` | menus |
| `model/` | character models |
| `motion/` | animations |
| `motion_check/` | animation validation |
| `paint_tool/` | logo editor |
| `ringmotion/` | ring/rope animation |
| `sound/` | `sound.msx` (mixer/bank index) |
| `thp/` | `call.mpq`, `LOADTIPS.mpq`, `thppac.mpq`, `ydspac.mpq` (THP movies) |
| `tutorial/` | tutorial text |
| `viewer/` | model viewer |
| root | `com_dt.mpc`, `static.mpc`, `static_jp.mpc`, `system.cfg`, `opening.bnr`, `pass8.tpl`, `viewlist.txt` |

Extensions: `.tex` 1783, `.ymg` 1464, `.yag` 215, `.ycg` 184, `.atr` 167,
`.pac` 160, `.wparry` 64, `.yad` 41, `.mpc` 13, `.tpl` 9, `.tpg` 9, `.mpq` 7.

## Boot code (0x80003154)

```text
80003154  bl   0x800032b0        ; register setup
80003158  bl   0x80003400        ; __init_hardware
8000315c  li   r0, -1
80003160  stwu r1, -8(r1)
...
8000316c  bl   0x80003340
80003170  li   r0, 0
80003174  lis  r6, -0x8000
80003178  addi r6, r6, 0x44      ; 0x80000044 - OS reset flag
8000317c  stw  r0, 0(r6)
80003188  lwz  r6, 0x800000f4    ; bi2 / debug flag
800031b0  lwz  r7, 0x800030e8
800031e8  lis  r6, -0x7fd6
800031ec  addi r6, r6, -0x2590   ; 0x8029da70 - ARAM/arena callback
800031f0  mtlr r6
800031f4  blrl
```

`0x80003100-0x80003154` is the DOL text-0 prologue (DVD/BI2 helpers), which the
runtime implements natively; `0x80003154` is the real entry point.

## Recomp implications

- **SMC**: DolRecomp reports self-modifying code by highlighting it. Yuke's
  engine does patch code at init in some titles; check `generated_smc.txt`
  before assuming zero patches.
- **ARAM** is used for audio; the runtime must implement `AR` transfers or the
  mixer will stall.
- **`.ymg/.yag/.ycg`** are CRI ADX; the runtime's AX/AI HLE must feed the DSP.
- **THP** movies need the THP player path; expect these to be the first thing
  to break on boot.

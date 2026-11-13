# WWE WrestleMania XIX — GameCube static recompilation

A native Windows port of the retail GameCube release (`GW9E78`), produced by
statically recompiling the game's PowerPC executable with
[DolRecomp](https://github.com/ExpansionPak/DolRecomp) and running it on a
[Dolphin](https://github.com/dolphin-emu/dolphin)-derived runtime
([ModernGekko](https://github.com/ExpansionPak/ModernGekko)), following
[Spaced1127's GameCube Static Recomp Guide](https://github.com/Spaced1127/GameCube-Static-Recomp-Guide).

No game data is included. You need your own legally dumped USA disc.

## Status

| | |
|---|---|
| Disc ID | `GW9E78` |
| DOL SHA-256 | `627b899760d0b820c049ad29f96a613da1c43d35dd4a1456e581cc620bae9fb7` |
| Disc size / CRC-32 | 1,459,978,240 / `635116c6` |
| Boot | `fallback=0`, `smc_failed=0` |
| Speed | 59.94 fps in menus, entrances and normal matches |
| Heaviest scene | Fatal 4-Way, 4 CPU wrestlers: ~50 fps on the static core |
| Core | static recompilation by default, Dolphin JIT selectable |

## Layout

```text
launcher.exe        setup, settings, PLAY
game.exe            the game
game_data/          extracted from the player's own disc (created by setup)
gGW9E78_recomp.dll  the recompiled module, beside game.exe
Sys/                runtime data
defaults/           14 controller profiles + config.play.ini
backdrop.bmp logo.bmp icon.bmp theme.ini   launcher art and strings
```

`launcher.exe --extract <iso>` performs headless setup. `game.exe` with no
arguments boots `game_data/` beside itself.

## Build

### 1. Get the runtime

`lib/` is not committed (upstream code, hundreds of MB):

```powershell
git clone https://github.com/ExpansionPak/ModernGekko-Template.git lib/ModernGekko-Template
cd lib/ModernGekko-Template
git submodule update --init --recursive
```

### 2. Configure and build the tools

```powershell
powershell -File tools\build-tools.ps1     # DolRecomp + moderngekko-port
powershell -File tools\configure-mg.ps1    # project identity, gates, output names
powershell -File tools\build-runtime.ps1   # launcher.exe + game.exe
```

Output names are `launcher` and `game` (`MODERNGEKKO_LAUNCHER_OUTPUT_NAME`,
`MODERNGEKKO_RUNNER_OUTPUT_NAME`), and the runner is pinned to disc ID `GW9E78`
and the retail DOL hash.

### 3. Extract the disc and compile the module

```powershell
python tools\gcdisc.py info    work\disc\game.iso
python tools\gcdisc.py extract work\disc\game.iso work\game
powershell -File tools\recompile.ps1        # generated C + module DLL
```

### 4. Optional: tuned + PGO module

The shipped module is built with `-O3`, thin LTO, loop budget 4096, call depth
128 and `-march=x86-64-v3`, then trained with PGO on a four-wrestler match:

```powershell
powershell -File tools\pgo-tuned.ps1
```

Measured on the same save state: stock 38.8 fps, tuned 42.6, PGO 47.1,
PGO + idle-loop skip 50.5.

### 5. Package

```powershell
powershell -File tools\make-release.ps1 -Version 0.3.1
```

## Controls

The launcher detects the pad, works out its button family (Xbox, PlayStation,
Nintendo, generic) and generates `Config\GCPadNew.ini`. Nintendo pads get A/B
and X/Y swapped so the printed labels match. The Controller page has a
**Button layout** override, and `defaults/` ships profiles for Xbox, Xbox 360,
Xbox Series, DualSense, DualShock 4/3, Switch Pro, Joy-Con, Steam Deck, 8BitDo,
generic SDL, DirectInput and keyboard.

Headless:

```powershell
launcher.exe --user-dir <dir> --write-pad-profile "SDL/0/DualSense Wireless Controller"
```

## Data folders

`%LOCALAPPDATA%\WMXIX`: `config.ini`, `Config\GCPadNew.ini`, `GC` (memory
card), `StateSaves`, `Logs`, `Cache\Shaders`.

## Roadmap / known gaps

- Launcher parity with guide chapter 15 is partial: MSAA/SSAA/AF/VSync/volume
  are not exposed, no card import UI, and the close-timeout kill is missing.
  The audit is in `docs/STATE.md`.
- The static core is CPU-bound; the remaining gap to 60 in a 4-way match is the
  scalar paired-single helpers in `GXRuntime/src/core/cpu.c`.

## Licence

Project code: GPL-3.0 (see `LICENSE`). DolRecomp is GPL-3.0; ModernGekko and
Dolphin are GPL-2.0-or-later (aggregate GPL-3.0). WWE and all related marks are
trademarks of their respective owners. This is an unofficial fan project with
no affiliation.

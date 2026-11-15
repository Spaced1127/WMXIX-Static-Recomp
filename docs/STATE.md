# WWE WrestleMania XIX (GameCube) - Static Recomp State

Living state file. Read this first in any new session.

## Target

| Field | Value |
|---|---|
| Game | WWE WrestleMania XIX (USA) |
| Disc ID | `GW9E78` |
| Title string | `WRESTLEMANIA XIX` |
| Region / country | USA (`0x00`) |
| Disc image size | 1,459,978,240 bytes |
| Disc magic | `0xc2339f3d` (GameCube) |
| DOL offset in ISO | `0x1f700` |
| Entry point | `0x80003154` |
| BSS | `0x8033f800` + `0x5e2a0` |
| FST entries | 5015 |
| DOL SHA-256 | `627b899760d0b820c049ad29f96a613da1c43d35dd4a1456e581cc620bae9fb7` |
| DOL size / CRC-32 | 3,422,144 / `ff848528` |
| Disc CRC-32 | `635116c6` |
| Disc SHA-256 | `b84472a45f66c2ea968f18a4fec7b9abf44b0f1c6fd834e8727332f054e8fcb0` |
| apploader.img | 119,332 bytes, ends `0x1f664`; variant header (ASCII date `2003/04/17`, entry `0x81200258`) |

DOL sections:

```text
text 0  file 0x000100  mem 0x80003100-0x800056c0  size 0x25c0
text 1  file 0x0026c0  mem 0x8001e5c0-0x802dba00  size 0x2bd440
data 0  file 0x2bfb00  mem 0x800056c0-0x80015d80  size 0x106c0
data 1  file 0x2d01c0  mem 0x80015d80-0x8001e5c0  size 0x8840
data 2  file 0x2d8a00  mem 0x802dba00-0x802dba40  size 0x40
data 3  file 0x2d8a40  mem 0x802dba40-0x802dba60  size 0x20
data 4  file 0x2d8a60  mem 0x802dba60-0x802ede40  size 0x123e0
data 5  file 0x2eae40  mem 0x802ede40-0x8033f800  size 0x519c0
data 6  file 0x33c800  mem 0x80395dc0-0x80396e40  size 0x1080
data 7  file 0x33d880  mem 0x803977a0-0x8039d6e0  size 0x5f40
```

Disc content profile (top extensions): `.tex` 1783, `.ymg` 1464, `.yag` 215,
`.ycg` 184, `.atr` 167, `.pac` 160, `.wparry` 64, `.tmp` 64, `.yad` 41,
`.dat` 14, `.mpc` 13, `.tpl` 9, `.tpg` 9, `.mpq` 7.

Notes:
- `.ymg` / `.yag` / `.ycg` / `.yad` are **CRI ADX / Sofdec family** audio and
  movie containers (Yamaha ADX). Expect AE/AX/AI microcode audio.
- `.ymm` may be the movie stream list.
- `.pac` is likely an archive; `.tex`/`.tpl`/`.tpg` are textures.

## Machine inventory

| Tool | Location | Status |
|---|---|---|
| Python 3.14.8 | PATH | OK |
| Git 2.54 | PATH | OK |
| CMake 4.5.0-rc1 | PATH | OK |
| Ninja | VS BuildTools 18 `...\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja` | OK (not on PATH, added by tools/msvc-env.ps1) |
| MSVC | VS BuildTools 18, `vcvars64.bat` | OK |
| LLVM/Clang 22.1.8 | `C:\Program Files\LLVM\bin` | OK |
| lld-link 22.1.8 | same | OK |
| llvm-profdata 22.1.8 | same | OK |
| Dolphin + DolphinTool | `C:\Users\Gamer\Documents\Dolphin-x64` | OK |
| gh 2.103.3 | PATH | OK |
| make / sh / bash | none | not needed; drive CMake directly |

## Layout

```text
work/disc/wmxix.rvz        original dump (kept)
work/disc/wmxix.iso        converted, verified size
work/game/                 extracted sys/ + files/
lib/ModernGekko-Template/  template + submodules
build/                     build tree + modules
tools/                     guide helper scripts + msvc-env.ps1
docs/STATE.md              this file
```

## Phase log

| Phase | Status | Evidence |
|---|---|---|
| Disc identified | done | `gcdisc.py info`: GW9E78, 1459978240 bytes |
| RVZ -> ISO | done | DolphinTool convert, size matches GC standard |
| Submodules | done | DolRecomp + ModernGekko + vendored Dolphin |
| Disc extracted | done | 4222 files, 1.41 GB, `work/game/{sys,files}` |
| DolRecomp built | done | `lib/DolRecomp/build/dolrecomp.exe` (Clang 22) |
| ModernGekko configured | done | MSVC 14.51, Ninja, `GW9E78` + DOL hash gates |
| Runtime built | done | `WMXIXRunner.exe`, `moderngekko-port.exe` |
| C generated | done | 177 chunks, entry `0x80003154`, 103 SMC candidates |
| Module compiled | done | `gGW9E78_recomp.dll` (Clang 22, thin LTO, `-O3`) |
| First boot | done | `booted=1`, `fallback=0`, `smc_failed=0` |
| Full-speed gameplay | done | 59.94 fps after the initial load |
| Input | done | keyboard + XInput layouts in `controls/` |
| Performance baseline | done | stock/tuned/PGO/idle + JIT reference table below |
| Packaging | done | `dist/WMXIX-v0.1.0-Windows-x64.zip`, manifest validates, no game data |
| Artifact test | done | release copied to temp, prepared from ISO, booted from its own folder |

## Core selection (static vs JIT vs interpreter)

The runtime ships **three** ways to execute guest code, and this project uses the
first:

| Core | How to select | Evidence |
|---|---|---|
| Static recomp | default, `CPUCore = 6` (`StaticRecomp`) | `[staticrecomp] module loaded: ... entry=0x80003154` |
| Dolphin JIT64 | `MODERNGEKKO_STATICRECOMP=0` | `SelectCPUCore()` returns `JIT64` on x64 |
| Interpreter fallback | `--allow-interpreter` with no module | `[staticrecomp] shutdown: native=0 ...` |

`SelectCPUCore()` in `src/runtime/dolphin_runtime.cpp`:

```cpp
const char* v = std::getenv("MODERNGEKKO_STATICRECOMP");
return !v || !*v || *v != '0';      // anything except "0" means static
```

JIT64 is genuinely compiled in (23 objects under `PowerPC/Jit64`), not stubbed.
So "is JIT implemented?" = yes, and it is one env var away. `--allow-interpreter`
on its own does **not** pick the JIT; it only permits a run without a module and
lands on the interpreter.

What the logs prove for a normal run:

```text
[staticrecomp] core init
[staticrecomp] module loaded: ...\gGW9E78_recomp.dll entry=0x80003154
[staticrecomp] shutdown: native=205327678 fallback=0 ...
```

`native=` is the count of guest instructions executed by recompiled code;
`fallback=0` means none went to the interpreter. A JIT run instead reports
`native=0` and no module line.

## Performance baseline (Fatal 4-Way save state, 4 CPU wrestlers)

State: `work/states/user-match.state` (Rock / Austin / Triple H / Jericho,
referee, full HUD). A four-wrestler match with CPU opponents is the heaviest
scene in the game. 30-40 s after a 20-25 s warmup, sampling the runtime's own
fps counter.

| Build | Settings | Avg fps | Min | Max |
|---|---|---|---|---|
| Stock module (loop 256, depth 24, generic) | 3x, capped | 40.31 | 37.43 | 43.10 |
| Stock module | 1x, uncapped | 38.82 | 34.42 | 42.54 |
| Tuned (`-O3`, loop 4096, depth 128, x86-64-v3) | 1x, uncapped | 42.58 | 38.01 | 55.89 |
| Tuned + PGO | 1x, uncapped | 47.14 | 44.90 | 49.37 |
| Tuned + PGO + idle skip | 1x, uncapped | **50.50** | 46.25 | 52.23 |
| Tuned + PGO + idle skip | 3x, capped | 48.96 | 45.81 | 51.91 |
| Dolphin JIT64 (reference) | 1x, uncapped | **205.28** | 187.57 | 221.58 |

What each step bought (uncapped, same state):

| Change | fps | delta |
|---|---|---|
| stock | 38.82 | - |
| loop 256 -> 4096, depth 24 -> 128, `-march=x86-64-v3` | 42.58 | +9.7% |
| PGO on real gameplay | 47.14 | +10.7% |
| idle-loop skip at `0x8027BA24` | 50.50 | +7.1% |

Conclusions:

- The port is **CPU-bound**; 1x uncapped and 3x capped are the same number.
- Stock -> fully tuned is **+30%**, and that is what closed most of the gap.
- The rest of the gap to 60 Hz in a four-wrestler match is real: the static
  module does ~50 fps there while Dolphin's JIT does 205. Normal matches,
  entrances and menus hold 59.94.
- Cause, from the PGO profile: the game leans hard on Gekko paired-single ops
  (`ppc_ps_madds1` 444M, `ppc_ps_madds0` 412M, `psq_load` 223M per 90 s run).
  The C runtime emulates those scalarly; JIT64 emits real SSE. Closing that
  means vectorising the `ppc_ps_*` helpers in `GXRuntime/src/core/cpu.c`, which
  is shared runtime code and a separate project.

### Idle-loop skip

`0x8027BA24` is a three-instruction spin:

```text
8027ba24  lwz    r0, -0x6c08(r13)
8027ba28  cmplwi r0, 0
8027ba2c  beq    0x8027ba24
```

The PGO profile counted 3,264,923,704 iterations of it. Setting
`[Core] StaticRecompIdlePC = 2150087204` (0x8027BA24) in `Config/Dolphin.ini`
makes the runtime call `CoreTiming::Idle()` instead of spinning - the guide's
recommended fix. Verified in play: the runtime removes the spin from the
profile's top sites and gameplay renders normally.

## Measured behaviour (first working build)

| Stage | Result |
|---|---|
| Boot to PRESS START | ~70 s on this machine |
| PRESS START -> Choose A Mode | reachable, renders correctly |
| Steady state | **59.94 fps / 59.94 vps** |
| Runtime stats after a 160 s run | `fallback=0`, `smc_failed=0`, `native_exc` nonzero (expected: game uses OS exception handlers) |
| Intro movies | THP plays (letterboxed FMV renders) |
| Memory card | `work/user/GC/USA/Card A/78-GW9E-__2f__wmx9_sys.gci` created |

Reading the fps field too early is misleading: during boot/loading the
instantaneous `fps` reads 2-3 because the game is streaming assets, then it
settles at 59.94. `vps` and `speed` stay near 1.0 throughout.

Static module vs runtime JIT reference (headless, 30 s): JIT completed more
frames early on, but both reach 59.94 once the game is past loading. Re-measure
with a save state for a fair comparison.

## Controls

`work/user/Config/GCPadNew.ini` is required - without it the pad is silent and
the game cannot leave the title screen. `tools\set-controls.ps1` asks the
runtime for its device list and writes the matching profile; it currently
selects the connected **DualSense via `SDL/0/DualSense Wireless Controller`**.
See `docs/CONTROLS.md`.

Finding worth keeping: the device string is `Source/Id/Name`, so
`DInput/0/Keyboard Mouse` and `SDL/0/DualSense Wireless Controller` are the
forms to use. A wrong device string still loads (`loaded=1`) and binds nothing
- there is no error.

DirectInput does not see injected `SendKeys`/`keybd_event` in a
non-interactive session, so keyboard bindings cannot be machine-tested here.
The pad path was proven instead with `Buttons/A = `Battery`` on the SDL
DualSense: the guest reported `buttons=0x0100` (A pressed), which exercises
ini -> device -> input -> pad -> SI.

## Local runtime patches (not upstream)

Kept small and inert unless `MODERNGEKKO_INPUT_DEBUG=1`:

| File | Change |
|---|---|
| `src/runtime/game.cpp` | `HashDirectorySha256` no longer throws on non-ANSI file names (see above) |
| `vendor/dolphin/.../SI/SI_DeviceGCController.cpp` | logs pad state changes |
| `vendor/dolphin/.../HW/GCPad.cpp` | logs ini path, load result, resolved device |
| `vendor/dolphin/.../ControllerInterface.cpp` | logs each device added |
| `vendor/dolphin/.../DInput/DInputKeyboardMouse.cpp` | logs raw keyboard state |
| `vendor/dolphin/.../SDL/SDLGamepad.cpp` | (none) |

The logging patches are diagnostic only; they add no behaviour changes.

Toolchain decision: **MSVC for the runtime, Clang for the generated game
module.** A GNU-style Clang build of the vendored Dolphin tree fails in
`Externals/libusb` (`redefinition of 'timespec'` against the Windows 10 SDK
UCRT). Clang is still the right compiler for the generated C, per the guide
(27.8 -> 46.8 fps over MSVC in the SpongeBob case).

Known version drift vs the guide: this ModernGekko has **no `--core jit|static`
flag** on the runner. Core selection is `--module <dll>` / `STATICRECOMP_MODULE`
/ `build/modules/<ID>/active-module.txt`.

## Launcher parity audit (guide chapter 15)

Launcher: ModernGekko shell (`moderngekko_launcher.cpp`), theme `WWE WrestleMania
XIX`, audited 2026-11-13 against `docs/15-launcher-parity.md`.

| Area | Requirement | Status |
|---|---|---|
| Setup | import disc | pass - Browse for ISO/WBFS/RVZ |
| Setup | verify ID / DOL | pass - `MODERNGEKKO_REQUIRED_DISC_ID` + DOL SHA-256 gate |
| Setup | verify Redump size/CRC | **exception** - only the manifest `game.dumps` entry carries it; the launcher checks ID + DOL, not CRC-32 |
| Setup | extract with progress | partial - status text only, no percentage |
| Setup | headless `--extract` | pass - `WMXIX.exe --extract <iso>`, verified 8 s from the release folder |
| Settings | resolution / scale | pass - 1x..12x |
| Settings | fullscreen / window | pass |
| Settings | core (JIT/static) | pass - added, drives the runner's `--core` |
| Settings | MSAA / SSAA / AF | **exception** - `config.ini` has no keys for them; runtime hardcodes Dolphin defaults |
| Settings | VSync | **exception** - no config key |
| Settings | audio backend / volume | **exception** - runtime picks Cubeb automatically, `--audio` only on the runner |
| Settings | widescreen | **exception** - not implemented for this title |
| Input | detect pad + write profile | pass - writes `SDL/0/<name>` into `config.ini` |
| Input | show the mapping | **exception** - replace-with-generated-profile only |
| States | list + load | pass - savestate dropdown on the game page |
| States | save / delete / reveal | **exception** - only reachable through the runner's automation protocol |
| Cards | create folder card, import `.gci`, reveal | **exception** - the runtime creates `GC/USA/Card A` on boot; no import UI |
| Host | create `Cache\Shaders` | pass - created on launcher start |
| Host | core affinity + High priority | **exception** - not set by the launcher |
| Host | verify DSP ROMs | n/a - HLE DSP, no ROMs required |
| Host | document per-app mute check | **exception** - not written into README |
| Diagnostics | open logs / copy tail / provenance | **exception** - `Logs/` and `StateSaves/` are created and the runner writes `ModernGekko.log`; no UI buttons yet |
| Close | wait for process | pass - `SDL_WaitProcess` |
| Close | kill tree after timeout, no modal on close | **exception** - waits indefinitely; no timeout kill |
| Updates | about / version / update check | **exception** - none |
| Theme | art and strings are data, not code | pass - `assets/theme.ini` (product, window title, accent, art paths) |

Paths agree between the two surfaces (rule 4): user dir `%LOCALAPPDATA%\WMXIX`,
config `%LOCALAPPDATA%\WMXIX\config.ini`, module beside the runner, game at
`{install}\Game`. The manifest `start` args were corrected from
`{local}/WMXIX/games/Game` to `{install}/Game` to match where the launcher
actually extracts.

Recorded exceptions above are the open work for full parity. The two the
chapter marks as non-optional are handled: shader cache directory (pass) and,
for close, the wait is in place but the timeout-kill is not.



## Native RVZ support

Dolphin `.rvz` images are first-class input; there is no conversion step.

- The launcher's `--extract` and its Browse dialog (`iso;wbfs;rvz`) go through
  Dolphin DiscIO, which reads the RVZ container itself.
- `tools\extract-disc.ps1` detects `RVZ\x01` by magic and, for the dev
  pipeline, reconstructs the ISO with `tools\rvz_extract.py`, then writes
  `sys/` + `files/`.

Acceptance (same disc, both containers, project extractor):

| Path | Entries | Tree aggregate |
|---|---|---|
| launcher `--extract` on `.iso` | 4227 | `3fc07252dc1232f8ca0268e5882099886604d49be96c49289d94dd2345531350` |
| launcher `--extract` on `.rvz` | 4227 | `3fc07252dc1232f8ca0268e5882099886604d49be96c49289d94dd2345531350` |

0 files only in one side, 0 content differences. `sys/` also matches:
`main.dol` `627b8997…9fb7`, `fst.bin` `27688b0f…2301`, `apploader.img`
`5a45b70e…ad98b`, `boot.bin` `feaf9324…08c7`, `bi2.bin` `4c2ae33f…6b6a`.

`tools\rvz_extract.py` rebuilds the ISO byte for byte:
`B84472A45F66C2EA968F18A4FEC7B9ABF44B0F1C6FD834E8727332F054E8FCB0` for both
the original `.iso` and the RVZ-derived one.

Known nuance: the dev pipeline (`gcdisc.py`) decodes two developer-leftover
Shift-JIS PSD names with one replacement character where DiscIO decodes `・`.
Contents are identical (content multiset equal); only those two file names
differ. The launcher path has no such difference.

## Controller support

8BitDo (and any vendor that ships several layouts under one vendor id) is
resolved from the **live SDL mapping**, not the product name:

- `DetectControllerMapping(guid)` calls `SDL_GetGamepadMappingForGUID` and parses
  `a:`/`b:` (Nintendo order = a > b) plus `dpleft:`/`dpright:` (hat bits 2 vs 8
  reversed).
- Callers pass the resolved layout and `dpad_swap` into
  `GenerateControllerConfig`.
- Migration: `ControllerConfigNeedsMigration` rewrites an auto-generated profile
  only when detection now says Nintendo and the stored body disagrees. Custom or
  manually forced profiles are preserved.

Offline results (`launcher.exe --pad-info`, `--pad-guid`, `--mapping`,
`--check-migration`):

| Case | Result |
|---|---|
| Pro 2 Nintendo `0300…11010000`, `…00020000`, `…00000000` | mapping=nintendo → Nintendo |
| Pro 2 BT `0500…00010000` (driver mapping fed) | mapping=nintendo → Nintendo |
| Pro 2 Switch-mode `0500…fd216d04` (driver mapping fed) | mapping=nintendo → Nintendo |
| Ultimate `0300…1330000011010000` | mapping=positional → Generic (standard) |
| 64 `0300…1930000000000000` | mapping=positional → Generic |
| synthetic reversed D-pad | dpad=swapped |
| generated generic profile + Nintendo detection | `migrate=yes` |
| generated Nintendo profile + Nintendo detection | `migrate=no` |
| custom profile (extra line) + Nintendo detection | `generated=no migrate=no` |
| DualSense / Xbox / Switch Pro | unchanged (PlayStation / Xbox / Nintendo) |

Generated bodies: Pro 2 → `Buttons/A = Button B`; Ultimate → `Button A`.

Profiles are created by **both** programs, because RecompLauncher starts
`game.exe` directly and never runs `launcher.exe`:

- `launcher.exe` writes `GCPadNew.ini` when a pad is chosen (Controller page or
  PLAY), with a Button layout override.
- `game.exe` calls `EnsureControllerProfile()` at startup: if
  `Config\GCPadNew.ini` is missing it enumerates SDL gamepads, writes the first
  one as `SDL/<index>/<name>`, and `Pad::Initialize` picks it up.

Verified from a clean packaged install: `game.exe --user-dir <empty>` created
`Device = SDL/0/Xbox One Controller`, and the runtime reported
`pad0 default device='SDL/0/Xbox One Controller'` with `connected=1`.

`GenerateControllerConfig` is layout-aware. Detection is **GUID-level**: the SDL
GUID carries USB vendor/product at bytes 4-5 and 8-9, so special editions are
identified by hardware ID rather than product name.

| Pad | VID:PID | Layout | SDL evidence |
|---|---|---|---|
| DualSense | 054C:0CE6 | PlayStation | `controller_list.h` PS5Controller |
| DualSense Edge | 054C:0DF2 | PlayStation | `usb_ids.h` `USB_PRODUCT_SONY_DS5_EDGE`; `controller_list.h` PS5Controller |
| Xbox Elite S1 | 045E:02E3 | Xbox | `usb_ids.h` `..._ELITE_SERIES_1`; `controller_list.h` |
| Xbox Elite S2 | 045E:0B00 | Xbox | `usb_ids.h` `..._ELITE_SERIES_2`; `controller_list.h` |
| Xbox Elite S2 BT | 045E:0B05 | Xbox | `usb_ids.h` `..._ELITE_SERIES_2_BLUETOOTH`; `controller_list.h` |
| Xbox Series | 045E:0B12 | Xbox | `controller_list.h` XBoxOneController |
| Switch Pro | 057E:2009 | Nintendo | `controller_list.h` SwitchPro |

Offline test (`launcher.exe --pad-info <guid>`), standard-equivalence by
comparing the generated profile body without the `Device` line:

```text
Edge body == DualSense body : True
Elite S1 body == Xbox body  : True
Elite S2 body == Xbox body  : True
Elite S2 BT body == Xbox    : True
Switch Pro -> Buttons/A = `Button B` (Nintendo swap still correct)
unknown VID -> Generic
```

Paddles and extra buttons (DualSense Edge paddles/Fn, Elite P1-P4) are
deliberately unmapped; documented in PLAYERS.md.

Startup diagnostic, printed to stderr on every run:

```text
[input] pad0 name="..." guid=<32 hex> layout=<Xbox|PlayStation|Nintendo|Generic> buttons=<normal|swapped> dpad=normal
```

Offline hardware-free test hook: `MODERNGEKKO_TEST_PAD="PID:VID:Name"` attaches
an SDL virtual gamepad with that USB id, which exercises the real GUID path.
Verified that way for 0DF2, 02E3, 0B00, 0B05 and 0CE6; each printed the expected
layout and generated the same button body as its standard model.

Player confirmation still needed: on real Edge/Elite hardware, check that
`layout=PlayStation` / `layout=Xbox` appears with the matching name and that
A/B/X/Y, L/R, Z and sticks behave like the standard pad. Send that line.

Name-based detection now only runs when a GUID has no vendor/product (virtual
or DirectInput pads) and is labelled as a fallback.

`GenerateControllerConfig` is layout-aware. SDL normalises pads positionally, so
Xbox, PlayStation, Steam Deck, 8BitDo and generic DirectInput pads all use the
same body; Nintendo pads (Switch Pro, Joy-Con) get A/B and X/Y swapped so the
printed labels match.

```text
ControllerLayout = Auto | Xbox | PlayStation | Nintendo | Generic
DetectControllerLayout()  name heuristics, e.g. "switch" -> Nintendo
```

The launcher's Controller page shows **Detected: <family> (auto)** and a
**Button layout** dropdown to override it. Headless equivalents:

```powershell
launcher.exe --user-dir <dir> --write-pad-profile "SDL/0/DualSense Wireless Controller"
launcher.exe --user-dir <dir> --write-pad-profile "<device>" --pad-layout nintendo
```

Verified detection matrix (Buttons/A written):

| Device string | Detected | Buttons/A |
|---|---|---|
| `SDL/0/DualSense Wireless Controller` | PlayStation | `Button A` |
| `SDL/0/Xbox Series X Controller` | Xbox | `Button A` |
| `SDL/0/8BitDo Pro 2` | Generic | `Button A` |
| `SDL/0/Steam Virtual Gamepad` | Generic | `Button A` |
| `SDL/0/Nintendo Switch Pro Controller` | Nintendo | `Button B` |

14 profiles ship in `defaults/`: xbox, xbox-series, xbox-360, dualsense,
dualsense-menu, dualshock4, dualshock3, switch-pro, joycon, steam-deck, 8bitdo,
generic, dinput, keyboard.

## Launcher shell

The launcher is the current shared shell (`moderngekko_launcher.cpp`, taken from
the WWE WMX8 port and re-themed), not the older flat settings form:

- left rail: PLAY / GRAPHICS / PERFORMANCE / AUDIO / CONTROLLER
- Game card + Launch card, status chip (`GW9E78 | READY` / `NO GAME IMPORTED`)
- dominant accent PLAY button, netplay buttons, state folder
- diagnostics (open logs, copy log tail), About/version
- `--extract <iso>` for headless setup, `--core static|jit` on the runner
- theme from `theme.ini` (product, subtitle, disc_id, version, accent, backdrop)

Two executables only: `launcher.exe` and `game.exe`. `game.exe` with no
arguments boots `game_data/` beside itself; setup writes `default-game.txt`.

Art (SteamGridDB, game id 5262281):

| File | Source | Use |
|---|---|---|
| `backdrop.bmp` | hero 3840x1240, centre-cropped | launcher background |
| `logo.bmp` | logo 631x293 | header wordmark |
| `icon.bmp` | icon 1024x1024 | window icon |
| `tools/icon.ico` | icon 1024, 6 sizes | embedded in both exes via .rc |

`tools\fetch-art.ps1` documents the API flow;
`tools\make-art-from-sgdb.ps1` performs the PNG -> BMP/ICO conversion.

```text
dist/WMXIX-v0.3.0-Windows-x64/       110.2 MB
  launcher.exe                       launcher: setup, settings, PLAY
  game.exe                           the game
  gGW9E78_recomp.dll                 PGO module, beside game.exe
  game_data/                         created by setup from the player's ISO
  Sys/                               5.6 MB Dolphin data
  defaults/                          controller profiles + config.play.ini
  backdrop.bmp, logo.bmp, icon.bmp   SteamGridDB art
  theme.ini                          product/subtitle/disc_id/version/accent
  recomplauncher.json                validates, schema 0 errors
  README.txt, PLAYERS.md, LICENSE
dist/WMXIX-v0.3.0-Windows-x64.zip    SHA-256 A3989390...83A4
```

Exactly two executables, no .cmd wrappers. The launcher is the front door:

- `Browse for ISO / WBFS / RVZ` -> extracts beside itself to `game_data/` and
  writes `default-game.txt`
- then shows `GW9E78 | READY` and the PLAY button
- PLAY spawns `game.exe --game <dir>\game_data --user-dir %LOCALAPPDATA%\WMXIX`
  and hides itself until the game exits
- `game.exe` finds `gGW9E78_recomp.dll` beside itself, so no `--module` needed

Settings exposed in the launcher: graphics backend, fullscreen, internal
resolution, FPS in title, controller profile, CPU core, netplay.

Verified in the packaged folder: `launcher.exe --extract <iso>` produced
`game_data/{sys,files}` + `default-game.txt` in 9 s, `game.exe` with no
arguments booted from it and ran at 59.9 FPS, and the launcher rendered the
SteamGridDB backdrop, wordmark and embedded icon.

Known rough edge: the launcher hashes the whole `files/` tree at startup, so a
ready install shows a black window for ~20 s before the UI appears.

### Launcher theming

`assets/launcher-bg.bmp` (1920x1080), `assets/launcher-logo.bmp`, and
`assets/icon.bmp` are loaded by the launcher via `SDL_LoadBMP` and drawn with
ImGui's background draw list; the window icon is set with `SDL_SetWindowIcon`.
Colours in `ApplyTitleTheme()` use the game's steel-blue with the WM XIX red
accent.

`tools\make-art.ps1` regenerates the current placeholder art with GDI+.
`tools\fetch-art.ps1` pulls real hero/logo/icon art from SteamGridDB and
converts it to the same BMPs - it needs an API key
(`$env:STEAMGRIDDB_API_KEY`, from steamgriddb.com/profile/preferences/api).
SteamGridDB's API returns 401 without one, so the shipped art is generated
rather than scraped.



## Open issues

### Runtime patch: non-ASCII file names abort the process (fixed)

`ModernGekko/src/runtime/game.cpp`, `HashDirectorySha256`:

- The comparator called `std::filesystem::relative(...).generic_string()`.
  `generic_string()` converts a wide path to the ANSI codepage and **throws**
  when a name cannot be represented.
- `path.generic_string()` in the manifest loop had the same problem.
- The exception escaped `InspectGame`, `std::terminate` called `abort()`, and
  the process died with `0xC0000409` (`STATUS_STACK_BUFFER_OVERRUN`, i.e.
  `__fastfail`). `moderngekko-port inspect` crashed on this disc, and the runner
  would have crashed on load the same way.

WrestleMania XIX ships two developer-leftover PSDs with Shift-JIS names:

```text
files/edit_data/MODEL/Woman/Face/tq0_417/c3_c_00<sjis>[...]_wo.psd
files/edit_data/MODEL/Woman/Face/tq0_417/c3_c_00<sjis>[...]_wo1.psd
```

Fix: sort with `lexically_relative()` (pure lexical, no encoding conversion) and
build the manifest name with `generic_u8string()`. Byte-identical for ASCII
trees, so existing asset hashes are unaffected.

Verification: with the two PSDs quarantined, `inspect` passed before the fix and
crashed after restoring them; after the patch, `inspect` passes with the full
4,222-file tree restored. This is the first entry for the upstream fix list.

## Rules for this project

- Never commit/publish game data (ISO/RVZ/DOL/extracted files).
- Never hand-edit generated C; fix the emitter or runtime, then regenerate.
- Do not clean build trees without asking.
- A fix is not proven without a real run and a log.
- 59.94 Hz is full speed; do not expose uncapping.
- Ask before commit/tag/release.

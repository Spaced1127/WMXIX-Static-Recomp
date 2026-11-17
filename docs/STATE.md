# WWE WrestleMania XIX (GameCube) - Static Recomp State

Living state file. Read this first in any new session.

## Current session constraints

- **Test pause (hub directive, 2026-11-16, active):** the user is on the
  machine. Do NOT launch any GUI or game executable - no `launcher.exe`, no
  `game.exe`, no runners, no windows, no audio. Host-side work only: code,
  analysis, builds (no GUI), docs, file-level verification. A previous
  directive lifted the hidden-desktop rule (tests, when allowed again, run as
  ordinary visible windows; nothing hidden, moved or killed).
- Blocked while paused: boot/fps smoke, save -> load in-game, controller matrix
  runs (`tools\test-pad-layouts.ps1` starts `launcher.exe`), any memcard save
  test. See "Next actions" for what each is waiting on.

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
| Release v0.4.1 | published | tag `v0.4.1`, commit `727eaeb`, zip sha256 `609CF45EAED2963A831F91CC8B9FEDBFB1F33C9FB5168F033E24901E8B26D975` |

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
| Memory card | v0.4.1+: raw `GC/MemoryCardA.USA.raw` (16 MB) with a `GW9E` system save; pre-v0.4.1 installs used the `GC/USA/Card A` GCI folder |

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

Startup diagnostic, printed to stderr on every run (one line, v0.4.1+):

```text
[input] pad0 name="..." guid=<32 hex> layout=<Xbox|PlayStation|Nintendo|Generic> buttons=<normal|swapped> dpad=<normal|swapped> mapping=<live|none> source=<mapping-nintendo|mapping-positional|guid> device="SDL/<id>/<name>"
```

Offline layout matrix, no hardware needed:

```powershell
powershell -File tools\test-pad-layouts.ps1
```

18 cases: Xbox 360 (plain + XInput GUID), Xbox One, Series 0B12/0B22, Elite S1,
Elite S2 USB, Elite S2 BT, Xbox name-only fallback, DualSense, DualSense Edge
USB/BT, 8BitDo Pro 2 Nintendo mode, Pro 2 XInput mode, Ultimate, 64, Switch Pro,
synthetic reversed D-pad. Each asserts layout, D-pad and the generated
`Buttons/A`. Result after the v0.4.1 fix: **18/18 PASS**.

Resolved per pad: layout and D-pad come from each pad's own GUID and live SDL
mapping inside `GenerateControllerConfig`, so a Nintendo pad on port 1 cannot
swap an Xbox pad on port 2. An explicit layout (launcher dropdown) still wins.

Offline hardware-free test hook: `MODERNGEKKO_TEST_PAD="PID:VID:Name"` attaches
an SDL virtual gamepad with that USB id. It exercises the GUID -> vendor path
only: SDL builds virtual pads with the `v` driver tag and no gamepad mapping, so
`mapping=none` and the a>b / D-pad rules are *not* covered by it. Use
`tools\test-pad-layouts.ps1` (which feeds real driver mapping strings through
`--pad-info --mapping`) for the mapping path, and the hook only for the vendor
table (0DF2, 02E3, 0B00, 0B05, 0CE6, 0B12).

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



## Release v0.4.1 (published 2026-11-16)

| Field | Value |
|---|---|
| Tag / commit | `v0.4.1` / `727eaeb` |
| Release | https://github.com/Spaced1127/WMXIX-Static-Recomp/releases/tag/v0.4.1 |
| Asset | `WMXIX-v0.4.1-Windows-x64.zip` + `SHA256SUMS.txt` |
| SHA-256 | `609CF45EAED2963A831F91CC8B9FEDBFB1F33C9FB5168F033E24901E8B26D975` |
| Contents | 2668 entries, 0 game-data files, 110.3 MB unpacked |
| Boot smoke | extracted artifact: `booted=1`, `speed=1`, 59.9 fps, clean stop |
| Provenance | `game.exe`, `launcher.exe`, `gGW9E78_recomp.dll` and the shipped docs are byte-identical to the build tree and `docs/release` at the tag (hash-compared without launching) |
| Asset refresh | rebuilt from the final tree (`de029f2`, docs-only after the tag) and re-uploaded with `--clobber`; downloaded back and hash-matched. No new tag/version: no shipped file changed between `727eaeb` and `de029f2`. |
| Smoke (visible window) | `fps=59.9425`, `vps=59.94`, `speed=1`, 1042->1951 frames in 15 s (60.6), clean stop, 16 MB raw card created. Headless first-run occasionally reports 0 frames (stalled before the first presented frame); retry or use a window. |
| Notes fix | the published body initially had a mojibake em dash from a non-ASCII byte; `gh release edit` replaced it and the body now matches `docs/release/release-notes-v0.4.1.md` exactly. The notes file is not inside the zip, so the artifact is unaffected. |

## Release v0.4.3 (published 2026-11-16)

| Field | Value |
|---|---|
| Tag / commit | `v0.4.3` |
| Release | https://github.com/Spaced1127/WMXIX-Static-Recomp/releases/tag/v0.4.3 |
| Asset | `WMXIX-v0.4.3-Windows-x64.zip` + `SHA256SUMS.txt` |
| SHA-256 | `714CAD7BECDE2204A9F38F03D0DCCED2778E6EB650E6D975C06B7B0CB0A29A0C` |
| Contents | 2668 entries, 0 game-data files, 110.3 MB unpacked |
| Smoke (visible window) | `fps=59.9396`, `speed=1`, 73->800 frames in 12 s (60.6), clean stop, raw card created |
| Fix | 8BitDo HID products resolve by product id when SDL has no live mapping (SDL's Windows DB has no 8BitDo Bluetooth rows); unmapped joysticks are named in the startup log. Matrix now 22/22. |

## Release v0.4.2 (published 2026-11-16)

| Field | Value |
|---|---|
| Tag / commit | `v0.4.2` / `0613b44` |
| Release | https://github.com/Spaced1127/WMXIX-Static-Recomp/releases/tag/v0.4.2 |
| Asset | `WMXIX-v0.4.2-Windows-x64.zip` + `SHA256SUMS.txt` |
| SHA-256 | `3C93111C49293FF4A958F77F2D8F4ED010A045A0F003B98ABF5E0873722FFAF4` |
| Contents | 2668 entries, 0 game-data files, 110.3 MB unpacked |
| Smoke (visible window) | `fps=59.9463`, `vps=59.9405`, `speed=1.00189`, clean stop, raw card created |
| Fix | ImGui context is created at process start (launcher) and before `Runtime::Create` (game.exe); `OnScreenUI::Initialize` adopts an existing context. Removes the "No current context" `GetIO` abort. |
| Provenance | binaries and shipped docs hash-match the build tree and `docs/release` at the tag |

## Open issues

### 8BitDo over Bluetooth: A/B swapped / pad not seen (fixed in v0.4.3)

Player report (v0.4.0): "I am using an 8bitdo pro controller over bluetooth and
it isn't being recognized." Older report (v0.3.2): "8 bitdo controls are
backwards (A and B and also left and right?) dualedge doesn't read at all."

Root cause found offline: SDL's **Windows** controller database has no 8BitDo
Bluetooth rows. The `05000000c82d00000660000000010000` row ("8BitDo Pro 2",
`a:b1,b:b0`) lives inside the `SDL_JOYSTICK_LINUX` block
(`vendor/.../SDL/src/joystick/SDL_gamepad_db.h`). On Windows a Bluetooth Pro 2
only gets a mapping from SDL's HIDAPI driver at open time; without it,
`SDL_GetGamepadMappingForGUID` returns NULL, layout fell back to vendor 0x2DC8
(not in the table) -> Generic -> standard positional body -> A/B and X/Y swapped
against the labels. If SDL also did not classify the device as a gamepad, the
enumeration skipped it entirely and no profile was written at all.

Fix: `DetectControllerLayout` resolves 8BitDo's own ids by product, matching
SDL's HIDAPI driver: Nintendo order for SF30 Pro 0x6000/0x6100, SN30 Pro
0x6001/0x6101, Pro 2 0x6003/0x6006, Pro 3 0x6009; standard order for the rest of
0x2DC8 (Ultimate 0x6012, 64). A live mapping still takes precedence, so USB and
XInput modes are unchanged, and existing generic profiles migrate because
detection now reports Nintendo. Unmapped joysticks are now named in the startup
log (`[input] joystick without a gamepad mapping: ...`).

DualSense Edge re-verified end to end: 054C:0DF2 -> PlayStation on USB
(`030000004c050000f20d000000007801`) and Bluetooth
(`050000004c050000f20d000000000000`), `dpad=normal`. The v0.3.2 "Edge doesn't
read at all" predates Edge support (v0.4.0).

Not verified on hardware: no 8BitDo or Edge on this host. The matrix
(`tools\test-pad-layouts.ps1`, 22 cases) uses the real GUIDs plus SDL's driver
mapping strings.

### v0.4.1: ImGui "No current context" abort at startup (fixed in v0.4.2)

Reported by the user as a ModernGekko error dialog at launch:

```text
Condition: GImGui != 0 && "No current context. Did you call
           ImGui::CreateContext() and ImGui::SetCurrentContext()?"
File: ...\imgui.cpp  Line: 4985  Function: GetIO
Ignore and continue?
```

The ImGui context was created in one place only, `OnScreenUI::Initialize`
(VideoCommon), which runs when the renderer initialises - after the core has
started. Any UI surface reached before that (OSD message queue, statistics,
debug text) called `ImGui::GetIO()` with no context and tripped Dolphin's
assert handler.

v0.4.1 put more work before the renderer: controller detection and profile
migration on every start, the memory-card slot migration, and the `GC/` tree
creation (and v0.4.0's SDL teardown preceded all of it).

Fix: `game.exe` creates the context before `Runtime::Create`;
`launcher.exe` creates it at the top of `main`; `OnScreenUI::Initialize` only
creates one when none exists, so the renderer still configures fonts, style and
the vertex format. Both paths are idempotent.

Not reproducible on this host with v0.4.1 or v0.4.2 (windowed, fullscreen, the
user's config, an Xbox pad attached): the fix removes the precondition rather
than a single call site. If it recurs, the dialog title and the exact
File/Line/Function plus `Logs\ModernGekko.log` are needed.

Note: the user's own install at `D:\Games\Recomps\wmxix-static-recomp` was still
v0.4.0 (`game.exe` hash `008AD4D3...59C8`), and that build produced three
`0xC0000005` dumps at 00:14/00:24/00:56 reading address 0x10 at
`game.exe+0x6B042` - a null map dereference in runtime startup. The ImGui
dialog is a different failure; both point at startup ordering.

### v0.4.1: memory card hung on "checking memory card in slot A" (fixed, pending release)

Shared pattern from the Aggressive Inline project
(`docs/notes/12-memcard-shared-pattern.md` there), same ModernGekko/Dolphin
runtime family. Three causes:

1. `Core/SlotA` was never written, so Dolphin's default `MemoryCardFolder` (8)
   was used with an empty `GC/<region>/Card A`; the game's card probe never
   completed and the save screen hung.
2. `Runtime::Create` called `UICommon::SetUserDirectory` + `UICommon::Init` but
   not `UICommon::CreateDirectories`, so `GC/` did not exist before
   `ExpansionInterface::Init` resolved `GC/MemoryCardA.<region>.raw`.
3. `SlotB = 0` is Dolphin's `Dummy` device ("THE DEVICE IN SLOT B IS NOT
   SUPPORTED"); the empty slot is `None` = 255.

Fix: `SlotA = 1` / `SlotB = 255` forced by `EnsureMemoryCardSlotSettings` in
`frontend_config.cpp` (called by both `launcher.exe` and `game.exe`),
`UICommon::CreateDirectories()` plus `Config::SetBase(MAIN_SLOT_A/B)` in
`dolphin_runtime.cpp`, and the same keys in the RecompLauncher manifest
(`ensure` / `always` / `new`).

Evidence, fresh user dir with no `GC/`, headless, clean automation `stop`:

| Point | Value |
|---|---|
| before | `GC/` absent |
| after | `GC/EUR`, `GC/JAP`, `GC/USA`, `MemoryCardA.USA.raw`, `SRAM.raw` |
| `Dolphin.ini` | `SlotA = 1`, `SlotB = 255` |
| card size | 16,777,216 bytes |
| card SHA-256 (empty formatted) | `EA5170CFB8F4BA0B84978330CF0D1C678DFCFB7FB5AAA5474B71D528A2D8A2C5` |
| second boot | same SHA (no rewrite) |
| legacy install (`SlotB = 0`, no `SlotA`) | repaired to 1/255, same 16 MB card |

Save evidence (fresh card, then the game's own card write). Empty formatted card
SHA depends on the per-format header serial, so compare the same file only.
After reaching the title and pressing START/A the game wrote its system file:

```text
empty formatted card      16,777,216  EA5170CF...A2D8A2C5
after the game's save     16,777,216  1C2B0319F9EB88877D74393CE500FE0B2FD3AAC8B970E65B96EF27A0A21AC327
directory entry 0         gamecode GW9E  company 78  name /wmx9_sys
entries 1..2              empty (FF)
```

Load: the same card booted a second time to the title and exited cleanly with
sha256 still `1C2B0319...21AC327` - the game read the existing card and did not
reformat or rewrite it. Card-level load confirmed; a UI-level "LOADING <file>"
round trip was not observed (headless has no frame dumper, so menu navigation
cannot be steered by screenshots on this host).

Runtime note: with `--headless` the `fps` field stays 0 (no presenter), so speed
is read from `speed=` plus the frame delta: 1264 frames in 21 s = 60.2 fps, and
`speed=1.0` on a reload boot.

Quiet-mode rule changed by user directive (2026-11-16): test runs are launched as
normal visible windows. `H:\Orchestration\tools\run-hidden.ps1` is no longer
used, and test windows are not hidden, moved or killed.

Not verified yet: an in-game save writing directory entries and a save -> load
round trip. Reaching a save needs menu automation on a fresh card; the only
existing savestate (`work/states/user-match.state`) predates the fix and would
restore the folder device, which is the shared pattern's caveat. Also confirmed
for the record: a force-kill skips the card flush and leaves no `.raw` file -
use the automation `stop` command.

### v0.4.0: Xbox pads detected but bound nothing (fixed in v0.4.1, pending release)

Symptom from players: Xbox controllers "not working at all". PlayStation and
8BitDo pads were fine.

Root cause, not layout detection. v0.4.0 revived `EnsureDefaultControllerConfig`
in `tools/moderngekko_run.cpp`, which opened SDL with
`SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD)` and then called **`SDL_Quit()`**
before the runtime started (v0.3.x used `SDL_InitSubSystem(SDL_INIT_GAMEPAD)`
and never quit). Dolphin's SDL input backend then initialised the joystick
drivers itself, on its own worker thread, without video. HIDAPI devices
(DualSense, Edge, Switch Pro, 8BitDo) came up; the Windows
XInput/RAWINPUT/WGI paths that enumerate a standard Xbox pad did not.

Evidence, same command line, release v0.4.0 vs fixed build:

```text
# v0.4.0
[input] device: DInput/Keyboard Mouse
[input] pad0 default device='SDL/0/Xbox Series X Controller'
[input] pad0 connected=0

# fixed
[input] device: DInput/Keyboard Mouse
[input] device: SDL/Xbox Series X Controller
[input] pad0 default device='SDL/0/Xbox Series X Controller'
```

The Xbox layout itself was never wrong: 360 `030000005e0400008e02000000000000`,
One `02EA`, Series `0B12`/`0B22`, Elite `02E3`/`0B00`/`0B05` all resolve to
`layout=Xbox`, `dpad=normal`, standard body, byte-identical to v0.3.2.

Also fixed in the same change: pad-1 layout/dpad leaking to every pad, device
id counted differently from the runtime, `"Xbox Wireless Controller"` matching
the PlayStation name rule, migration skipped when `config.ini` named a pad, the
duplicated `[input]` line with a hard-coded `dpad=normal`, and a launcher
"Detected:" label that ignored the live mapping.

Open: physical confirmation from an Xbox 360, Xbox One/Series and an Elite S1/S2
owner; this machine has no Xbox hardware (DualSense/DS4 only), so the run above
used SDL's virtual pad with VID 045E, PID 0B12.

Next actions
------------
1. Hub approval, then `tools\make-release.ps1 -Version 0.4.1`, verify the zip
   back (SHA-256, no game data), commit, tag, publish.
2. Memory card: drive a save in a fresh-card session and record the directory
   entry + SHA after the save, then a load of that file. Do not use an old
   savestate (it restores the EXI device type). `tools\test-pad-layouts.ps1`
   covers the controller matrix; card tests need the automation `stop` command.
3. Ask for the new `[input] pad0 ...` line from an Elite S2 (BT) owner: the
   P1-P4 paddles stay unmapped by design; confirm A/B/X/Y, L/R, Z and sticks.
4. D-pad in the generated gameplay profile is still `Pad N & Shoulder L`
   (deliberate in v0.3.x, plain in the menu profile and in `generic.ini`).
   Left as-is; confirm with the hub whether the D-pad should be plain in-game
   too.

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

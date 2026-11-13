WWE WrestleMania XIX — static recompilation, first release
==========================================================

A native Windows port of the retail GameCube release (GW9E78), produced by
statically recompiling the game's PowerPC executable with DolRecomp and running
it on a Dolphin-derived runtime (ModernGekko).

This release contains NO game data. You must supply your own legally dumped
USA disc image.


Requirements
------------
- Windows 10/11 x64
- Vulkan-capable GPU (OpenGL works too)
- Your own WWE WrestleMania XIX (USA) ISO
  Redump size:   1,459,978,240 bytes
  Redump CRC-32: 635116c6

A .rvz will not work with setup. Convert it to .iso first.


Install
-------
1. Download and unzip anywhere.
2. Run launcher.exe.
3. Browse for your ISO. Setup extracts it into game_data\ and shows progress.
4. The launcher switches to READY. Press PLAY.

game.exe also runs on its own and reads game_data\ beside itself.


Controls
--------
The launcher detects your pad and generates the profile. Xbox, Xbox 360,
Xbox Series, DualSense, DualShock 4/3, Switch Pro, Joy-Con, Steam Deck, 8BitDo,
generic SDL and DirectInput pads are covered. Nintendo pads get A/B and X/Y
swapped so the labels match; the Controller page has a Button layout override.

Keyboard fallback: Space = A, Left Shift = B, Enter = Start, WASD = stick,
IJKL = C-stick, arrows = D-pad.


Performance
-----------
- Menus, entrances and normal matches: 59.94 Hz (full speed).
- Fatal 4-Way with four CPU wrestlers is the heaviest scene and runs around
  50 fps on the static core. Switch CPU core to JIT for a locked 60 there.
- The static module was tuned to 50.5 fps from a 38.8 fps stock build:
  loop budget 4096, call depth 128, -march=x86-64-v3, PGO trained on real
  gameplay, and the frame-limiter spin at 0x8027BA24 skipped.


Known issues
------------
- The launcher hashes the extracted files at startup, so a ready install shows
  a black window for ~20 s before the UI appears.
- Launcher parity with the guide's chapter 15 is partial: MSAA/SSAA/AF/VSync/
  volume are not exposed, there is no memory-card import UI, and closing the
  launcher does not kill a stuck game after a timeout.
- The static core is CPU-bound; the remaining gap in a four-wrestler match is
  the scalar paired-single emulation in the runtime.


Verification
------------
- Disc ID GW9E78, retail DOL SHA-256
  627b899760d0b820c049ad29f96a613da1c43d35dd4a1456e581cc620bae9fb7
- Runtime log shows fallback=0, smc_failed=0
- RecompLauncher manifest validates with 0 schema errors


Licence
-------
Project code GPL-3.0. DolRecomp GPL-3.0; ModernGekko and Dolphin
GPL-2.0-or-later (aggregate GPL-3.0). Launcher art from SteamGridDB, used with
permission. WWE and all related marks are trademarks of their respective
owners. Unofficial fan project, no affiliation.

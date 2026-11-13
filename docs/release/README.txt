WWE WrestleMania XIX - static recompilation for Windows
=======================================================

A native Windows port of the retail GameCube release (GW9E78), produced by
statically recompiling the game's PowerPC executable with DolRecomp and running
it on a Dolphin-derived runtime.

This package contains NO game data. You must supply your own legally dumped
disc image.

Two programs, nothing else:

  launcher.exe   setup, settings, and PLAY
  game.exe       the game


Requirements
------------
- Windows 10/11 x64
- A Vulkan-capable GPU (OpenGL also works)
- Your own WWE WrestleMania XIX (USA) disc image, .iso
  Redump USA dump: 1,459,978,240 bytes, CRC-32 635116c6

A compressed .rvz is not accepted by setup. Convert it first:
  DolphinTool convert -i game.rvz -o game.iso -f iso


First run
---------
Double-click launcher.exe.

1. Browse for your ISO.
2. Setup extracts it into game_data\ next to the executables and shows
   progress.
3. The launcher shows Ready.
4. Click PLAY.

Manual setup, if you prefer a console:

  launcher.exe --extract "D:\dumps\WWE WrestleMania XIX (USA).iso"

That writes game_data\ and default-game.txt. Then either open launcher.exe, or
run:

  game.exe

game.exe with no arguments reads game_data\ beside itself.


Settings
--------
Everything is in launcher.exe:

- Graphics backend (Vulkan / OpenGL)
- Start in fullscreen
- Internal resolution, 1x (640x528) up to 12x
- Show FPS in window title
- CPU core (static recompilation or Dolphin JIT)
- Controller profile
- Netplay

Settings are saved to %LOCALAPPDATA%\WMXIX\config.ini.


Controls, saves, performance
----------------------------
See PLAYERS.md.


Data folders
------------
- Memory card: %LOCALAPPDATA%\WMXIX\GC
- Savestates:  %LOCALAPPDATA%\WMXIX\StateSaves
- Logs:        %LOCALAPPDATA%\WMXIX\Logs
- Settings:    %LOCALAPPDATA%\WMXIX\config.ini

When installed through RecompLauncher, its local app folder is used instead of
%LOCALAPPDATA%.


Troubleshooting
---------------
- "No extracted game is configured yet": run setup, or pass --extract.
- The disc does not validate: it must be the USA retail disc. Check the size
  and CRC-32 above.
- Black screen at boot: make sure your GPU driver supports Vulkan.
- Buttons do nothing: the pad profile is missing. Open the launcher, pick a
  controller, save.
- Window will not close: see Logs\ModernGekko.log.


License
-------
Project code: GPL-3.0.
DolRecomp: GPL-3.0. ModernGekko / Dolphin: GPL-2.0-or-later (aggregate
GPL-3.0).
WWE and all related marks are trademarks of their respective owners. This is an
unofficial fan project with no affiliation.

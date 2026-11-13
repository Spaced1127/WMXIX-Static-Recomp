# Players guide

## First run

1. Open `launcher.exe`.
2. Click **Browse for ISO / WBFS / RVZ** and pick your own USA dump of
   WWE WrestleMania XIX (the game id is `GW9E78`).
3. Setup extracts the disc into `game_data/` next to the executables. It takes
   a minute or two and shows progress.
4. The launcher switches to **Ready** and the big **PLAY** button becomes
   active.
5. Click **PLAY**. The launcher starts `game.exe` and gets out of the way.

After that, `launcher.exe` opens straight to Ready. `game.exe` also works on
its own: with no arguments it reads `game_data/` beside itself.

The intro movie plays before the title screen and takes about a minute. That is
normal, not a hang.

## Default controls

The launcher detects your pad, works out its button family, and writes
`GCPadNew.ini` for it. Xbox, PlayStation, Nintendo, Steam Deck, 8BitDo and
generic DirectInput pads are all covered, and the **Button layout** dropdown on
the Controller page lets you override what it guessed.

Nintendo pads (Switch Pro, Joy-Con) get A/B and X/Y swapped so the physical
labels match the GameCube buttons; everything else uses the standard positional
mapping, where Cross/A is GameCube A.

The standard mapping:

| GameCube | Xbox | PlayStation | Keyboard |
| --- | --- | --- | --- |
| A | A | Cross | Space |
| B | B | Circle | Left Shift |
| X | X | Square | E |
| Y | Y | Triangle | Q |
| Z | Right bumper | R1 | R |
| Start | Menu | Options | Enter |
| D-pad | D-pad | D-pad | Arrow keys |
| Control stick | Left stick | Left stick | W A S D |
| C-stick | Right stick | Right stick | I J K L |
| L | Left trigger | L2 | 1 |
| R | Right trigger | R2 | 2 |

Bindings live in `<user folder>\Config\GCPadNew.ini`. If your pad is not
detected, open `launcher.exe`, pick it under **Controller**, and save.

## Menus

The game's menus read the **main stick** and A/B. If a menu ignores the D-pad,
use the left stick.

## Saving

The port uses a folder memory card, not a card image:

```
<user folder>\GC\USA\Card A\*.gci
```

You can copy `.gci` files from Dolphin into that folder. Savestates live under
`<user folder>\StateSaves\`.

The user folder is `%LOCALAPPDATA%\WMXIX` for a manual install, or the
RecompLauncher local folder when installed through RecompLauncher.

## Performance

The GameCube VI runs at 59.94 Hz. A title-bar reading of 59.9 is full speed.
There is no uncapped mode.

The default core is the **static recompilation** - the native build this port
is made of. It holds 59.94 in menus, entrances and normal matches. A
four-wrestler Fatal 4-Way with CPU opponents is the heaviest scene in the game
and runs around 50 FPS on this core.

If you want that scene at a locked 60, switch **CPU core** to **JIT (Dolphin
core)**. JIT is Dolphin's emulator core rather than the static build, and it
has a lot of headroom, but it is not the point of the project.

Other things worth trying first:

1. Drop the internal resolution from 3x to 2x.
2. Close GPU-heavy applications (browsers with hardware acceleration, other
   games).
3. Make sure the GPU driver is current.

## Reporting a problem

Include:

- the last 60 lines of `<user folder>\Logs\ModernGekko.log`
- your GPU and driver version
- whether static or JIT was selected
- the scene and the on-screen frame rate

Never upload the game's files or a disc image with a report.

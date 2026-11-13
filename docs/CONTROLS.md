# Controls

ModernGekko has **no in-game controller menu** (same as Dolphin's NoGUI
frontend). GameCube pad bindings come from a Dolphin-format file:

```text
work/user/Config/GCPadNew.ini
```

With no file, every button is silent and the game sits on the title screen
forever. That is the single most common "the port has no controller support"
report, and it is not a game or recomp problem.

## Install bindings

```powershell
tools\set-controls.ps1            # detect a pad, else keyboard
tools\set-controls.ps1 -List      # show what the runtime sees
tools\set-controls.ps1 -Mode keyboard
tools\set-controls.ps1 -Mode gamepad
```

The script asks the running runtime for its actual device list
(`MODERNGEKKO_INPUT_DEBUG=1`), then writes a binding file using one of those
exact device strings. It backs up any existing file to `GCPadNew.ini.bak`.

`tools\run.ps1` / `Play.cmd` runs the same detection when no binding file
exists yet.

## Device string format

The runtime reports devices as `Source/Id/Name`:

```text
DInput/0/Keyboard Mouse
DInput/0/DualSense Wireless Controller
SDL/0/DualSense Wireless Controller
XInput/0/Gamepad
```

The `Device =` line must match one of those **exactly**. A wrong or stale
device string loads fine and silently binds nothing.

Prefer `SDL/...` when it is offered: SDL normalises button names, so the same
profile works for Xbox, DualSense, DualShock and Switch Pro pads. `XInput`
covers Xbox pads. Raw `DInput` gamepads expose `Button 0`-style names and need
a hand-written profile.

## Verified layout: DualSense (SDL backend)

Installed automatically when a DualSense is detected.

| GameCube | DualSense |
|---|---|
| A (action / select) | Cross (south) |
| B (back) | Circle (east) |
| X | Square (west) |
| Y | Triangle (north) |
| Z | R1 |
| L / R | L2 / R2 (analog) |
| Start | Options |
| Main stick | Left stick |
| C stick | Right stick |
| D-Pad | D-Pad |

SDL names used: `Button S`, `Button E`, `Button W`, `Button N`, `Start`,
`Shoulder R`, `Trigger L`, `Trigger R`, `Left X/Y`, `Right X/Y`,
`Pad N/S/W/E`. Dolphin also accepts the XInput aliases `Button A/B/X/Y` for the
same physical buttons.

## Keyboard fallback

`tools\set-controls.ps1 -Mode keyboard`

| GameCube | Keyboard |
|---|---|
| Main stick | `W` `A` `S` `D` |
| D-Pad | Arrow keys |
| A / B | `Space` / `Left Shift` |
| X / Y | `E` / `Q` |
| Z | `R` |
| L / R | `1` / `2` |
| Start | `Enter` |
| C stick | `I` `J` `K` `L` |

The game window must have focus for keyboard input.

DirectInput ignores injected keystrokes in a non-interactive session, so
`SendKeys`/`keybd_event` cannot be used to test keyboard bindings from an
automation harness. Verify by hand, or use the automation pad below.

## Two players

Add a `[GCPad2]` section with the same keys and `Device = SDL/1/<second pad>`.
Port 2 is `SIDEVICE_NONE` by default.

## Diagnosing silent input

```powershell
$env:MODERNGEKKO_INPUT_DEBUG = "1"
tools\run.ps1
```

Prints, on stderr:

```text
[input] device: SDL/0/DualSense Wireless Controller
[input] GCPadNew.ini loaded=1 path=...\work\user\Config\GCPadNew.ini
[input] pad0 default device='SDL/0/DualSense Wireless Controller'
[input] pad0 connected=1 buttons=0x0100 stick=128,128 ...
```

`loaded=0` means the file is missing or unreadable. `default device` shows what
the ini actually resolved to. `buttons` changes when the guest really sees a
press (bit `0x0100` is A, `0x0008` is Start).

## Automation input

For scripted tests, no real pad is needed:

```text
build/auto/commands/press.txt
  command=pad_frames
  port=1
  frames=6
  start=1
```

Fields: `a b x y z start dpad_up dpad_down dpad_left dpad_right l r l_analog
r_analog main_x main_y c_x c_y`, each `0..1` (sticks `-1..1`).

This path is verified: injecting `start=1` every 5 s drives the game from the
title screen into a match.

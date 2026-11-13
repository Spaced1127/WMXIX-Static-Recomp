# Controller profiles

These are Dolphin-format `GCPadNew.ini` profiles. The runtime reads
`<user-dir>\Config\GCPadNew.ini`. Copy one of these over that file.

| File | Controller | Device string |
|---|---|---|
| `GCPadNew.xbox.ini` | Xbox One / Series | `SDL/0/Xbox Wireless Controller` |
| `GCPadNew.xbox-series.ini` | Xbox Series X | `SDL/0/Xbox Series X Controller` |
| `GCPadNew.xbox-360.ini` | Xbox 360 | `SDL/0/Xbox 360 Controller` |
| `GCPadNew.dualsense.ini` | DualSense (PS5) | `SDL/0/DualSense Wireless Controller` |
| `GCPadNew.dualsense-menu.ini` | DualSense, D-pad = menus | `SDL/0/DualSense Wireless Controller` |
| `GCPadNew.dualshock4.ini` | DualShock 4 (PS4) | `SDL/0/Wireless Controller` |
| `GCPadNew.dualshock3.ini` | DualShock 3 (PS3) | `SDL/0/PS3 Controller` |
| `GCPadNew.switch-pro.ini` | Switch Pro | `SDL/0/Nintendo Switch Pro Controller` |
| `GCPadNew.joycon.ini` | Joy-Con (L) | `SDL/0/Joy-Con (L)` |
| `GCPadNew.steam-deck.ini` | Steam Deck | `SDL/0/Steam Virtual Gamepad` |
| `GCPadNew.8bitdo.ini` | 8BitDo Pro 2 | `SDL/0/8BitDo Pro 2` |
| `GCPadNew.generic.ini` | any SDL pad | `SDL/0/SDL Gamepad` |
| `GCPadNew.dinput.ini` | DirectInput pad | `DInput/0/USB Gamepad` |
| `GCPadNew.keyboard.ini` | Keyboard | `DInput/0/Keyboard Mouse` |

You usually do not need these: the launcher detects the pad, detects its
button family, and generates `GCPadNew.ini` for you. The files are here for
manual setups and for pads whose SDL name differs.

The **only** controller-specific line is `Device =`. If a profile does not
produce input, the SDL device name differs on your machine. Dolphin names SDL
pads `SDL/<index>/<name>`; the name is what the controller reports, for
example:

- `SDL/0/DualSense Wireless Controller`
- `SDL/0/Xbox Series X Controller`
- `SDL/0/Nintendo Switch Pro Controller`
- `SDL/0/Steam Virtual Gamepad`

To see what this runtime detects, open the launcher's **Controller** page.

## D-pad: menus vs taunts

WrestleMania XIX's menus read the **main stick**. In a match the D-pad is used
for taunts, so the two layouts exist as separate files:

- `GCPadNew.dualsense.ini` — D-pad is the D-pad (taunts in a match)
- `GCPadNew.dualsense-menu.ini` — D-pad also moves menu selection

Use the `-menu` variant if you prefer navigating with the D-pad.

## Keyboard

`GCPadNew.keyboard.ini` maps:

| GameCube | Key |
| --- | --- |
| A / B | Space / Left Shift |
| X / Y | E / Q |
| Z | R |
| L / R | 1 / 2 |
| Start | Enter |
| Main stick | W A S D |
| C-stick | I J K L |
| D-pad | Arrow keys |

## config.play.ini

A minimal `config.ini` for the runtime user folder: Vulkan, 3x internal
resolution, fullscreen, 60 Hz lock. Copy it to `<user-dir>\config.ini` if you
want to skip the launcher.

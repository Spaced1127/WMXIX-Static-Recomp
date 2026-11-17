WWE WrestleMania XIX - v0.4.3
============================

8BitDo over Bluetooth and DualSense Edge follow-up to the v0.4.1/v0.4.2
controller work. No rendering or memory-card changes.


8BitDo Pro 2 over Bluetooth showed the wrong A/B (and was sometimes not seen)
------------------------------------------------------------------------------
SDL's Windows controller database has no row for 8BitDo in Bluetooth mode: the
`05000000c82d00000660000000010000` ("8BitDo Pro 2") row that lists
`a:b1,b:b0` is compiled only for Linux. On Windows the pad therefore arrives
with no live mapping, and layout detection fell back to the vendor id 0x2DC8,
which was not in the table - so the profile was written in the standard
positional order and A/B (and X/Y) came out swapped against the printed labels.
If SDL also failed to classify the device as a gamepad, no profile was written
at all and the pad looked unrecognised.

Fix: 8BitDo's own HID ids are now resolved by product, matching SDL's own
HIDAPI driver:
  Nintendo order (a:b1,b:b0): SF30 Pro 0x6000/0x6100, SN30 Pro 0x6001/0x6101,
                              Pro 2 0x6003/0x6006, Pro 3 0x6009
  standard order:             everything else at 0x2DC8 (Ultimate, 64)
A live SDL mapping still wins when one exists, so USB mode and XInput mode are
unaffected. Existing auto-generated profiles migrate on the next start because
detection now reports Nintendo.

Diagnostics: a joystick that SDL gives no gamepad mapping to is now named in
the startup output, because a Bluetooth 8BitDo in the wrong mode lands there:

  [input] joystick without a gamepad mapping: name="..." guid=...
          (no profile written; put the pad in its XInput/Switch mode or enable
          SDL HIDAPI)

DualSense Edge
--------------
Re-verified end to end: 054C:0DF2 resolves to the PlayStation family on both
USB (`030000004c050000f20d000000007801`) and Bluetooth
(`050000004c050000f20d000000000000`), with the standard body and `dpad=normal`.
The earlier "Edge doesn't read at all" report was against v0.3.2, which had no
Edge handling; it has been supported since v0.4.0.


Offline matrix
--------------
`tools\test-pad-layouts.ps1` now covers 22 cases, all passing:

  Xbox 360 (plain/XInput), Xbox One, Series 0B12/0B22, Elite S1, Elite S2
  USB+BT, Xbox name-only, DualSense, DualSense Edge USB+BT, 8BitDo Pro 2
  (USB Nintendo mode, Bluetooth with and without a live mapping), Switch-mode
  Pro over Bluetooth, 8BitDo Pro 2 in Bluetooth XInput mode, 8BitDo Pro 2
  XInput mode, Ultimate, 64, Switch Pro, reversed D-pad.


Caveats
-------
- No physical 8BitDo or DualSense Edge on the build host: results above are
  offline (GUID + SDL driver mapping strings) plus one live DualSense. Players
  should confirm with the startup line:
  `[input] pad0 name=... guid=... layout=... buttons=... dpad=... mapping=... source=... device=...`
- If a Bluetooth 8BitDo still reports `controller: 0 SDL gamepad(s) detected`
  plus the "joystick without a gamepad mapping" line, the pad is in a mode SDL
  cannot map; pair it as a Switch Pro (Start+B) or in XInput mode (Start+X).
- The in-game LOAD round trip of a memory-card save remains unobserved;
  card-level write/read is proven.


Install
-------
Unzip over your install (keep `game_data/`). Auto-generated controller profiles
migrate on first run; hand-edited profiles are left alone.
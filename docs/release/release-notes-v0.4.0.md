WWE WrestleMania XIX — v0.4.0
=============================

Controller and disc-format release. Game rendering and performance are
unchanged from v0.3.2.


8BitDo A/B/X/Y layout fix
-------------------------
8BitDo ships several layouts under one vendor id. The Pro 2 in Nintendo mode
reports `a:b1,b:b0`, so a positional binding put GameCube A on the physical B
button and A/B plus X/Y came out reversed.

Detection now reads the live SDL button mapping for the device GUID instead of
trusting the product name:

- Pro 2 Nintendo mode (USB and Bluetooth) -> Nintendo layout, A/B and X/Y
  swapped to match the printed labels.
- Pro 2 in XInput mode -> standard layout.
- Ultimate and 64 stay standard, as before.

Existing auto-generated profiles are migrated to the corrected layout on first
run; hand-edited or manually chosen profiles are left alone.

Startup log line, so you can check what was detected:

  [input] pad0 name="8BitDo Pro 2" guid=03000000c82d00000660000011010000 layout=Nintendo buttons=swapped dpad=normal


DualSense Edge and Xbox Elite Series 1 / 2
------------------------------------------
Identified by USB vendor/product in the SDL GUID, not by name:

- DualSense Edge (054C:0DF2) uses the standard DualSense layout.
- Xbox Elite Series 1 (045E:02E3) and Series 2 (045E:0B00 USB, 045E:0B05
  Bluetooth) use the standard Xbox layout.
- Paddles and the Edge Fn button are deliberately unmapped: the GameCube pad
  has no equivalent input. Map them in your pad software if you want them to
  duplicate a standard button.


Native RVZ support
------------------
You can now drop a Dolphin .rvz disc image straight into setup. There is no
RVZ to ISO conversion step.

The launcher reads the RVZ container natively and extracts exactly the same
files an ISO produces. Verified on this disc: 4227 entries, tree aggregate
3fc07252dc1232f8ca0268e5882099886604d49be96c49289d94dd2345531350 from both
the .iso and the .rvz, with zero content differences.

The dev pipeline also accepts either container:

  powershell -File tools\extract-disc.ps1 -Disc game.rvz -Out work\game


Please verify
-------------
Controllers were validated offline against the SDL controller database and
synthetic GUIDs; physical hardware confirmation is still requested.

- 8BitDo Pro 2 in Nintendo mode: face buttons A/B and X/Y read correctly, and
  the D-pad direction is right.
- 8BitDo Ultimate or 64: unchanged standard layout.
- DualSense Edge: behaves like a standard DualSense.
- Xbox Elite Series 1 / 2: behaves like a standard Xbox pad.

If anything is off, send the one startup line from the log:

  [input] pad0 name="..." guid=... layout=... buttons=... dpad=...


Install
-------
1. Unzip anywhere.
2. Run launcher.exe.
3. Browse for your .iso or .rvz. Setup extracts it into game_data\.
4. Press PLAY.

No game data is included. You need your own USA dump
(1,459,978,240 bytes, CRC-32 635116c6).


Known issues
------------
- The launcher hashes the extracted files at startup, so a ready install shows
  a black window for ~20 s before the UI appears.
- Launcher parity with the guide's chapter 15 is partial (no MSAA/VSync/volume
  exposure, no card import UI, no close-timeout kill).
- The static core is CPU-bound in a four-wrestler match (~50 fps); switch CPU
  core to JIT for a locked 60 there.

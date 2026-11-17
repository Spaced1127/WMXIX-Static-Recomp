WWE WrestleMania XIX - v0.4.4
============================

controllers: one canonical profile, positional/nintendo classes, no profile
rewriting, first-pad fallback + hot-plug

This is the generic controller system ported from WWE WrestleMania X8 v0.1.4.
The per-device profile generator is gone.


What changed
------------
- ONE static GCPadNew.ini (canonical SDL positional bindings). It is written
  only when missing and never rewritten - not at launch, not on a layout
  change, not on a device change.
- Two layout classes: positional (default) and nintendo (A<->B and X<->Y so the
  printed labels match). D-pad, sticks and triggers are never swapped.
- The class is resolved per pad, in the input layer, from SDL's gamepad type
  (Switch Pro / JoyCon), with one small vendor fallback for 8BitDo pads that
  report a standard type while using Nintendo order: 05ac:0004 plus the 8BitDo
  HID ids c82d:0060/0061/0160/0161/0360/0660/0960. A user override wins:
  `controller_class = auto|positional|nintendo` in config.ini, or
  `--controller-layout`.
- Device binding no longer depends on the profile's Device line: at input init
  the runtime checks whether the configured pad is connected and otherwise
  binds the first SDL gamepad in memory (the file is untouched). A 2 s watcher
  repeats the check, so a pad that appears after launch binds without a
  restart.
- Deleted: the profile generator, per-device GUID tables, DetectControllerMapping
  and the a>b rule, the D-pad swap heuristics, profile migration, the 16
  per-family default profiles and tools/make-controller-profiles.ps1.
- Legacy config keys (`controller`, `controller_profile`, `controller_layout`)
  and the old headless flags (`--pad-info`, `--write-pad-profile`, `--pad-guid`,
  `--pad-layout`, `--check-migration`) still parse and never fail; they are
  ignored.

Startup line (players quote it, we triage with it):

  controller: name="SDL/0/Xbox One Controller" guid=0300fa675e040000ff02000000007801 class=auto dpad=normal profile=static


Why this fixes "PlayStation works, Xbox does not"
------------------------------------------------
The old path wrote a profile naming one pad found by a launch-time scan. If the
scan missed the Xbox pad (SDL teardown, sleeping wireless pad, different driver
name), the profile pointed at a device that did not exist and nothing bound -
while a DualSense row happened to match. Now the profile is device-agnostic:
binding falls back to the first pad in memory, so a present Xbox pad always has
input even with a stale profile line.


Two defects in the reference that this port fixes
-------------------------------------------------
1. `SetLayoutClassOverride()` writes the atomic in LayoutClass.h, but the
   reference's `ClassifyGamepad` read a second, file-static atomic in
   SDLGamepad.cpp - so its `--controller-layout` override was a no-op. This
   port reads the shared override.
2. `EnsurePadBound()` used `GetDefaultDeviceString()`, which returns the
   highest-priority device - the keyboard. The "first pad" fallback therefore
   bound "DInput/0/Keyboard Mouse" and the pad still had no input. This port
   picks the first `SDL/...` device.


Verification
------------
Offline (`powershell -File tools\test-controller-layouts.ps1`), 11 checks:
canonical profile contents (positional A/B/X/Y, plain D-pad, triggers, single
[GCPad1]), write-once, keyboard variant, legacy flags exit 0, every class value
accepted, junk class rejected. All pass.

Real runs (visible windows) on the pads available here:
- Xbox One Controller (045e:02ff, XInput): `class=auto`, canonical profile
  written once, 59.94 fps, clean stop.
- `--controller-layout nintendo`: startup line reports `class=nintendo`.
- Profile naming a missing pad ("Ghost Pad") plus the Xbox pad connected:
  `controller: configured device missing; bound "SDL/0/Xbox One Controller"`,
  profile text unchanged (still Ghost Pad), game boots.
- Profile byte-for-byte unchanged across launches.

Not verified on this host: a real Nintendo-class pad (Switch Pro / 8BitDo in
Switch mode), physical hot-plug (would need unplugging a pad) and button-order
press tests. The class code paths are covered offline; the watcher is covered by
the stale-profile run above.
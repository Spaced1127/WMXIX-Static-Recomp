WWE WrestleMania XIX - v0.4.1 (hotfix)
======================================

Controller and memory-card fix. Rendering, performance and disc handling are
unchanged from v0.4.0.

Controller caveat: detection was verified offline against SDL's controller
database and the driver mapping strings, plus one live DualSense run on the
build host. No physical Xbox 360 / One / Series / Elite pad was available, so
Xbox owners should confirm. Send the startup line from the log:

  [input] pad0 name="..." guid=... layout=... buttons=... dpad=... mapping=... source=... device="..."


Xbox controllers: pad detected but nothing worked
--------------------------------------------------
v0.4.0 started `game.exe` by opening SDL with `SDL_Init(SDL_INIT_VIDEO |
SDL_INIT_GAMEPAD)` and then calling `SDL_Quit()` before the emulator started.
That tore SDL down again, so Dolphin's SDL input backend had to initialise the
joystick drivers itself, from its own worker thread and without video.

HIDAPI pads (DualSense, DualSense Edge, Switch Pro, 8BitDo over Bluetooth/USB
mode) still came up that way. The Windows XInput / RAWINPUT / WGI paths that
enumerate a standard Xbox pad did not, so the profile named
`SDL/0/<pad>` but the runtime only ever had `DInput/Keyboard Mouse`:

  [input] pad0 default device='SDL/0/Xbox Series X Controller'
  [input] pad0 connected=0

The pad was detected in the log and bound nothing. Reproduced and fixed with
the runtime's own device list; after the fix the same run shows
`[input] device: SDL/Xbox Series X Controller` and the profile resolves.

Fix: open the gamepad subsystem with `SDL_InitSubSystem` and leave it up, as
v0.3.x did. No `SDL_Quit()` before the game starts.

The Xbox **button layout** was never wrong: every Xbox GUID (360 028E, One
02EA, Series 0B12/0B22, Elite 02E3/0B00/0B05) resolves to `layout=Xbox`,
`dpad=normal` and the standard body, byte-identical to v0.3.2.


Other controller fixes
----------------------
- A profile is only ever written when a pad is present, and an existing
  auto-generated profile is only rewritten when the live mapping now disagrees
  (migration). Custom profiles are still left alone.
- Layout and D-pad are resolved per pad from that pad's own GUID and live SDL
  mapping. Before, pad 1's decision was applied to every pad, so a Switch Pro or
  8BitDo in Nintendo mode on port 1 swapped A/B on an Xbox pad on port 2.
- 8BitDo stays scoped to the live `a`/`b` order: Pro 2 in Nintendo mode swaps,
  Pro 2 in XInput mode and the Ultimate/64 stay standard. The a>b rule is not
  applied to non-8BitDo rows, so Xbox and PlayStation mappings are unaffected.
- Xbox Series 0B22 (and every other 045E product) resolves to the Xbox family
  by GUID; the matrix covers 0B12 and 0B22.
- The device id written into `GCPadNew.ini` now counts the same way the runtime
  does (per name over every SDL joystick it adds), so `SDL/<id>/<name>` is the
  string the runtime resolves.
- `"Xbox Wireless Controller"` no longer resolves to the PlayStation family
  through the old `"wireless controller"` name rule.
- Profile migration now also runs when `config.ini` already names a controller.
  Players who picked their pad in the launcher used to keep an uncorrected
  profile forever.
- The launcher's Controller page "Detected:" label uses the same live-mapping
  resolution as the generator, so 8BitDo no longer shows "Generic", and it
  shows when the D-pad L/R swap is active. No DualSense or DualSense Edge
  mirroring was found in this tree: both resolve to `dpad=normal`.
- One startup line instead of two (the second one hard-coded `dpad=normal` and
  contradicted the first):

  [input] pad0 name="Xbox Series X Controller" guid=0300...7801 layout=Xbox
    buttons=normal dpad=normal mapping=live source=mapping-positional
    device="SDL/0/Xbox Series X Controller"

  `mapping=live|none` says whether SDL had a mapping for the GUID, `source=`
  says what decided the layout (`mapping-nintendo`, `mapping-positional` or
  `guid`).


Saving hangs on "checking memory card in slot A"
------------------------------------------------
Shared fix from the Aggressive Inline project (same ModernGekko/Dolphin runtime
family). Slot A was never configured, so every install used Dolphin's default
`MemoryCardFolder` device with an empty `GC/<region>/Card A`, and the runtime
never created the `GC/` tree before EXI init. The game's card probe then never
completed and the save screen hung. `SlotB = 0` (Dummy) additionally makes the
game report "THE DEVICE IN SLOT B IS NOT SUPPORTED".

Applied:

- `Config/Dolphin.ini`: `[Core] SlotA = 1` (raw 16 MB card) and
  `SlotB = 255` (None = empty slot), forced on every start by both the launcher
  and `game.exe`. Existing installs are repaired even when the keys are absent
  or set to `SlotB = 0`.
- `Runtime::Create`: `UICommon::CreateDirectories()` between
  `SetUserDirectory` and `UICommon::Init` (DolphinQt order), so `GC/USA`,
  `GC/EUR`, `GC/JAP` exist before `ExpansionInterface::Init` resolves the card
  path. The runtime also sets `MAIN_SLOT_A` / `MAIN_SLOT_B` directly, so the
  card is right even if the ini was never written.
- `recomplauncher.json`: `Core/SlotA = 1`, `Core/SlotB = 255` in `ensure`,
  `always` and `new`, so RecompLauncher-only installs get them too.

Verified on a fresh user dir (no `GC/`), headless, clean stop through the
automation `stop` command:

```text
before: GC exists = False
after:  GC/EUR  GC/JAP  GC/USA  MemoryCardA.USA.raw  SRAM.raw
Dolphin.ini: SlotA = 1 / SlotB = 255
MemoryCardA.USA.raw  16,777,216 bytes  sha256 EA5170CF...A2D8A2C5
```

No `GC/USA/Card A` folder is created (that would mean the folder device), and a
second boot leaves the card byte-identical. A legacy install with
`SlotB = 0` and no `SlotA` is repaired to `1` / `255` and produces the same
16 MB card.

Caveat for testers (from the shared pattern): a savestate restores the EXI
device type, so a state made before this fix re-enables the GCI folder. Test
cards with a fresh user dir and the automation `stop` command - a force-kill
skips the card flush and leaves no `.raw` file.

Save / load evidence: on a fresh card the game wrote its system file and the
card carries a real directory entry:

```text
empty formatted card   16,777,216  sha256 EA5170CF...A2D8A2C5
after the game save    16,777,216  sha256 1C2B0319F9EB88877D74393CE500FE0B2FD3AAC8B970E65B96EF27A0A21AC327
entry 0                gamecode GW9E  company 78  name /wmx9_sys
```

Booting again with that card kept the SHA unchanged after a clean exit, so the
game read the existing card instead of reformatting it. A UI-level
"LOADING <file>" round trip was not observed; the card-level read is what is
proven here. Note the empty-card hash varies per format (the header carries a
serial), so only compare the same file before and after.


Offline layout matrix
---------------------
`tools\test-pad-layouts.ps1` asserts layout, D-pad and the generated
`Buttons/A` for 18 cases against the real launcher binary, no hardware needed:

  Xbox 360 (plain + XInput GUID), Xbox One, Xbox Series (0B12, 0B22),
  Xbox Elite S1, Elite S2 USB, Elite S2 BT, Xbox name-only fallback,
  DualSense, DualSense Edge USB + BT, 8BitDo Pro 2 Nintendo mode,
  8BitDo Pro 2 XInput mode, 8BitDo Ultimate, 8BitDo 64, Switch Pro,
  synthetic reversed D-pad

  result: 18 / 18 PASS


Install
-------
Unzip over v0.4.0 (or into a new folder) and keep your user folder. Existing
auto-generated profiles are migrated on first run; hand-edited profiles are
left alone.
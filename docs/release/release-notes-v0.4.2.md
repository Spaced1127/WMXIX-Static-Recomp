WWE WrestleMania XIX - v0.4.2
============================

Hotfix for the startup error dialog introduced by the v0.4.1 controller +
memory-card work. v0.4.1 could abort at startup with:

  An error occurred.
  Condition: GImGui != 0 && "No current context. Did you call
             ImGui::CreateContext() and ImGui::SetCurrentContext()?"
  File: ...\imgui.cpp
  Line: 4985
  Function: GetIO
  Ignore and continue?


What happened
-------------
The ImGui context was created in exactly one place: the renderer's
`OnScreenUI::Initialize`, which runs after the core has started. Anything that
touched a UI surface before that - the OSD message queue, the statistics
window, the debug text - called `ImGui::GetIO()` with no current context and
tripped the assert.

v0.4.1 made more work happen before the renderer is up: controller detection and
profile migration on every start, the memory-card slot migration, and the
`GC/` directory tree. Combined with the v0.4.0 SDL teardown that v0.4.1
reverted, a machine could reach a UI path before any context existed. The
dialog offers "Ignore and continue", but it must never appear.

Fix
---
- `game.exe`: create the ImGui context before `Runtime::Create`, so it exists
  before the core, the OSD queue or the statistics code can run.
- `launcher.exe`: create the context at the top of `main`, before config load,
  controller enumeration and profile writing.
- `OnScreenUI::Initialize` now adopts an existing context instead of creating a
  second one, so the renderer still configures fonts, style and the vertex
  format exactly as before.

Both init paths are idempotent: if a context already exists it is reused.


Also in this release (from v0.4.1)
----------------------------------
Controller
- Xbox pads work. v0.4.0 quit SDL before the runtime started, so the Windows
  XInput/RAWINPUT/WGI paths never enumerated a standard Xbox pad and the
  generated profile pointed at a device that did not exist (pad0 connected=0).
- Layout and D-pad resolve per pad from that pad's own GUID and live SDL
  mapping; pad 1 no longer swaps A/B on pad 2. 8BitDo stays scoped to the live
  a/b order. Device ids match the runtime's own numbering. One truthful
  startup line (`layout= buttons= dpad= mapping= source= device=`).

Memory card
- Saves no longer hang on "checking memory card in slot A". Slot A is a raw
  16 MB card (`SlotA = 1`), slot B is empty (`SlotB = 255` = None, not Dummy),
  `GC/<region>` is created before EXI init, and existing installs are migrated
  by both the launcher and the game.

Verified: fresh card 16,777,216 bytes; the game's save wrote a directory entry
(`GW9E` / `78` / `/wmx9_sys`) with the card SHA changing from
`EA5170CF...A2D8A2C5` to `1C2B0319...21AC327`; a second boot read the card and
left it byte-identical.


Caveats
-------
- The startup assert could not be reproduced on the build host with either
  v0.4.1 or v0.4.2 (many boots: windowed, fullscreen, their config, an Xbox pad
  attached). The fix removes the precondition - a UI call with no current
  context - rather than a single known call site. If it still appears, send
  the dialog title and the exact line/function plus `Logs\ModernGekko.log`.
- Controllers were verified offline against SDL's database (18-case matrix) and
  with a live DualSense; Xbox owners should confirm with the startup line.
- An in-game LOAD round trip of a memory-card save was not observed; card-level
  read/write is what is proven.
- Updating from v0.4.0 moves saves from `GC\<region>\Card A\*.gci` to
  `GC\MemoryCardA.<region>.raw`. The old folder is left untouched but unused.


Install
-------
Unzip over your install (keep `game_data/`), or extract to a new folder and
point it at your disc again. Existing auto-generated controller profiles are
migrated; hand-edited profiles are left alone.
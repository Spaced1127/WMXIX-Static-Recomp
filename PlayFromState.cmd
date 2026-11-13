@echo off
REM Start the game from a save state instead of the long boot.
REM Default: work\states\manual.state   (make one with SaveState.cmd)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\run.ps1" -LoadState "%~dp0work\states\manual.state" %*

@echo off
REM Press this while playing to save a state to work\states\manual.state
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\request-save.ps1" %*
pause

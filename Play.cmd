@echo off
REM Double-click to play WWE WrestleMania XIX.
REM Pass -Graphics OpenGL if Vulkan misbehaves.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\run.ps1" %*

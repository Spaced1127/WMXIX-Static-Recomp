$ErrorActionPreference = 'Continue'
. "H:\Projects\WWE WMXIIIV\tools\msvc-env.ps1" | Out-Null
Set-Location "H:\Projects\WWE WMXIIIV\lib\ModernGekko-Template"

# The previous tree was configured with GNU-style Clang, which cannot build
# Dolphin's vendored libusb on modern Windows SDKs. MSVC is the supported
# window toolchain for the runtime; Clang is used only for the game module.
if (Test-Path lib/ModernGekko/build) { Remove-Item -Recurse -Force lib/ModernGekko/build }

$dolSha = "627b899760d0b820c049ad29f96a613da1c43d35dd4a1456e581cc620bae9fb7"

cmake -S lib/ModernGekko -B lib/ModernGekko/build -G Ninja `
  -DCMAKE_BUILD_TYPE=Release `
  -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl `
  -DMODERNGEKKO_FRONTEND_NAME="WWE WrestleMania XIX Recomp" `
  -DMODERNGEKKO_LAUNCHER_OUTPUT_NAME="WMXIX" `
  -DMODERNGEKKO_RUNNER_OUTPUT_NAME="WMXIXRunner" `
  -DMODERNGEKKO_USER_DIRECTORY_NAME="WMXIX" `
  -DMODERNGEKKO_DEFAULT_WINDOW_TITLE="WWE WrestleMania XIX" `
  -DMODERNGEKKO_REQUIRED_DISC_ID="GW9E78" `
  -DMODERNGEKKO_REQUIRED_DOL_SHA256="$dolSha" `
  -DMODERNGEKKO_PORTABLE_DEFAULT_GAME=ON `
  -DMODERNGEKKO_GAMECUBE_CONTROLLERS=ON 2>&1 | Select-Object -Last 25
Write-Output ("EXIT=" + $LASTEXITCODE)

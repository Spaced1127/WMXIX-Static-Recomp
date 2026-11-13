# Generate C from the retail DOL and compile the game module.
# Usage: tools\recompile.ps1 [-Toolchain clang] [-OptLevel 3]
param(
    [string]$Toolchain = "clang",
    [string]$OptLevel  = "3"
)
$ErrorActionPreference = 'Continue'
. "H:\Projects\WWE WMXIIIV\tools\msvc-env.ps1" | Out-Null

$root = "H:\Projects\WWE WMXIIIV"
$port = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\moderngekko-port.exe"

if (-not (Test-Path $port)) { throw "moderngekko-port.exe not built yet: $port" }

& $port build "$root\work\game" --backend c --toolchain $Toolchain --opt-level $OptLevel --output "$root\build\modules"
Write-Output ("EXIT=" + $LASTEXITCODE)

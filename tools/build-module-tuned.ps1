# Build a tuned module DLL from an existing DolRecomp output directory.
#
# The stock `moderngekko-port build` path compiles with -O2 + thin LTO but no
# CPU baseline and no DolRecomp loop/call budgets. This script configures the
# same module template directly with the guide's tuned flags.
#
# Usage:
#   tools\build-module-tuned.ps1 -GeneratedDir <...\dolrecomp-output\generated> [-OutDir <dir>]
param(
    [Parameter(Mandatory=$true)][string]$GeneratedDir,
    [string]$OutDir = "H:\Projects\WWE WMXIIIV\build\modules\GW9E78\tuned",
    [string]$March = "x86-64-v3",
    [string]$ExtraFlags = ""
)
$ErrorActionPreference = 'Continue'
. "H:\Projects\WWE WMXIIIV\tools\msvc-env.ps1" | Out-Null

$root   = "H:\Projects\WWE WMXIIIV"
$mg     = "$root\lib\ModernGekko-Template\lib\ModernGekko"
$tmpl   = "$mg\vendor\dolphin\module-template"
$build  = Join-Path $OutDir "module-build"

$flags = @(
    "-march=$March",
    "-mtune=generic",
    "-O3",
    "-DNDEBUG",
    "-std=gnu11",
    "-flto=thin",
    "-ffp-contract=off",
    "-fno-fast-math",
    "-DDOLRECOMP_C_LOOP_CYCLE_BUDGET=4096",
    "-DDOLRECOMP_C_MAX_CALL_DEPTH=128"
) -join " "
if ($ExtraFlags) { $flags = "$flags $ExtraFlags" }

Write-Host "[module] generated: $GeneratedDir"
Write-Host "[module] out:       $OutDir"
Write-Host "[module] flags:     $flags"

# CMAKE_NINJA_FORCE_RESPONSE_FILE is required: the module links thousands of
# chunk objects and would otherwise overflow the Windows command line.
$env:CMAKE_NINJA_FORCE_RESPONSE_FILE = "1"

cmake -S $tmpl -B $build -G Ninja `
    -DCMAKE_BUILD_TYPE=Release `
    -DCMAKE_C_COMPILER=clang `
    -DGAME_ID=GW9E78 `
    -DGENERATED_DIR="$GeneratedDir" `
    -DGXRUNTIME_DIR="$mg\vendor\dolphin\GXRuntime" `
    -DCHASSIS_ABI_DIR="$mg\vendor\dolphin\Source\Core\Core\PowerPC\StaticRecomp" `
    -DRECOMPCORE_MODULE_OPT_LEVEL=3 `
    -DCMAKE_C_FLAGS="$flags" `
    -DCMAKE_SHARED_LINKER_FLAGS="-flto=thin" 2>&1 | Select-Object -Last 10
if ($LASTEXITCODE -ne 0) { throw "configure failed" }

cmake --build $build -j 16 2>&1 | Select-Object -Last 30
if ($LASTEXITCODE -ne 0) { throw "build failed" }

$dll = Get-ChildItem $build -Recurse -Filter "gGW9E78_recomp.dll" | Select-Object -First 1
Write-Host "[module] built: $($dll.FullName)"
if ($dll) { Copy-Item $dll.FullName (Join-Path $OutDir "gGW9E78_recomp.dll") -Force }

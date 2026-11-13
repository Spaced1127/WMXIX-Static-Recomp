# Launch the port.
# Usage: tools\run.ps1 [-Headless] [-Module <dll>] [-LoadState <file>] [-Graphics Vulkan]
param(
    [switch]$Headless,
    [string]$Module,
    [string]$LoadState,
    [string]$Graphics = "Vulkan",
    [string]$Audio    = "",
    [ValidateSet("", "static", "jit")]
    [string]$Core     = "",
    [string[]]$Extra  = @()
)
$ErrorActionPreference = 'Continue'

$root    = "H:\Projects\WWE WMXIIIV"
$runner  = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\WMXIXRunner.exe"
$modules = "$root\build\modules\GW9E78"

if (-not (Test-Path $runner)) { throw "runner not built: $runner" }

if (-not $Module) {
    $active = Join-Path $modules "active-module.txt"
    if (Test-Path $active) {
        $Module = (Get-Content $active -Raw).Trim()
    } else {
        $dll = Get-ChildItem $modules -Recurse -Filter "gGW9E78_recomp.dll" -ErrorAction SilentlyContinue |
               Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if (-not $dll) { throw "no module found under $modules" }
        $Module = $dll.FullName
    }
}

# Make sure a pad binding exists; with none the game ignores every button.
$padIni = "$root\work\user\Config\GCPadNew.ini"
if (-not (Test-Path $padIni)) {
    Write-Host "[run] no controller bindings found, detecting a pad"
    & "$root\tools\set-controls.ps1" -Mode auto
}

# Keep the automation channel open while playing so SaveState.cmd can ask the
# running game for a snapshot without restarting it.
$auto = "$root\build\auto"
New-Item -ItemType Directory -Force -Path $auto,"$auto\commands","$auto\processed" | Out-Null

$runnerArgs = @(
    "--game",       "$root\work\game",
    "--module",     $Module,
    "--user-dir",   "$root\work\user",
    "--automation-dir", $auto,
    "--graphics",   $Graphics,
    "--allow-interpreter"
)
if ($Audio) { $runnerArgs += @("--audio", $Audio) }
if ($Core)  { $runnerArgs += @("--core", $Core) }
if ($Headless)  { $runnerArgs += "--headless" }
if ($LoadState) { $runnerArgs += @("--load-state", $LoadState) }
if ($Extra.Count -gt 0) { $runnerArgs += $Extra }

Write-Host "[run] $runner"
Write-Host "[run] module: $Module"
& $runner @runnerArgs
Write-Output ("EXIT=" + $LASTEXITCODE)

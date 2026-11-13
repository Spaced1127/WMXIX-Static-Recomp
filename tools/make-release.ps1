# Build a player-facing release folder with no game data in it.
#
#   tools\make-release.ps1 -Version 0.1.0
#   tools\make-release.ps1 -Version 0.1.0 -Module build\modules\...\gGW9E78_recomp.dll
param(
    [string]$Version = "0.3.0",
    [string]$Module,
    [string]$OutRoot = "H:\Projects\WWE WMXIIIV\dist"
)
$ErrorActionPreference = 'Stop'
$root   = "H:\Projects\WWE WMXIIIV"
$build  = "$root\lib\ModernGekko-Template\lib\ModernGekko\build"
$name   = "WMXIX-v$Version-Windows-x64"
$out    = Join-Path $OutRoot $name

if (-not $Module) {
    $Module = (Get-Content "$root\build\modules\GW9E78\active-module.txt" -Raw).Trim()
}
if (-not (Test-Path $Module)) { throw "module not found: $Module" }

New-Item -ItemType Directory -Force -Path $out | Out-Null

# Rebuild from scratch: Copy-Item -Recurse into an existing directory nests a
# second copy (assets\assets, Sys\Sys) and doubles the release size.
if (Test-Path $out) { Remove-Item -Recurse -Force $out }
New-Item -ItemType Directory -Force -Path $out | Out-Null

Write-Host "[release] launcher + game"
Copy-Item "$build\launcher.exe" $out -Force
Copy-Item "$build\game.exe" $out -Force

Write-Host "[release] Sys data"
Copy-Item "$build\Sys" (Join-Path $out "Sys") -Recurse -Force

Write-Host "[release] launcher art (SteamGridDB)"
foreach ($art in @("backdrop.bmp", "logo.bmp", "icon.bmp")) {
    Copy-Item "$root\assets_src\$art" $out -Force
}

Write-Host "[release] module"
Copy-Item $Module (Join-Path $out "gGW9E78_recomp.dll") -Force

Write-Host "[release] manifest + docs"
Copy-Item "$root\docs\release\recomplauncher.json" $out -Force
Copy-Item "$root\docs\release\README.txt" $out -Force
Copy-Item "$root\docs\release\PLAYERS.md" $out -Force
Copy-Item "$root\docs\release\theme.ini" $out -Force
Copy-Item "$root\docs\release\defaults" (Join-Path $out "defaults") -Recurse -Force
Copy-Item "$root\LICENSE" $out -Force -ErrorAction SilentlyContinue

# --- game-data gate ---------------------------------------------------------
Write-Host "[release] scanning for game data"
$bad = Get-ChildItem $out -Recurse -File | Where-Object {
    $_.Extension -in '.iso', '.rvz', '.wbfs', '.gcm', '.dol', '.rel', '.gci', '.sav', '.state', '.psd' -or
    $_.FullName -match '\\Game\\' -or
    $_.FullName -match '\\files\\' -or
    $_.Name -in 'main.dol', 'boot.bin', 'bi2.bin', 'apploader.img'
}
if ($bad) {
    $bad | ForEach-Object { Write-Warning "game data: $($_.FullName)" }
    throw "release contains game data - refusing to package"
}
Write-Host "[release] clean"

$zip = Join-Path $OutRoot "$name.zip"
Remove-Item $zip -ErrorAction SilentlyContinue
Compress-Archive -Path (Join-Path $out '*') -DestinationPath $zip -CompressionLevel Optimal
$hash = (Get-FileHash $zip -Algorithm SHA256).Hash
Write-Host ""
Write-Host "[release] folder: $out"
Write-Host ("[release] size:   {0:N1} MB" -f ((Get-ChildItem $out -Recurse -File | Measure-Object Length -Sum).Sum / 1MB))
Write-Host "[release] zip:    $zip"
Write-Host "[release] sha256: $hash"
"$hash *$name.zip" | Set-Content (Join-Path $OutRoot "SHA256SUMS.txt")

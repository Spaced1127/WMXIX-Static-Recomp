# Copy this project's runtime patches over a freshly cloned
# lib/ModernGekko-Template.
#
#   git clone https://github.com/ExpansionPak/ModernGekko-Template.git lib/ModernGekko-Template
#   cd lib/ModernGekko-Template && git submodule update --init --recursive && cd ../..
#   powershell -File tools\apply-patches.ps1
#
# The patches are file copies, not diffs, because several of them (launcher,
# frontend_config) are already a generation ahead of upstream. Re-running is
# safe and idempotent.
param(
    [string]$Root = "H:\Projects\WWE WMXIIIV"
)
$ErrorActionPreference = 'Stop'
$source = Join-Path $Root "patched\lib\ModernGekko"
$target = Join-Path $Root "lib\ModernGekko-Template\lib\ModernGekko"

if (-not (Test-Path $target)) { throw "runtime not found at $target; clone the template first" }

$files = Get-ChildItem $source -Recurse -File
foreach ($file in $files) {
    $relative = $file.FullName.Substring($source.Length).TrimStart('\')
    $destination = Join-Path $target $relative
    New-Item -ItemType Directory -Force -Path (Split-Path $destination) | Out-Null
    Copy-Item $file.FullName $destination -Force
    # Copy-Item keeps the source timestamp; ninja only rebuilds newer files.
    (Get-Item $destination).LastWriteTime = Get-Date
    Write-Host "[patch] $relative"
}
Write-Host "[patch] applied $($files.Count) files to $target"

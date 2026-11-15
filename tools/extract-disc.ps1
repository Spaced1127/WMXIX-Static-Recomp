# Extract a GameCube disc image to sys/ + files/, accepting ISO and RVZ.
#
#   tools\extract-disc.ps1 -Disc work\disc\wmxix.rvz -Out work\game
#
# RVZ is detected by magic (RVZ\x01) and converted to a cached ISO first with
# tools\rvz_extract.py, which reproduces the ISO byte for byte. No manual
# RVZ -> ISO step is required; the conversion is an implementation detail.
param(
    [Parameter(Mandatory = $true)][string]$Disc,
    [string]$Out = "H:\Projects\WWE WMXIIIV\work\game",
    [string]$CacheDir = "H:\Projects\WWE WMXIIIV\work\disc"
)
$ErrorActionPreference = 'Stop'
$root = "H:\Projects\WWE WMXIIIV"

if (-not (Test-Path $Disc)) { throw "disc image not found: $Disc" }

$magic = [System.IO.File]::ReadAllBytes($Disc)
$isRvz = ($magic.Length -ge 4 -and $magic[0] -eq 0x52 -and $magic[1] -eq 0x56 -and $magic[2] -eq 0x5A)
$magic = $null

$iso = $Disc
if ($isRvz) {
    New-Item -ItemType Directory -Force -Path $CacheDir | Out-Null
    $iso = Join-Path $CacheDir ([System.IO.Path]::GetFileNameWithoutExtension($Disc) + ".iso")
    if (Test-Path $iso) {
        Write-Host "[disc] using cached ISO: $iso"
    } else {
        Write-Host "[disc] RVZ detected, reconstructing ISO (one time)"
        python "$root\tools\rvz_extract.py" $Disc $iso
        if ($LASTEXITCODE -ne 0) { throw "RVZ extraction failed" }
    }
} else {
    Write-Host "[disc] ISO detected"
}

Write-Host "[disc] extracting files/ tree"
python "$root\tools\gcdisc.py" extract $iso (Join-Path $Out "files")
if ($LASTEXITCODE -ne 0) { throw "file tree extraction failed" }

Write-Host "[disc] extracting sys/"
python "$root\tools\extract_sys.py" $iso (Join-Path $Out "sys")
if ($LASTEXITCODE -ne 0) { throw "sys extraction failed" }

Write-Host "[disc] done: $Out"

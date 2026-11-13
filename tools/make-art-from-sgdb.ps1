# Convert the SteamGridDB PNGs in assets_src into the files the launcher and
# executables use.
#
#   tools\make-art-from-sgdb.ps1
#
# Inputs : assets_src\hero.png, logo.png, icon.png, grid.png
# Outputs: assets_src\backdrop.bmp, logo.bmp, icon.bmp, icon.ico
param(
    [string]$SrcDir = "H:\Projects\WWE WMXIIIV\assets_src",
    [string]$OutDir = "H:\Projects\WWE WMXIIIV\assets_src"
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

function Save-Bmp($image, $path, [int]$maxW, [int]$maxH = 0) {
    $scale = [Math]::Min(1.0, $maxW / $image.Width)
    if ($maxH -gt 0) { $scale = [Math]::Min($scale, $maxH / $image.Height) }
    $w = [int][Math]::Round($image.Width * $scale)
    $h = [int][Math]::Round($image.Height * $scale)
    $bmp = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($image, 0, 0, $w, $h)
    $g.Dispose()
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Bmp)
    $bmp.Dispose()
    Write-Host ("[art] {0}  {1}x{2}" -f (Split-Path $path -Leaf), $w, $h)
}

# --- backdrop: hero cropped to the launcher's 1920x620 banner area ----------
$heroPath = Join-Path $SrcDir "hero.png"
if (Test-Path $heroPath) {
    $hero = [System.Drawing.Image]::FromFile($heroPath)
    try {
        $targetW = 1920; $targetH = 620
        # centre-crop to the target aspect, then scale
        $srcAspect = $hero.Width / $hero.Height
        $dstAspect = $targetW / $targetH
        if ($srcAspect -gt $dstAspect) {
            $cropH = $hero.Height
            $cropW = [int]($hero.Height * $dstAspect)
            $cropX = [int](($hero.Width - $cropW) / 2)
            $cropY = 0
        } else {
            $cropW = $hero.Width
            $cropH = [int]($hero.Width / $dstAspect)
            $cropX = 0
            $cropY = [int](($hero.Height - $cropH) * 0.35)
        }
        $bmp = New-Object System.Drawing.Bitmap $targetW, $targetH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($hero, (New-Object System.Drawing.Rectangle 0, 0, $targetW, $targetH),
                     (New-Object System.Drawing.Rectangle $cropX, $cropY, $cropW, $cropH),
                     [System.Drawing.GraphicsUnit]::Pixel)
        $g.Dispose()
        $bmp.Save((Join-Path $OutDir "backdrop.bmp"), [System.Drawing.Imaging.ImageFormat]::Bmp)
        $bmp.Dispose()
        Write-Host "[art] backdrop.bmp  ${targetW}x${targetH}"
    } finally { $hero.Dispose() }
}

# --- logo ------------------------------------------------------------------
$logoPath = Join-Path $SrcDir "logo.png"
if (Test-Path $logoPath) {
    $logo = [System.Drawing.Image]::FromFile($logoPath)
    try { Save-Bmp $logo (Join-Path $OutDir "logo.bmp") 620 } finally { $logo.Dispose() }
}

# --- icon: BMP for the window, ICO for the executables ---------------------
$iconPath = Join-Path $SrcDir "icon.png"
if (Test-Path $iconPath) {
    $icon = [System.Drawing.Image]::FromFile($iconPath)
    try {
        Save-Bmp $icon (Join-Path $OutDir "icon.bmp") 256 256

        # ICO container with PNG-compressed entries (Vista+).
        $sizes = @(256, 128, 64, 48, 32, 16)
        $pngs = @()
        foreach ($s in $sizes) {
            $bmp = New-Object System.Drawing.Bitmap $s, $s, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.DrawImage($icon, 0, 0, $s, $s)
            $g.Dispose()
            $ms = New-Object System.IO.MemoryStream
            $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
            $bmp.Dispose()
            $pngs += ,@($s, $ms.ToArray())
        }
        $icoPath = Join-Path $OutDir "icon.ico"
        $fs = [System.IO.File]::Create($icoPath)
        $bw = New-Object System.IO.BinaryWriter $fs
        $bw.Write([UInt16]0); $bw.Write([UInt16]1); $bw.Write([UInt16]$pngs.Count)
        $offset = 6 + (16 * $pngs.Count)
        foreach ($entry in $pngs) {
            $s = $entry[0]; $bytes = $entry[1]
            $dim = if ($s -ge 256) { 0 } else { $s }
            $bw.Write([Byte]$dim); $bw.Write([Byte]$dim)
            $bw.Write([Byte]0); $bw.Write([Byte]0)
            $bw.Write([UInt16]1); $bw.Write([UInt16]32)
            $bw.Write([UInt32]$bytes.Length); $bw.Write([UInt32]$offset)
            $offset += $bytes.Length
        }
        foreach ($entry in $pngs) { $bw.Write($entry[1]) }
        $bw.Flush(); $bw.Dispose(); $fs.Dispose()
        Write-Host "[art] icon.bmp 256x256, icon.ico $($pngs.Count) sizes"
    } finally { $icon.Dispose() }
}

Write-Host "[art] done -> $OutDir"

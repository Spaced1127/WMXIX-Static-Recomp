# Draw original placeholder launcher art (no third-party assets).
# Produces assets\launcher-bg.bmp, launcher-logo.bmp, icon.bmp.
#
# If you have a SteamGridDB API key, tools\fetch-art.ps1 replaces these with
# real hero/logo/icon art for the title.
param(
    [string]$OutDir = "H:\Projects\WWE WMXIIIV\lib\ModernGekko-Template\lib\ModernGekko\build\assets"
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function New-BrushGradient([System.Drawing.RectangleF]$rect, $c1, $c2, [single]$angle) {
    return New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $c1, $c2, $angle)
}

# ---------------------------------------------------------------- background
$W = 1920; $H = 1080
$bg = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($bg)
$g.SmoothingMode = 'AntiAlias'
$g.Clear([System.Drawing.Color]::FromArgb(255, 5, 7, 13))

# steel base gradient
$rect = New-Object System.Drawing.RectangleF 0, 0, $W, $H
$baseBrush = New-BrushGradient $rect ([System.Drawing.Color]::FromArgb(255, 12, 18, 30)) ([System.Drawing.Color]::FromArgb(255, 4, 6, 11)) 90
$g.FillRectangle($baseBrush, $rect)
$baseBrush.Dispose()

# blue key glow, upper left
$glow = New-Object System.Drawing.Drawing2D.GraphicsPath
$glow.AddEllipse(-500, -650, 1900, 1500)
$pgb = New-Object System.Drawing.Drawing2D.PathGradientBrush $glow
$pgb.CenterColor = [System.Drawing.Color]::FromArgb(120, 40, 90, 160)
$pgb.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
$g.FillPath($pgb, $glow)
$pgb.Dispose(); $glow.Dispose()

# red wash, lower right
$glow2 = New-Object System.Drawing.Drawing2D.GraphicsPath
$glow2.AddEllipse(900, 380, 1500, 1200)
$pgb2 = New-Object System.Drawing.Drawing2D.PathGradientBrush $glow2
$pgb2.CenterColor = [System.Drawing.Color]::FromArgb(110, 150, 20, 26)
$pgb2.SurroundColors = @([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
$g.FillPath($pgb2, $glow2)
$pgb2.Dispose(); $glow2.Dispose()

# light beams from the truss
for ($i = 0; $i -lt 7; $i++) {
    $x = 180 + $i * 260
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(26, 190, 210, 240)), (14 + ($i % 3) * 8)
    $g.DrawLine($pen, $x, -80, $x + 160, $H + 80)
    $pen.Dispose()
}

# arena floor
$floor = New-Object System.Drawing.RectangleF 0, 780, $W, 300
$fb = New-BrushGradient $floor ([System.Drawing.Color]::FromArgb(255, 26, 33, 46)) ([System.Drawing.Color]::FromArgb(255, 8, 10, 16)) 90
$g.FillRectangle($fb, $floor)
$fb.Dispose()

# vignette
$vig = New-Object System.Drawing.Drawing2D.GraphicsPath
$vig.AddEllipse(-350, -260, $W + 700, $H + 520)
$vgb = New-Object System.Drawing.Drawing2D.PathGradientBrush $vig
$vgb.CenterColor = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
$vgb.SurroundColors = @([System.Drawing.Color]::FromArgb(230, 0, 0, 0))
$g.FillPath($vgb, $vig)
$vgb.Dispose(); $vig.Dispose()

$g.Dispose()
$bg.Save((Join-Path $OutDir 'launcher-bg.bmp'), [System.Drawing.Imaging.ImageFormat]::Bmp)
$bg.Dispose()
Write-Host "[art] launcher-bg.bmp"

# ---------------------------------------------------------------------- logo
$LW = 1400; $LH = 380
$logo = New-Object System.Drawing.Bitmap $LW, $LH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$lg = [System.Drawing.Graphics]::FromImage($logo)
$lg.SmoothingMode = 'AntiAlias'
$lg.TextRenderingHint = 'AntiAliasGridFit'
$lg.Clear([System.Drawing.Color]::Transparent)

$family = $null
foreach ($name in @('Impact', 'Arial Black', 'Segoe UI Black', 'Arial')) {
    try { $family = New-Object System.Drawing.FontFamily $name; break } catch { }
}
if (-not $family) { $family = (New-Object System.Drawing.Font 'Arial', 10).FontFamily }

function Add-TextPath($text, $size, $x, $y, $family) {
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $fmt = [System.Drawing.StringFormat]::GenericTypographic
    $path.AddString($text, $family, [int][System.Drawing.FontStyle]::Bold, $size,
                     (New-Object System.Drawing.PointF $x, $y), $fmt)
    return $path
}

# WRESTLEMANIA - chrome
$p1 = Add-TextPath 'WRESTLEMANIA' 150 20 60 $family
$lg.DrawPath((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 8, 10, 14)), 18), $p1)
$lg.DrawPath((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(200, 210, 220, 235)), 3), $p1)
$chrome = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.Rectangle 0, 40, $LW, 220),
    [System.Drawing.Color]::FromArgb(255, 255, 255, 255),
    [System.Drawing.Color]::FromArgb(255, 96, 116, 142), 90)
$blend = New-Object System.Drawing.Drawing2D.ColorBlend 4
$blend.Colors = @(
    [System.Drawing.Color]::FromArgb(255, 236, 243, 252),
    [System.Drawing.Color]::FromArgb(255, 96, 112, 136),
    [System.Drawing.Color]::FromArgb(255, 216, 228, 244),
    [System.Drawing.Color]::FromArgb(255, 70, 84, 106))
$blend.Positions = @(0.0, 0.42, 0.58, 1.0)
$chrome.InterpolationColors = $blend
$lg.FillPath($chrome, $p1)
$chrome.Dispose(); $p1.Dispose()

# XIX - red accent
$p2 = Add-TextPath 'XIX' 190 980 150 $family
$lg.DrawPath((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 10, 6, 6)), 20), $p2)
$lg.DrawPath((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(220, 240, 200, 200)), 3), $p2)
$red = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    (New-Object System.Drawing.Rectangle 900, 120, 460, 260),
    [System.Drawing.Color]::FromArgb(255, 226, 74, 74),
    [System.Drawing.Color]::FromArgb(255, 118, 8, 12), 90)
$lg.FillPath($red, $p2)
$red.Dispose(); $p2.Dispose()

$lg.Dispose()
$logo.Save((Join-Path $OutDir 'launcher-logo.bmp'), [System.Drawing.Imaging.ImageFormat]::Bmp)
$logo.Dispose()
Write-Host "[art] launcher-logo.bmp"

# ---------------------------------------------------------------------- icon
$IC = 256
$icon = New-Object System.Drawing.Bitmap $IC, $IC, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$ig = [System.Drawing.Graphics]::FromImage($icon)
$ig.SmoothingMode = 'AntiAlias'
$ig.Clear([System.Drawing.Color]::Transparent)
$plate = New-Object System.Drawing.Drawing2D.GraphicsPath
$plate.AddEllipse(8, 8, $IC - 16, $IC - 16)
$icoRect = New-Object System.Drawing.RectangleF 8, 8, ($IC - 16), ($IC - 16)
$icoC1 = [System.Drawing.Color]::FromArgb(255, 34, 44, 62)
$icoC2 = [System.Drawing.Color]::FromArgb(255, 8, 10, 16)
$pb = New-Object System.Drawing.Drawing2D.LinearGradientBrush $icoRect, $icoC1, $icoC2, 60
$ig.FillPath($pb, $plate)
$pb.Dispose()
$ig.DrawPath((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 180, 190, 205)), 5), $plate)
$plate.Dispose()
$ip = Add-TextPath 'XIX' 96 46 74 $family
$ig.DrawPath((New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 8, 8, 10)), 12), $ip)
$ig.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 214, 46, 52))), $ip)
$ip.Dispose()
$ig.Dispose()
$icon.Save((Join-Path $OutDir 'icon.bmp'), [System.Drawing.Imaging.ImageFormat]::Bmp)
$icon.Dispose()
Write-Host "[art] icon.bmp"

Write-Host "[art] written to $OutDir"

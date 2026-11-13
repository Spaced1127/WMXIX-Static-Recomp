# Fetch launcher art from SteamGridDB and convert it to the BMP files the
# launcher loads.
#
#   $env:STEAMGRIDDB_API_KEY = "..."
#   tools\fetch-art.ps1
#   tools\fetch-art.ps1 -GameId 5058          # skip the search step
#
# SteamGridDB's API requires a personal key from
# https://www.steamgriddb.com/profile/preferences/api
#
# Output (next to the launcher): assets\launcher-bg.bmp, launcher-logo.bmp, icon.bmp
param(
    [string]$ApiKey = $env:STEAMGRIDDB_API_KEY,
    [string]$GameId = "",
    [string]$Term   = "WrestleMania XIX",
    [string]$OutDir = "H:\Projects\WWE WMXIIIV\lib\ModernGekko-Template\lib\ModernGekko\build\assets",
    [string]$RawDir = "H:\Projects\WWE WMXIIIV\assets_src"
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if (-not $ApiKey) {
    Write-Warning "No SteamGridDB API key. Set `$env:STEAMGRIDDB_API_KEY or pass -ApiKey."
    Write-Warning "Get one at https://www.steamgriddb.com/profile/preferences/api"
    exit 1
}
$headers = @{ Authorization = "Bearer $ApiKey" }
$api = "https://www.steamgriddb.com/api/v2"
New-Item -ItemType Directory -Force -Path $OutDir, $RawDir | Out-Null

function Get-Json($url) {
    return Invoke-RestMethod -Uri $url -Headers $headers -Method Get
}

if (-not $GameId) {
    Write-Host "[art] searching SteamGridDB for '$Term'..."
    $search = Get-Json "$api/search/autocomplete/$([uri]::EscapeDataString($Term))"
    if (-not $search.success -or -not $search.data) { throw "no SteamGridDB match for '$Term'" }
    $search.data | Select-Object -First 5 | ForEach-Object { Write-Host ("  {0}  {1}" -f $_.id, $_.name) }
    $GameId = $search.data[0].id
    Write-Host "[art] using game id $GameId ($($search.data[0].name))"
}

function Save-Url($url, $path) {
    Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing
    return $path
}

# hero (wide background) -> grid (portrait, fallback) -> logo -> icon
$heroes = Get-Json "$api/heroes/game/$GameId?dimensions=1920x620,3840x1240"
$logos  = Get-Json "$api/logos/game/$GameId?mimes=image/png,image/webp"
$icons  = Get-Json "$api/icons/game/$GameId"

function To-Bmp($source, $dest, [int]$maxW) {
    $img = [System.Drawing.Image]::FromFile($source)
    try {
        $scale = [Math]::Min(1.0, $maxW / $img.Width)
        $w = [int]($img.Width * $scale); $h = [int]($img.Height * $scale)
        $bmp = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($img, 0, 0, $w, $h)
        $g.Dispose()
        $bmp.Save($dest, [System.Drawing.Imaging.ImageFormat]::Bmp)
        $bmp.Dispose()
        Write-Host "[art] $dest  ($w x $h)"
    } finally { $img.Dispose() }
}

if ($heroes.success -and $heroes.data.Count -gt 0) {
    $f = Join-Path $RawDir "hero.png"
    Save-Url $heroes.data[0].url $f | Out-Null
    To-Bmp $f (Join-Path $OutDir "launcher-bg.bmp") 1920
} else {
    Write-Warning "[art] no hero art; the launcher will use its gradient background"
}

if ($logos.success -and $logos.data.Count -gt 0) {
    $f = Join-Path $RawDir "logo.png"
    Save-Url $logos.data[0].url $f | Out-Null
    To-Bmp $f (Join-Path $OutDir "launcher-logo.bmp") 620
}

if ($icons.success -and $icons.data.Count -gt 0) {
    $f = Join-Path $RawDir "icon.png"
    Save-Url $icons.data[0].url $f | Out-Null
    To-Bmp $f (Join-Path $OutDir "icon.bmp") 256
}

Write-Host "[art] done -> $OutDir"

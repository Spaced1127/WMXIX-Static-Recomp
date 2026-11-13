# Ask the running game to save a state right now.
#
# The runner watches <auto>\commands even while you play, so dropping a command
# file works mid-game. Default output: work\states\manual.state
param(
    [string]$Out = "H:\Projects\WWE WMXIIIV\work\states\manual.state"
)
$root = "H:\Projects\WWE WMXIIIV"
$auto = "$root\build\auto"
New-Item -ItemType Directory -Force -Path "$auto\commands","$auto\processed",(Split-Path $Out) | Out-Null

if (-not (Get-Process WMXIXRunner -ErrorAction SilentlyContinue)) {
    Write-Warning "The game is not running. Start it with Play.cmd first."
    exit 1
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss-fff"
$file  = Join-Path "$auto\commands" "savestate-$stamp.txt"
"command=save_state`npath=$Out" | Set-Content $file
Write-Host "Save requested -> $Out"
Write-Host "It is written on the next frame; give it a second."

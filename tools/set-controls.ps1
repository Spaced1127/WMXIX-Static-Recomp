# Install a GameCube pad binding for the port.
#
#   tools\set-controls.ps1                 # detect a pad, else keyboard
#   tools\set-controls.ps1 -Mode gamepad   # detect a pad, error if none
#   tools\set-controls.ps1 -Mode keyboard  # force keyboard
#   tools\set-controls.ps1 -List           # just show what the runtime sees
#
# Detection works by asking the runtime itself (MODERNGEKKO_INPUT_DEBUG=1),
# so the device string written to the ini is exactly one the runtime offers.
param(
    [ValidateSet("auto","gamepad","keyboard")]
    [string]$Mode = "auto",
    [switch]$List,
    [string]$UserDir = "H:\Projects\WWE WMXIIIV\work\user"
)
$ErrorActionPreference = 'Stop'
$root   = "H:\Projects\WWE WMXIIIV"
$runner = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\WMXIXRunner.exe"

if (-not (Test-Path $runner)) { throw "runner not built: $runner" }

function Get-InputDevices {
    $log = "$root\build\logs\device-probe.err"
    New-Item -ItemType Directory -Force -Path "$root\build\logs" | Out-Null
    $env:MODERNGEKKO_INPUT_DEBUG = "1"
    try {
        $p = Start-Process -FilePath $runner -PassThru -NoNewWindow `
            -ArgumentList "--game `"$root\work\game`" --user-dir `"$UserDir`" --graphics Vulkan --audio Null --allow-interpreter" `
            -RedirectStandardOutput "$root\build\logs\device-probe.out" `
            -RedirectStandardError $log
        Start-Sleep -Seconds 12
    } finally {
        if ($p -and -not $p.HasExited) { & taskkill /PID $p.Id /T /F 2>&1 | Out-Null }
        Remove-Item Env:\MODERNGEKKO_INPUT_DEBUG -ErrorAction SilentlyContinue
    }
    $devices = @()
    if (Test-Path $log) {
        $devices = Get-Content $log |
            Where-Object { $_ -match '^\[input\] device: (.+)$' } |
            ForEach-Object { $Matches[1] } |
            Sort-Object -Unique
    }
    return $devices
}

Write-Host "[controls] asking the runtime which input devices exist..."
$devices = Get-InputDevices
if (-not $devices) { Write-Warning "[controls] runtime reported no devices" }
foreach ($d in $devices) { Write-Host "  device: $d" }
if ($List) { return }

# Prefer SDL (normalised gamepad names, best button mapping), then XInput,
# then a DInput gamepad. Keyboard and mouse is the last resort.
$pad = $devices | Where-Object { $_ -like 'SDL/*' } | Select-Object -First 1
$kind = 'sdl'
if (-not $pad) {
    $pad = $devices | Where-Object { $_ -like 'XInput/*' } | Select-Object -First 1
    $kind = 'xinput'
}
if (-not $pad) {
    $pad = $devices | Where-Object { $_ -like 'DInput/*' -and $_ -notlike '*Keyboard Mouse*' } |
           Select-Object -First 1
    $kind = 'dinput'
}

if ($Mode -eq 'keyboard' -or (-not $pad)) {
    if ($Mode -eq 'gamepad') {
        throw "[controls] no gamepad found; attach one or use -Mode keyboard"
    }
    $src = "$root\controls\GCPadNew.keyboard.ini"
    $desc = "keyboard"
} else {
    switch ($kind) {
        'sdl'    { $src = "$root\controls\GCPadNew.sdl.ini" }
        'xinput' { $src = "$root\controls\GCPadNew.xinput.ini" }
        default  { $src = $null }
    }
    if (-not $src) {
        Write-Warning "[controls] '$pad' is a raw DirectInput pad; no template for it. Install keyboard bindings and map manually (docs/CONTROLS.md)."
        $src = "$root\controls\GCPadNew.keyboard.ini"
        $desc = "keyboard"
    } else {
        $desc = "$kind pad ($pad)"
    }
}

$dstDir = Join-Path $UserDir "Config"
New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
$dst = Join-Path $dstDir "GCPadNew.ini"
if ((Test-Path $dst) -and -not (Test-Path "$dst.bak")) { Copy-Item $dst "$dst.bak" }

$content = Get-Content $src -Raw
if ($src -notlike '*keyboard*') { $content = $content.Replace('{{DEVICE}}', $pad) }
Set-Content -Path $dst -Value $content -NoNewline
Write-Host "[controls] installed $desc -> $dst"

if ($desc -eq 'keyboard') {
    Write-Host ""
    Write-Host "  Move (main stick)  W A S D      D-Pad    Arrow keys"
    Write-Host "  A / B              SPACE / LSHIFT"
    Write-Host "  X / Y              E / Q        Z        R"
    Write-Host "  L / R              1 / 2        Start    Enter"
    Write-Host "  C stick            I J K L"
}

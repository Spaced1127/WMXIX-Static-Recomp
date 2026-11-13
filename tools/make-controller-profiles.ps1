# Generate the shipped GCPadNew.ini profiles.
#
# The mapping body is identical for every pad; only `Device =` and, for
# Nintendo pads, the A/B and X/Y labels change. SDL gives every modern pad a
# standard positional button set, so one body covers Xbox, PlayStation,
# Nintendo, Steam Deck and generic DirectInput pads.
param(
    [string]$OutDir = "H:\Projects\WWE WMXIIIV\docs\release\defaults"
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function New-PadProfile {
    param([string]$Device, [switch]$Nintendo, [switch]$MenuDpad)

    if ($Nintendo) { $a='Button B'; $b='Button A'; $x='Button Y'; $y='Button X' }
    else           { $a='Button A'; $b='Button B'; $x='Button X'; $y='Button Y' }

    $lines = @(
        '[GCPad1]'
        "Device = $Device"
        "Buttons/A = ``$a``"
        "Buttons/B = ``$b``"
        "Buttons/X = ``$x``"
        "Buttons/Y = ``$y``"
        'Buttons/Z = `Shoulder R`'
        'Buttons/Start = `Start`'
        'Main Stick/Up = `Pad N` | `Left Y+`'
        'Main Stick/Down = `Pad S` | `Left Y-`'
        'Main Stick/Left = `Pad W` | `Left X-`'
        'Main Stick/Right = `Pad E` | `Left X+`'
        'Main Stick/Calibration = 100.00'
        'C-Stick/Up = `Right Y+`'
        'C-Stick/Down = `Right Y-`'
        'C-Stick/Left = `Right X-`'
        'C-Stick/Right = `Right X+`'
        'C-Stick/Calibration = 100.00'
        'Triggers/L = `Trigger L`'
        'Triggers/R = `Trigger R`'
        'Triggers/L-Analog = `Trigger L`'
        'Triggers/R-Analog = `Trigger R`'
    )

    if ($MenuDpad) {
        $lines += @(
            'D-Pad/Up = `Pad N`'
            'D-Pad/Down = `Pad S`'
            'D-Pad/Left = `Pad W`'
            'D-Pad/Right = `Pad E`'
        )
    } else {
        $lines += @(
            'D-Pad/Up = `Pad N` & `Shoulder L`'
            'D-Pad/Down = `Pad S` & `Shoulder L`'
            'D-Pad/Left = `Pad W` & `Shoulder L`'
            'D-Pad/Right = `Pad E` & `Shoulder L`'
        )
    }
    $lines += 'Rumble/Motor = `Motor L` | `Motor R`'
    return ($lines -join "`r`n") + "`r`n"
}

$profiles = @(
    @{ File = 'GCPadNew.xbox.ini';           Device = 'SDL/0/Xbox Wireless Controller';      Nintendo = $false; Menu = $false },
    @{ File = 'GCPadNew.xbox-360.ini';       Device = 'SDL/0/Xbox 360 Controller';            Nintendo = $false; Menu = $false },
    @{ File = 'GCPadNew.xbox-series.ini';    Device = 'SDL/0/Xbox Series X Controller';       Nintendo = $false; Menu = $false },
    @{ File = 'GCPadNew.dualsense.ini';      Device = 'SDL/0/DualSense Wireless Controller';  Nintendo = $false; Menu = $false },
    @{ File = 'GCPadNew.dualsense-menu.ini'; Device = 'SDL/0/DualSense Wireless Controller';  Nintendo = $false; Menu = $true  },
    @{ File = 'GCPadNew.dualshock4.ini';     Device = 'SDL/0/Wireless Controller';            Nintendo = $false; Menu = $false },
    @{ File = 'GCPadNew.dualshock3.ini';     Device = 'SDL/0/PS3 Controller';                 Nintendo = $false; Menu = $false },
    @{ File = 'GCPadNew.switch-pro.ini';     Device = 'SDL/0/Nintendo Switch Pro Controller'; Nintendo = $true;  Menu = $false },
    @{ File = 'GCPadNew.joycon.ini';         Device = 'SDL/0/Joy-Con (L)';                    Nintendo = $true;  Menu = $true  },
    @{ File = 'GCPadNew.steam-deck.ini';     Device = 'SDL/0/Steam Virtual Gamepad';          Nintendo = $false; Menu = $true  },
    @{ File = 'GCPadNew.8bitdo.ini';         Device = 'SDL/0/8BitDo Pro 2';                   Nintendo = $false; Menu = $false },
    @{ File = 'GCPadNew.generic.ini';        Device = 'SDL/0/SDL Gamepad';                    Nintendo = $false; Menu = $true  },
    @{ File = 'GCPadNew.dinput.ini';         Device = 'DInput/0/USB Gamepad';                 Nintendo = $false; Menu = $true  }
)

foreach ($p in $profiles) {
    $text = New-PadProfile -Device $p.Device -Nintendo:$p.Nintendo -MenuDpad:$p.Menu
    Set-Content -Path (Join-Path $OutDir $p.File) -Value $text -Encoding ascii -NoNewline
    Write-Host "[profiles] $($p.File)"
}

$keyboard = @(
    '[GCPad1]'
    'Device = DInput/0/Keyboard Mouse'
    'Buttons/A = `SPACE`'
    'Buttons/B = `LSHIFT`'
    'Buttons/X = `E`'
    'Buttons/Y = `Q`'
    'Buttons/Z = `R`'
    'Buttons/Start = `RETURN`'
    'Triggers/L = `1`'
    'Triggers/R = `2`'
    'Main Stick/Up = `W`'
    'Main Stick/Down = `S`'
    'Main Stick/Left = `A`'
    'Main Stick/Right = `D`'
    'C-Stick/Up = `I`'
    'C-Stick/Down = `K`'
    'C-Stick/Left = `J`'
    'C-Stick/Right = `L`'
    'D-Pad/Up = `UP`'
    'D-Pad/Down = `DOWN`'
    'D-Pad/Left = `LEFT`'
    'D-Pad/Right = `RIGHT`'
)
Set-Content -Path (Join-Path $OutDir 'GCPadNew.keyboard.ini') -Value (($keyboard -join "`r`n") + "`r`n") -Encoding ascii -NoNewline
Write-Host "[profiles] GCPadNew.keyboard.ini"
Write-Host "[profiles] done -> $OutDir"

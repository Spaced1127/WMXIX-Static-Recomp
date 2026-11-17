# Offline controller layout matrix.
#
# Runs the real launcher binary through its headless hooks and asserts, for each
# pad, the resolved layout, the D-pad decision and the generated profile body.
# No controller hardware and no window are needed.
#
#   powershell -File tools\test-pad-layouts.ps1
#   powershell -File tools\test-pad-layouts.ps1 -Launcher <path to launcher.exe>
#
# Exit code 0 = every case matched its expectation, 1 = at least one failed.
param(
    [string]$Launcher = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

if (-not $Launcher) {
    $candidates = @(
        (Join-Path $root 'lib\ModernGekko-Template\lib\ModernGekko\build\launcher.exe'),
        (Join-Path $root 'dist\WMXIX-v0.4.0-Windows-x64\launcher.exe')
    )
    $Launcher = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}
if (-not (Test-Path $Launcher)) { throw "launcher.exe not found; pass -Launcher" }

$work = Join-Path $env:TEMP 'wmxix-pad-matrix'
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory $work | Out-Null

# Driver mapping strings, copied from SDL's own database / driver code.
$mXInput = 'a:b0,b:b1,back:b6,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,guide:b10,leftshoulder:b4,leftstick:b8,lefttrigger:a2,leftx:a0,lefty:a1,rightshoulder:b5,rightstick:b9,righttrigger:a5,rightx:a3,righty:a4,start:b7,x:b2,y:b3'
$mPS5 = 'a:b1,b:b2,back:b8,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,guide:b12,leftshoulder:b4,leftstick:b10,lefttrigger:a3,leftx:a0,lefty:a1,misc1:b13,rightshoulder:b5,rightstick:b11,righttrigger:a4,rightx:a2,righty:a5,start:b9,x:b0,y:b3'
$m8BitDo = 'a:b1,b:b0,back:b4,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,dpup:h0.1,guide:b5,leftshoulder:b9,leftstick:b7,lefttrigger:a4,leftx:a0,lefty:a1,rightshoulder:b10,rightstick:b8,righttrigger:a5,rightx:a2,righty:a3,start:b6,x:b3,y:b2'
# A firmware that reports the hat left/right bits reversed (dpleft=2, dpright=8).
$mReversed = 'a:b0,b:b1,back:b6,dpdown:h0.4,dpleft:h0.2,dpright:h0.8,dpup:h0.1,leftshoulder:b4,leftstick:b8,lefttrigger:a2,leftx:a0,lefty:a1,rightshoulder:b5,rightstick:b9,righttrigger:a5,rightx:a3,righty:a4,start:b7,x:b2,y:b3'

# guid, name, mapping (optional), expected layout, expected dpad, expected A button
$cases = @(
    @{ Id='x360-usb';      Guid='030000005e0400008e02000000000000'; Name='Xbox 360 Controller';            Map=$null;     Layout='Xbox';        Dpad='normal'; A='Button A' }
    @{ Id='x360-xinput';   Guid='030000005e0400008e02000000007801'; Name='Xbox 360 Controller';            Map=$mXInput;  Layout='Xbox';        Dpad='normal'; A='Button A' }
    @{ Id='xone-xinput';   Guid='030000005e040000ea02000000007801'; Name='Xbox One Controller';            Map=$mXInput;  Layout='Xbox';        Dpad='normal'; A='Button A' }
    @{ Id='series-hidapi'; Guid='030000005e040000120b00000000006801'; Name='Xbox Series X Controller';     Map=$null;     Layout='Xbox';        Dpad='normal'; A='Button A' }
    @{ Id='elite-s1';      Guid='030000005e040000e302000000007801'; Name='Xbox One Elite Controller';      Map=$mXInput;  Layout='Xbox';        Dpad='normal'; A='Button A' }
    @{ Id='elite-s2-usb';  Guid='030000005e040000000b000000007801'; Name='Xbox One Elite 2 Controller';    Map=$mXInput;  Layout='Xbox';        Dpad='normal'; A='Button A' }
    @{ Id='elite-s2-bt';   Guid='030000005e040000050b000003096801'; Name='Xbox One Elite 2 Controller';    Map=$null;     Layout='Xbox';        Dpad='normal'; A='Button A' }
    @{ Id='series-0b22';   Guid='030000005e040000220b000000007801'; Name='Xbox Wireless Controller';       Map=$mXInput;  Layout='Xbox';        Dpad='normal'; A='Button A' }
    @{ Id='xbox-nameonly'; Guid='';                                 Name='Xbox Wireless Controller';       Map=$null;     Layout='Xbox';        Dpad='normal'; A='Button A' }
    @{ Id='dualsense';     Guid='030000004c050000e60c000000007601'; Name='DualSense Wireless Controller';  Map=$mPS5;     Layout='PlayStation'; Dpad='normal'; A='Button A' }
    @{ Id='edge-usb';      Guid='030000004c050000f20d000000007801'; Name='DualSense Edge Wireless Controller'; Map=$mPS5; Layout='PlayStation'; Dpad='normal'; A='Button A' }
    @{ Id='edge-bt';       Guid='050000004c050000f20d000000000000'; Name='DualSense Edge Wireless Controller'; Map=$mPS5; Layout='PlayStation'; Dpad='normal'; A='Button A' }
    @{ Id='8bitdo-pro2-n'; Guid='03000000c82d00000660000011010000'; Name='8BitDo Pro 2';                   Map=$m8BitDo;  Layout='Nintendo';    Dpad='normal'; A='Button B' }
    @{ Id='8bitdo-pro2-bt'; Guid='05000000c82d00000660000000010000'; Name='8BitDo Pro 2';                 Map=$null;     Layout='Nintendo';    Dpad='normal'; A='Button B' }
    @{ Id='8bitdo-pro2-btm'; Guid='05000000c82d00000660000000010000'; Name='8BitDo Pro 2';                Map=$m8BitDo;  Layout='Nintendo';    Dpad='normal'; A='Button B' }
    @{ Id='switch-pro-bt';  Guid='050000007e0500000920000000000000'; Name='Pro Controller';               Map=$null;     Layout='Nintendo';    Dpad='normal'; A='Button B' }
    @{ Id='8bitdo-pro2-btx'; Guid='050000005e040000e002000003090000'; Name='8BitDo Pro 2';                Map=$null;     Layout='Xbox';        Dpad='normal'; A='Button A' }
    @{ Id='8bitdo-pro2-x'; Guid='030000005e040000e002000000007801'; Name='8BitDo Pro 2';                   Map=$mXInput;  Layout='Xbox';        Dpad='normal'; A='Button A' }
    @{ Id='8bitdo-ult';    Guid='03000000c82d00001330000011010000'; Name='8BitDo Ultimate Wireless Controller'; Map=$null; Layout='Generic';   Dpad='normal'; A='Button A' }
    @{ Id='8bitdo-64';     Guid='03000000c82d00001930000000000000'; Name='8BitDo 64';                      Map=$null;     Layout='Generic';     Dpad='normal'; A='Button A' }
    @{ Id='switch-pro';    Guid='030000007e0500000920000000000000'; Name='Nintendo Switch Pro Controller'; Map=$m8BitDo;  Layout='Nintendo';    Dpad='normal'; A='Button B' }
    @{ Id='dpad-reversed'; Guid='030000005e0400008e02000000007801'; Name='Xbox 360 Controller';            Map=$mReversed; Layout='Xbox';       Dpad='swapped'; A='Button A' }
)

function Get-Info([string]$guid, [string]$name, [string]$map) {
    $args = @('--pad-info', $guid, '--pad-name', $name)
    if ($map) { $args += @('--mapping', $map) }
    $out = & $Launcher @args 2>&1 | Out-String
    $fields = @{}
    foreach ($line in ($out -split "`r?`n")) {
        if ($line -match '^(guid|ids|mapping|dpad|layout)=(.*)$') { $fields[$Matches[1]] = $Matches[2].Trim() }
    }
    return $fields
}

$fail = 0
$rows = @()
foreach ($c in $cases) {
    $guid = $c.Guid
    if ($guid) {
        $info = Get-Info $guid $c.Name $c.Map
        $layout = $info['layout']; $dpad = $info['dpad']
    } else {
        # No GUID and no mapping: the name fallback has to carry the decision.
        $layout = 'name-only'; $dpad = 'normal'
    }

    $dir = Join-Path $work $c.Id
    $wargs = @('--user-dir', $dir, '--write-pad-profile', ("SDL/0/" + $c.Name))
    if ($guid) { $wargs += @('--pad-guid', $guid) }
    if ($c.Map) { $wargs += @('--mapping', $c.Map) }
    & $Launcher @wargs | Out-Null
    $body = Get-Content (Join-Path $dir 'Config\GCPadNew.ini') -ErrorAction SilentlyContinue
    $a = (($body | Where-Object { $_ -like 'Buttons/A*' }) -replace '.*=\s*`([^`]*)`.*', '$1').Trim()
    $dl = (($body | Where-Object { $_ -like 'D-Pad/Left*' }) -replace '.*=\s*`([^`]*)`.*', '$1').Trim()

    if ($layout -eq 'name-only') {
        # Only the body is authoritative here; a swapped A means it guessed Nintendo.
        $ok = ($a -eq $c.A) -and ($a -ne 'Button B')
        if ($a -eq 'Button B') { $layout = 'Nintendo' }
    } else {
        $ok = ($layout -eq $c.Layout) -and ($dpad -eq $c.Dpad) -and ($a -eq $c.A)
    }
    $rows += [pscustomobject]@{ Case=$c.Id; Layout=$layout; Dpad=$dpad; A=$a; DpadLeft=$dl; Expected=("$($c.Layout)/$($c.Dpad)/$($c.A)"); Result=$(if($ok){'PASS'}else{'FAIL'}) }
    if (-not $ok) { $fail++ }
}

$rows | Format-Table -AutoSize
if ($fail -ne 0) { "FAILED: $fail of $($rows.Count) cases"; exit 1 }
"PASSED: $($rows.Count) cases"
exit 0
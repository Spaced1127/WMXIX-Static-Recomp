# Probe input: press a key every few seconds while capturing a screenshot
# timeline, so a state change can be attributed to real keyboard input.
param(
    [int]$Total = 160,
    [int]$PressEvery = 6,
    [string]$Keys = "{ENTER}",
    [int[]]$ShotAt = @(60, 75, 90, 105, 120, 135, 150),
    [string]$Tag = "probe"
)
$root   = "H:\Projects\WWE WMXIIIV"
$runner = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\WMXIXRunner.exe"
$module =(Get-ChildItem "$root\build\modules\GW9E78" -Recurse -Filter "gGW9E78_recomp.dll" |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$auto   = "$root\build\auto"
New-Item -ItemType Directory -Force -Path $auto,"$auto\commands","$auto\processed","$root\build\logs" | Out-Null
Get-ChildItem "$auto\commands" -ErrorAction SilentlyContinue | Remove-Item -Force

$out = "$root\build\logs\$Tag.out"
$err = "$root\build\logs\$Tag.err"
$argLine = @(
    "--game", "`"$root\work\game`"", "--module", "`"$module`"",
    "--user-dir","`"$root\work\user`"", "--automation-dir", "`"$auto`"",
    "--graphics","Vulkan","--audio","Null","--allow-interpreter"
) -join " "

Add-Type -AssemblyName System.Windows.Forms
$sig = @'
using System;
using System.Runtime.InteropServices;
public class Win2 {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int n);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
}
'@
Add-Type -TypeDefinition $sig -ErrorAction SilentlyContinue

Write-Host "[probe] start"
$p = Start-Process -FilePath $runner -PassThru -NoNewWindow -ArgumentList $argLine `
     -RedirectStandardOutput $out -RedirectStandardError $err

$wshell = New-Object -ComObject WScript.Shell
$nextPress = $PressEvery
$nextShot  = 0
for ($t = 1; $t -le $Total; $t++) {
    Start-Sleep -Seconds 1
    if ($p.HasExited) { Write-Host "[probe] exited at ${t}s"; break }

    if ($t -ge $nextPress) {
        $wshell.AppActivate($p.Id) | Out-Null
        Start-Sleep -Milliseconds 150
        [System.Windows.Forms.SendKeys]::SendWait($Keys)
        Write-Host "[probe] t=${t}s pressed $Keys"
        $nextPress += $PressEvery
    }
    if ($nextShot -lt $ShotAt.Count -and $t -ge $ShotAt[$nextShot]) {
        $png = "$root\build\logs\$Tag-$t.png"
        "command=screenshot`npath=$png" | Set-Content "$auto\commands\shot$t.txt"
        Write-Host "[probe] t=${t}s screenshot -> $png"
        $nextShot++
    }
}

"command=stop" | Set-Content "$auto\commands\stop.txt"
Start-Sleep -Seconds 6
if (-not $p.HasExited) { & taskkill /PID $p.Id /T /F 2>&1 | Out-Null }
Write-Host "[probe] done"

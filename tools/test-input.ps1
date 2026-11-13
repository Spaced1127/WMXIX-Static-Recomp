# Prove keyboard input reaches the game: boot to a known screen, focus the
# window, send a key sequence, capture before/after screenshots.
param(
    [int]$BootSeconds = 72,
    [string]$Keys = "{ENTER}",
    [string]$Tag = "input"
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

Write-Host "[input] booting for ${BootSeconds}s"
$p = Start-Process -FilePath $runner -PassThru -NoNewWindow -ArgumentList $argLine `
     -RedirectStandardOutput $out -RedirectStandardError $err
Start-Sleep -Seconds $BootSeconds

$before = "$root\build\logs\$Tag-before.png"
"command=screenshot`npath=$before" | Set-Content "$auto\commands\shot-before.txt"
Start-Sleep -Seconds 3

Add-Type -AssemblyName System.Windows.Forms
$sig = @'
using System;
using System.Runtime.InteropServices;
public class Win {
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int n);
}
'@
Add-Type -TypeDefinition $sig -ErrorAction SilentlyContinue
$h = $p.MainWindowHandle
Write-Host "[input] window: $h '$($p.MainWindowTitle)'"
if ($h -ne [IntPtr]::Zero) { [Win]::ShowWindow($h, 9) | Out-Null; [Win]::SetForegroundWindow($h) | Out-Null }
Start-Sleep -Seconds 2

Write-Host "[input] sending: $Keys"
foreach ($k in ($Keys -split ';')) {
    [System.Windows.Forms.SendKeys]::SendWait($k)
    Start-Sleep -Milliseconds 900
}
Start-Sleep -Seconds 4

$after = "$root\build\logs\$Tag-after.png"
"command=screenshot`npath=$after" | Set-Content "$auto\commands\shot-after.txt"
Start-Sleep -Seconds 4

Write-Host "[input] status:"
if (Test-Path "$auto\status.txt") { Get-Content "$auto\status.txt" | Where-Object { $_ -match '^(fps|frame_count|state)=' } }
"command=stop" | Set-Content "$auto\commands\stop.txt"
Start-Sleep -Seconds 6
if (-not $p.HasExited) { & taskkill /PID $p.Id /T /F 2>&1 | Out-Null }
Write-Host "[input] before=$((Test-Path $before)) after=$((Test-Path $after))"

# Send a REAL held key (down, hold, up) instead of SendKeys' instant tap, then
# screenshot. A 1 ms tap can fall between 60 Hz pad polls and be missed.
param(
    [int]$BootSeconds = 75,
    [string]$Key = "RETURN",
    [int]$HoldMs = 200,
    [int]$Repeat = 1,
    [int]$GapMs = 800,
    [string]$Tag = "hold"
)
$root   = "H:\Projects\WWE WMXIIIV"
$runner = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\WMXIXRunner.exe"
$module =(Get-ChildItem "$root\build\modules\GW9E78" -Recurse -Filter "gGW9E78_recomp.dll" |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$auto   = "$root\build\auto"
New-Item -ItemType Directory -Force -Path $auto,"$auto\commands","$auto\processed","$root\build\logs" | Out-Null
Get-ChildItem "$auto\commands" -ErrorAction SilentlyContinue | Remove-Item -Force

$sig = @'
using System;
using System.Runtime.InteropServices;
public class Kb {
  [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int n);
}
'@
Add-Type -TypeDefinition $sig -ErrorAction SilentlyContinue

$out = "$root\build\logs\$Tag.out"
$err = "$root\build\logs\$Tag.err"
$argLine = @(
    "--game", "`"$root\work\game`"", "--module", "`"$module`"",
    "--user-dir","`"$root\work\user`"", "--automation-dir", "`"$auto`"",
    "--graphics","Vulkan","--audio","Null","--allow-interpreter"
) -join " "

Write-Host "[hold] booting ${BootSeconds}s"
$p = Start-Process -FilePath $runner -PassThru -NoNewWindow -ArgumentList $argLine `
     -RedirectStandardOutput $out -RedirectStandardError $err
Start-Sleep -Seconds $BootSeconds

$before = "$root\build\logs\$Tag-before.png"
"command=screenshot`npath=$before" | Set-Content "$auto\commands\shot-b.txt"
Start-Sleep -Seconds 3

$vk = [int][char]$Key
if ($Key -eq "RETURN") { $vk = 0x0D }
if ($Key -eq "SPACE")  { $vk = 0x20 }
Write-Host "[hold] window=$($p.MainWindowHandle) vk=0x$('{0:X2}' -f $vk)"
if ($p.MainWindowHandle -ne [IntPtr]::Zero) {
    [Kb]::ShowWindow($p.MainWindowHandle, 9) | Out-Null
    [Kb]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
}
Start-Sleep -Seconds 1

for ($i = 0; $i -lt $Repeat; $i++) {
    Write-Host "[hold] press $($i+1)/$Repeat hold ${HoldMs}ms"
    [Kb]::keybd_event([byte]$vk, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds $HoldMs
    [Kb]::keybd_event([byte]$vk, 0, 2, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds $GapMs
}
Start-Sleep -Seconds 3

$after = "$root\build\logs\$Tag-after.png"
"command=screenshot`npath=$after" | Set-Content "$auto\commands\shot-a.txt"
Start-Sleep -Seconds 4

Write-Host "[hold] status:"
if (Test-Path "$auto\status.txt") { Get-Content "$auto\status.txt" | Where-Object { $_ -match '^(fps|frame_count|state)=' } }
"command=stop" | Set-Content "$auto\commands\stop.txt"
Start-Sleep -Seconds 6
if (-not $p.HasExited) { & taskkill /PID $p.Id /T /F 2>&1 | Out-Null }

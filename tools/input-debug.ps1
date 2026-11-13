# Diagnostic: run with MODERNGEKKO_INPUT_DEBUG=1, send real held keys, and print
# every pad-state change the guest sees.
param(
    [int]$BootSeconds = 25,
    [int]$HoldMs = 250,
    [string]$Tag = "iodebug"
)
$root   = "H:\Projects\WWE WMXIIIV"
$runner = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\WMXIXRunner.exe"
$module =(Get-ChildItem "$root\build\modules\GW9E78" -Recurse -Filter "gGW9E78_recomp.dll" |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$err = "$root\build\logs\$Tag.err"
$out = "$root\build\logs\$Tag.out"

$sig = @'
using System;
using System.Runtime.InteropServices;
public class Kb2 {
  [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int n);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
}
'@
Add-Type -TypeDefinition $sig -ErrorAction SilentlyContinue

$env:MODERNGEKKO_INPUT_DEBUG = "1"
$argLine = @(
    "--game", "`"$root\work\game`"", "--module", "`"$module`"",
    "--user-dir","`"$root\work\user`"",
    "--graphics","Vulkan","--audio","Null","--allow-interpreter"
) -join " "

Write-Host "[iodebug] start, boot ${BootSeconds}s"
$p = Start-Process -FilePath $runner -PassThru -NoNewWindow -ArgumentList $argLine `
     -RedirectStandardOutput $out -RedirectStandardError $err
Start-Sleep -Seconds $BootSeconds

Write-Host "[iodebug] window=$($p.MainWindowHandle)"
if ($p.MainWindowHandle -ne [IntPtr]::Zero) {
    [Kb2]::ShowWindow($p.MainWindowHandle, 9) | Out-Null
    [Kb2]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
}
Start-Sleep -Seconds 1
Write-Host "[iodebug] foreground now: $([Kb2]::GetForegroundWindow()) (game=$($p.MainWindowHandle))"

foreach ($vk in @(0x0D, 0x20, 0x41)) {
    Write-Host "[iodebug] key 0x$('{0:X2}' -f $vk) down"
    [Kb2]::keybd_event([byte]$vk, 0, 0, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds $HoldMs
    [Kb2]::keybd_event([byte]$vk, 0, 2, [UIntPtr]::Zero)
    Start-Sleep -Milliseconds 1200
}

Start-Sleep -Seconds 2
if (-not $p.HasExited) { & taskkill /PID $p.Id /T /F 2>&1 | Out-Null }
Remove-Item Env:\MODERNGEKKO_INPUT_DEBUG
Start-Sleep -Seconds 1

Write-Host "===== pad changes seen by the guest ====="
if (Test-Path $err) {
    $lines = Get-Content $err | Where-Object { $_ -match '^\[input\]' }
    if ($lines) { $lines } else { "(none - the binding never fired)" }
}

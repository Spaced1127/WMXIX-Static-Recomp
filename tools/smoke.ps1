# Headless smoke test: run for N seconds, kill the process tree, print the log.
param(
    [int]$Seconds = 45,
    [string]$Tag = "smoke"
)
$root   = "H:\Projects\WWE WMXIIIV"
$runner = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\WMXIXRunner.exe"
$active = "$root\build\modules\GW9E78\active-module.txt"
$module = if (Test-Path $active) { (Get-Content $active -Raw).Trim() } else { $null }
if (-not $module) {
    $module = (Get-ChildItem "$root\build\modules\GW9E78" -Recurse -Filter "gGW9E78_recomp.dll" |
               Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
}

New-Item -ItemType Directory -Force -Path "$root\build\logs" | Out-Null
$out = "$root\build\logs\$Tag.out"
$err = "$root\build\logs\$Tag.err"
Remove-Item $out,$err -ErrorAction SilentlyContinue

Write-Host "[smoke] module: $module"
$argLine = @(
    "--game",    "`"$root\work\game`"",
    "--module",  "`"$module`"",
    "--user-dir","`"$root\work\user`"",
    "--headless",
    "--graphics","Null",
    "--audio",   "Null",
    "--allow-interpreter"
) -join " "
$p = Start-Process -FilePath $runner -PassThru -NoNewWindow -ArgumentList $argLine `
     -RedirectStandardOutput $out -RedirectStandardError $err

Start-Sleep -Seconds $Seconds
if (-not $p.HasExited) {
    Write-Host "[smoke] still running after ${Seconds}s - stopping"
    & taskkill /PID $p.Id /T /F 2>&1 | Out-Null
} else {
    Write-Host "[smoke] exited early with code $($p.ExitCode)"
}
Start-Sleep -Seconds 2

Write-Host "===== stdout ====="
if (Test-Path $out) { Get-Content $out -Tail 80 }
Write-Host "===== stderr ====="
if (Test-Path $err) { Get-Content $err -Tail 40 }

# Run the port headless with the automation protocol, wait, then dump status.txt.
param(
    [int]$Seconds = 40,
    [string]$Tag = "auto"
)
$root   = "H:\Projects\WWE WMXIIIV"
$runner = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\WMXIXRunner.exe"
$module = (Get-ChildItem "$root\build\modules\GW9E78" -Recurse -Filter "gGW9E78_recomp.dll" |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$auto   = "$root\build\auto"
New-Item -ItemType Directory -Force -Path $auto,"$root\build\logs" | Out-Null
Remove-Item "$auto\status.txt" -ErrorAction SilentlyContinue

$out = "$root\build\logs\$Tag.out"
$err = "$root\build\logs\$Tag.err"
$argLine = @(
    "--game",    "`"$root\work\game`"",
    "--module",  "`"$module`"",
    "--user-dir","`"$root\work\user`"",
    "--automation-dir", "`"$auto`"",
    "--headless",
    "--graphics","Null",
    "--audio",   "Null",
    "--allow-interpreter"
) -join " "

Write-Host "[auto] starting for ${Seconds}s"
$p = Start-Process -FilePath $runner -PassThru -NoNewWindow -ArgumentList $argLine `
     -RedirectStandardOutput $out -RedirectStandardError $err

Start-Sleep -Seconds $Seconds
$running = -not $p.HasExited
if ($running) { & taskkill /PID $p.Id /T /F 2>&1 | Out-Null }
Start-Sleep -Seconds 2

Write-Host "[auto] still-running=$running"
Write-Host "===== status.txt ====="
if (Test-Path "$auto\status.txt") { Get-Content "$auto\status.txt" } else { "(none)" }
Write-Host "===== stderr ====="
if (Test-Path $err) { Get-Content $err -Tail 40 }
Write-Host "===== stdout ====="
if (Test-Path $out) { Get-Content $out -Tail 40 }

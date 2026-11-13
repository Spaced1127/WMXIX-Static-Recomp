# Run with no --module so the runtime uses its Dolphin-derived JIT core.
# This is the reference baseline for the static module.
param([int]$Seconds = 30, [string]$Tag = "jit")
$root   = "H:\Projects\WWE WMXIIIV"
$runner = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\WMXIXRunner.exe"
$auto   = "$root\build\auto-jit"
New-Item -ItemType Directory -Force -Path $auto,"$auto\commands","$auto\processed","$root\build\logs" | Out-Null
Get-ChildItem "$auto\commands" -ErrorAction SilentlyContinue | Remove-Item -Force
Remove-Item "$auto\status.txt" -ErrorAction SilentlyContinue

$out = "$root\build\logs\$Tag.out"
$err = "$root\build\logs\$Tag.err"
$argLine = @(
    "--game",    "`"$root\work\game`"",
    "--user-dir","`"$root\work\user-jit`"",
    "--automation-dir", "`"$auto`"",
    "--headless", "--graphics","Null","--audio","Null","--allow-interpreter"
) -join " "

Write-Host "[jit] starting for ${Seconds}s (no static module)"
$p = Start-Process -FilePath $runner -PassThru -NoNewWindow -ArgumentList $argLine `
     -RedirectStandardOutput $out -RedirectStandardError $err
Start-Sleep -Seconds $Seconds
$running = -not $p.HasExited
"command=stop" | Set-Content "$auto\commands\stop.txt"
Start-Sleep -Seconds 8
if (-not $p.HasExited) { & taskkill /PID $p.Id /T /F 2>&1 | Out-Null }
Start-Sleep -Seconds 1

Write-Host "[jit] still-running=$running"
Write-Host "===== status ====="
if (Test-Path "$auto\status.txt") { Get-Content "$auto\status.txt" | Select-Object -First 8 }
Write-Host "===== stderr ====="
if (Test-Path $err) { Get-Content $err -Tail 12 }

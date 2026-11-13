# Run headless with dispatch sampling, stop cleanly, print the hot PCs.
param([int]$Seconds = 30, [string]$Tag = "samples", [string]$Module = "", [string]$State = "")
$root   = "H:\Projects\WWE WMXIIIV"
$runner = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\WMXIXRunner.exe"
if (-not $Module) {
    $Module = (Get-ChildItem "$root\build\modules\GW9E78" -Recurse -Filter "gGW9E78_recomp.dll" |
               Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
}
$auto   = "$root\build\auto"
New-Item -ItemType Directory -Force -Path $auto,"$auto\commands","$auto\processed","$root\build\logs" | Out-Null
Get-ChildItem "$auto\commands" -ErrorAction SilentlyContinue | Remove-Item -Force
Remove-Item "$auto\status.txt" -ErrorAction SilentlyContinue

$out = "$root\build\logs\$Tag.out"
$err = "$root\build\logs\$Tag.err"
$load = if ($State) { "--load-state `"$State`"" } else { "" }
$argLine = @(
    "--game",    "`"$root\work\game`"",
    "--module",  "`"$Module`"",
    "--user-dir","`"$root\work\user`"",
    "--automation-dir", "`"$auto`"",
    "--headless", "--graphics","Null","--audio","Null","--allow-interpreter", $load
) -join " "

$env:STATICRECOMP_DISPATCH_SAMPLES = "1"
$p = Start-Process -FilePath $runner -PassThru -NoNewWindow -ArgumentList $argLine `
     -RedirectStandardOutput $out -RedirectStandardError $err
Start-Sleep -Seconds $Seconds
"command=stop" | Set-Content "$auto\commands\stop.txt"
Start-Sleep -Seconds 8
if (-not $p.HasExited) { & taskkill /PID $p.Id /T /F 2>&1 | Out-Null }
Start-Sleep -Seconds 1
Remove-Item Env:\STATICRECOMP_DISPATCH_SAMPLES

Write-Host "===== status ====="
if (Test-Path "$auto\status.txt") { Get-Content "$auto\status.txt" | Select-Object -First 8 }
Write-Host "===== dispatch samples ====="
Get-Content $err | Select-String -Pattern "staticrecomp" | ForEach-Object { $_.Line }

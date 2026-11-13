# Boot with a real graphics backend, capture a screenshot via the automation
# protocol, then stop cleanly.
param(
    [int]$BootSeconds = 35,
    [string]$Graphics = "Vulkan",
    [string]$Tag = "shot"
)
$root   = "H:\Projects\WWE WMXIIIV"
$runner = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\WMXIXRunner.exe"
$module = (Get-ChildItem "$root\build\modules\GW9E78" -Recurse -Filter "gGW9E78_recomp.dll" |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$auto   = "$root\build\auto"
$shot   = "$root\build\logs\$Tag.png"
New-Item -ItemType Directory -Force -Path $auto,"$auto\commands","$auto\processed","$root\build\logs" | Out-Null
Remove-Item "$auto\status.txt",$shot -ErrorAction SilentlyContinue
Get-ChildItem "$auto\commands" -ErrorAction SilentlyContinue | Remove-Item -Force

$out = "$root\build\logs\$Tag.out"
$err = "$root\build\logs\$Tag.err"
$argLine = @(
    "--game",    "`"$root\work\game`"",
    "--module",  "`"$module`"",
    "--user-dir","`"$root\work\user`"",
    "--automation-dir", "`"$auto`"",
    "--graphics", $Graphics,
    "--audio",   "Null",
    "--allow-interpreter"
) -join " "

Write-Host "[shot] starting ($Graphics) for ${BootSeconds}s"
$p = Start-Process -FilePath $runner -PassThru -NoNewWindow -ArgumentList $argLine `
     -RedirectStandardOutput $out -RedirectStandardError $err

Start-Sleep -Seconds $BootSeconds
if ($p.HasExited) {
    Write-Host "[shot] exited early code=$($p.ExitCode)"
} else {
    Write-Host "[shot] requesting screenshot"
    "command=screenshot`npath=$shot" | Set-Content "$auto\commands\shot.txt"
    Start-Sleep -Seconds 6
    Write-Host "[shot] status:"
    if (Test-Path "$auto\status.txt") { Get-Content "$auto\status.txt" | Select-Object -First 12 }
    "command=stop" | Set-Content "$auto\commands\stop.txt"
    Start-Sleep -Seconds 5
    if (-not $p.HasExited) { & taskkill /PID $p.Id /T /F 2>&1 | Out-Null }
}
Write-Host "[shot] png exists: $(Test-Path $shot)"
Write-Host "===== stderr ====="
if (Test-Path $err) { Get-Content $err -Tail 30 }

# Prove the GAME accepts pad input by injecting it through the automation
# protocol (bypasses the host keyboard/DInput path entirely).
param(
    [int]$Total = 150,
    [int]$PressEvery = 5,
    [string]$Button = "start",
    [int[]]$ShotAt = @(80, 95, 110, 125, 140),
    [string]$Tag = "padprobe"
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

Write-Host "[padprobe] start"
$p = Start-Process -FilePath $runner -PassThru -NoNewWindow -ArgumentList $argLine `
     -RedirectStandardOutput $out -RedirectStandardError $err

$nextPress = $PressEvery
$nextShot = 0
$n = 0
for ($t = 1; $t -le $Total; $t++) {
    Start-Sleep -Seconds 1
    if ($p.HasExited) { Write-Host "[padprobe] exited at ${t}s"; break }
    if ($t -ge $nextPress) {
        $n++
        "command=pad_frames`nport=1`nframes=6`n$Button=1" | Set-Content "$auto\commands\press$n.txt"
        Write-Host "[padprobe] t=${t}s $Button press #$n"
        $nextPress += $PressEvery
    }
    if ($nextShot -lt $ShotAt.Count -and $t -ge $ShotAt[$nextShot]) {
        "command=screenshot`npath=$root\build\logs\$Tag-$t.png" | Set-Content "$auto\commands\shot$t.txt"
        Write-Host "[padprobe] t=${t}s screenshot"
        $nextShot++
    }
}
"command=stop" | Set-Content "$auto\commands\stop.txt"
Start-Sleep -Seconds 6
if (-not $p.HasExited) { & taskkill /PID $p.Id /T /F 2>&1 | Out-Null }
Write-Host "[padprobe] done"

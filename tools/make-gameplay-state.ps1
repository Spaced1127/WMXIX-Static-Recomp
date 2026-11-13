# Drive the game from boot into a match using automation pad input, then save a
# state there. A gameplay state makes A/B performance runs short and repeatable.
param(
    [int]$PressFrom = 65,
    [int]$PressTo = 115,
    [int]$PressEvery = 5,
    [int]$SaveAt = 140,
    [string]$Out = "H:\Projects\WWE WMXIIIV\work\states\gameplay.state"
)
$root   = "H:\Projects\WWE WMXIIIV"
$runner = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\WMXIXRunner.exe"
$module =(Get-ChildItem "$root\build\modules\GW9E78" -Recurse -Filter "gGW9E78_recomp.dll" |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$auto   = "$root\build\auto"
New-Item -ItemType Directory -Force -Path $auto,"$auto\commands","$auto\processed",(Split-Path $Out) | Out-Null
Get-ChildItem "$auto\commands" -ErrorAction SilentlyContinue | Remove-Item -Force
Remove-Item $Out -ErrorAction SilentlyContinue

$stdoutLog = "$root\build\logs\gpstate.out"
$err = "$root\build\logs\gpstate.err"
$argLine = @(
    "--game", "`"$root\work\game`"", "--module", "`"$module`"",
    "--user-dir","`"$root\work\user`"", "--automation-dir", "`"$auto`"",
    "--graphics","Vulkan","--audio","Null","--allow-interpreter"
) -join " "

Write-Host "[gp] boot"
$p = Start-Process -FilePath $runner -PassThru -NoNewWindow -ArgumentList $argLine `
     -RedirectStandardOutput $stdoutLog -RedirectStandardError $err

$n = 0
for ($t = 1; $t -le $SaveAt; $t++) {
    Start-Sleep -Seconds 1
    if ($p.HasExited) { Write-Host "[gp] exited at ${t}s"; break }

    if ($t -ge $PressFrom -and $t -le $PressTo -and (($t - $PressFrom) % $PressEvery) -eq 0) {
        $n++
        "command=pad_frames`nport=1`nframes=6`nstart=1" | Set-Content "$auto\commands\press$n.txt"
        Write-Host "[gp] t=${t}s START #$n"
    }
    if ($t -eq ($SaveAt - 12)) {
        "command=screenshot`npath=$root\build\logs\gp-before-save.png" | Set-Content "$auto\commands\shotA.txt"
        Write-Host "[gp] t=${t}s screenshot"
    }
    if ($t -eq $SaveAt) {
        "command=save_state`npath=$Out" | Set-Content "$auto\commands\save.txt"
        Write-Host "[gp] t=${t}s save_state"
    }
}
Start-Sleep -Seconds 10
if (Test-Path "$auto\status.txt") {
    Get-Content "$auto\status.txt" | Where-Object { $_ -match '^(state|fps|frame_count|last_command|last_error)=' }
}
"command=stop" | Set-Content "$auto\commands\stop.txt"
Start-Sleep -Seconds 6
if (-not $p.HasExited) { & taskkill /PID $p.Id /T /F 2>&1 | Out-Null }
Write-Host "[gp] state written=$((Test-Path $Out))"
if (Test-Path $Out) { Get-Item $Out | Select-Object FullName,Length }

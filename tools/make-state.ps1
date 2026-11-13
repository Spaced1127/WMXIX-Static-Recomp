# Boot, wait for the game to settle, then save a runtime state so later runs
# can start instantly with --load-state.
param(
    [int]$BootSeconds = 115,
    [string]$Out = "H:\Projects\WWE WMXIIIV\work\states\menu.state"
)
$root   = "H:\Projects\WWE WMXIIIV"
$runner = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\WMXIXRunner.exe"
$module =(Get-ChildItem "$root\build\modules\GW9E78" -Recurse -Filter "gGW9E78_recomp.dll" |
          Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$auto   = "$root\build\auto"
New-Item -ItemType Directory -Force -Path $auto,"$auto\commands","$auto\processed",(Split-Path $Out) | Out-Null
Get-ChildItem "$auto\commands" -ErrorAction SilentlyContinue | Remove-Item -Force
Remove-Item $Out -ErrorAction SilentlyContinue

$byte = "$root\build\logs\state.out"
$berr = "$root\build\logs\state.err"
$argLine = @(
    "--game", "`"$root\work\game`"", "--module", "`"$module`"",
    "--user-dir","`"$root\work\user`"", "--automation-dir", "`"$auto`"",
    "--graphics","Vulkan","--audio","Null","--allow-interpreter"
) -join " "

Write-Host "[state] booting ${BootSeconds}s"
$p = Start-Process -FilePath $runner -PassThru -NoNewWindow -ArgumentList $argLine `
     -RedirectStandardOutput $byte -RedirectStandardError $berr
Start-Sleep -Seconds $BootSeconds

Write-Host "[state] requesting save_state -> $Out"
"command=save_state`npath=$Out" | Set-Content "$auto\commands\save-state.txt"
Start-Sleep -Seconds 8

if (Test-Path "$auto\status.txt") {
    Write-Host "[state] status:"
    Get-Content "$auto\status.txt" | Where-Object { $_ -match '^(state|fps|frame_count|last_error|last_command)=' }
}
"command=stop" | Set-Content "$auto\commands\stop.txt"
Start-Sleep -Seconds 6
if (-not $p.HasExited) { & taskkill /PID $p.Id /T /F 2>&1 | Out-Null }
Write-Host "[state] written=$((Test-Path $Out))"
if (Test-Path $Out) { Get-Item $Out | Select-Object FullName,Length }

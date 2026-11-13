# Load a state, let it run N seconds, then save a new state and screenshot.
param(
    [string]$In  = "H:\Projects\WWE WMXIIIV\work\states\gameplay.state",
    [string]$Out = "H:\Projects\WWE WMXIIIV\work\states\match.state",
    [int]$Seconds = 45
)
$root   = "H:\Projects\WWE WMXIIIV"
$runner = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\WMXIXRunner.exe"
$module =(Get-Content "$root\build\modules\GW9E78\active-module.txt" -Raw).Trim()
$auto   = "$root\build\auto"
New-Item -ItemType Directory -Force -Path $auto,"$auto\commands","$auto\processed" | Out-Null
Get-ChildItem "$auto\commands" -ErrorAction SilentlyContinue | Remove-Item -Force
Remove-Item $Out -ErrorAction SilentlyContinue

$stdout = "$root\build\logs\advance.out"
$err    = "$root\build\logs\advance.err"
$argLine = "--game `"$root\work\game`" --module `"$module`" --user-dir `"$root\work\user`" " +
           "--automation-dir `"$auto`" --graphics Vulkan --audio Null --allow-interpreter " +
           "--load-state `"$In`""

Write-Host "[adv] load state, run ${Seconds}s"
$p = Start-Process -FilePath $runner -PassThru -NoNewWindow -ArgumentList $argLine `
     -RedirectStandardOutput $stdout -RedirectStandardError $err
Start-Sleep -Seconds ($Seconds - 6)
"command=screenshot`npath=$root\build\logs\advance.png" | Set-Content "$auto\commands\shot.txt"
Start-Sleep -Seconds 4
"command=save_state`npath=$Out" | Set-Content "$auto\commands\save.txt"
Start-Sleep -Seconds 6
if (Test-Path "$auto\status.txt") { Get-Content "$auto\status.txt" | Where-Object { $_ -match '^(fps|frame_count|last_error)=' } }
"command=stop" | Set-Content "$auto\commands\stop.txt"
Start-Sleep -Seconds 5
if (-not $p.HasExited) { & taskkill /PID $p.Id /T /F 2>&1 | Out-Null }
Write-Host "[adv] written=$((Test-Path $Out))"
if (Test-Path $Out) { Get-Item $Out | Select-Object FullName,Length }

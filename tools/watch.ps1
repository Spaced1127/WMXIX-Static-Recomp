# Boot with Vulkan and capture a series of screenshots over time.
param(
    [string]$Graphics = "Vulkan",
    [int[]]$At = @(20, 45, 75, 105, 135),
    [string]$Tag = "watch"
)
$root   = "H:\Projects\WWE WMXIIIV"
$runner = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\WMXIXRunner.exe"
$module = (Get-ChildItem "$root\build\modules\GW9E78" -Recurse -Filter "gGW9E78_recomp.dll" |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
$auto   = "$root\build\auto"
New-Item -ItemType Directory -Force -Path $auto,"$auto\commands","$auto\processed","$root\build\logs" | Out-Null
Get-ChildItem "$auto\commands" -ErrorAction SilentlyContinue | Remove-Item -Force
Remove-Item "$auto\status.txt" -ErrorAction SilentlyContinue

$out = "$root\build\logs\$Tag.out"
$err = "$root\build\logs\$Tag.err"
$argLine = @(
    "--game", "`"$root\work\game`"", "--module", "`"$module`"",
    "--user-dir","`"$root\work\user`"", "--automation-dir", "`"$auto`"",
    "--graphics", $Graphics, "--audio","Null", "--allow-interpreter"
) -join " "

Write-Host "[watch] starting"
$p = Start-Process -FilePath $runner -PassThru -NoNewWindow -ArgumentList $argLine `
     -RedirectStandardOutput $out -RedirectStandardError $err

$last = 0
foreach ($t in $At) {
    Start-Sleep -Seconds ($t - $last); $last = $t
    if ($p.HasExited) { Write-Host "[watch] exited early at ${t}s"; break }
    $png = "$root\build\logs\$Tag-$t.png"
    "command=screenshot`npath=$png" | Set-Content "$auto\commands\shot$t.txt"
    Start-Sleep -Seconds 3
    $st = if (Test-Path "$auto\status.txt") { (Get-Content "$auto\status.txt" | Where-Object { $_ -match '^(fps|vps|frame_count|present_count|state)=' }) -join ' ' } else { '' }
    Write-Host "[watch] t=${t}s $st"
}

"command=stop" | Set-Content "$auto\commands\stop.txt"
Start-Sleep -Seconds 8
if (-not $p.HasExited) { & taskkill /PID $p.Id /T /F 2>&1 | Out-Null }
Start-Sleep -Seconds 1
Write-Host "===== stderr ====="
if (Test-Path $err) { Get-Content $err -Tail 10 }

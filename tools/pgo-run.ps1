# Collect a PGO profile from real gameplay.
#
# moderngekko-port pgo-run builds an instrumented module, runs the game, merges
# the .profraw files and rebuilds with -fprofile-use. This wrapper supplies the
# gameplay (from a save state) and stops the run cleanly so the profile flushes.
param(
    [string]$State = "H:\Projects\WWE WMXIIIV\work\states\user-match.state",
    [int]$PlaySeconds = 75,
    [string]$ProfileDir = "H:\Projects\WWE WMXIIIV\build\pgo",
    [string]$Tag = "pgo"
)
$ErrorActionPreference = 'Continue'
$root   = "H:\Projects\WWE WMXIIIV"
$port   = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\moderngekko-port.exe"
$profdata = "C:\Program Files\LLVM\bin\llvm-profdata.exe"
$auto   = "$root\build\auto-pgo"

New-Item -ItemType Directory -Force -Path $auto,"$auto\commands","$auto\processed",$ProfileDir,"$root\build\logs" | Out-Null
Get-ChildItem "$auto\commands" -ErrorAction SilentlyContinue | Remove-Item -Force

$log = "$root\build\logs\$Tag.log"
$argLine = @(
    "pgo-run", "`"$root\work\game`"",
    "--backend", "c",
    "--toolchain", "clang",
    "--opt-level", "3",
    "--output", "`"$root\build\modules`"",
    "--profile-dir", "`"$ProfileDir`"",
    "--llvm-profdata", "`"$profdata`"",
    "--",
    "--user-dir", "`"$root\work\user`"",
    "--automation-dir", "`"$auto`"",
    "--graphics", "Vulkan",
    "--audio", "Null",
    "--allow-interpreter",
    "--load-state", "`"$State`""
) -join " "

Write-Host "[pgo] building instrumented module and running ${PlaySeconds}s of gameplay"
$p = Start-Process -FilePath $port -PassThru -NoNewWindow -ArgumentList $argLine `
     -RedirectStandardOutput $log -RedirectStandardError "$root\build\logs\$Tag.err"

Start-Sleep -Seconds $PlaySeconds
Write-Host "[pgo] stopping run so the profile flushes"
"command=stop" | Set-Content "$auto\commands\stop.txt"

while (-not $p.HasExited) {
    Start-Sleep -Seconds 5
    if ((Get-Date) -gt $p.StartTime.AddMinutes(20)) { Write-Warning "[pgo] timeout"; break }
}
Write-Host "[pgo] exit=$($p.ExitCode)"
Write-Host "===== tail ====="
if (Test-Path $log) { Get-Content $log -Tail 25 }
$merged = Join-Path $ProfileDir "merged.profdata"
Write-Host "[pgo] merged profile: $merged exists=$(Test-Path $merged)"
if (Test-Path $merged) { Get-Item $merged | Select-Object Length,LastWriteTime }

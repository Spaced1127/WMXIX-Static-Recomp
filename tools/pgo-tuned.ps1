# Full PGO cycle for the tuned module:
#   1. build tuned + -fprofile-generate
#   2. run real gameplay from a save state, collect .profraw
#   3. merge with llvm-profdata
#   4. rebuild tuned + -fprofile-use
#
# Flags stay identical between the instrumented and final build so Clang's
# function hashes match and the profile is actually applied.
param(
    [string]$GeneratedDir = "H:\Projects\WWE WMXIIIV\build\modules\GW9E78\627b899760d0b820c049ad29f96a613da1c43d35dd4a1456e581cc620bae9fb7-0fe561dfd013cdfb\dolrecomp-output\generated",
    [string]$OutDir = "H:\Projects\WWE WMXIIIV\build\modules\GW9E78\pgo",
    [string]$ProfileDir = "H:\Projects\WWE WMXIIIV\build\pgo",
    [string]$State = "H:\Projects\WWE WMXIIIV\work\states\user-match.state",
    [int]$PlaySeconds = 90,
    [string]$March = "x86-64-v3"
)
$ErrorActionPreference = 'Continue'
$root = "H:\Projects\WWE WMXIIIV"
$clang = "C:\Program Files\LLVM\bin\clang.exe"
$profdata = "C:\Program Files\LLVM\bin\llvm-profdata.exe"
$runner = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\WMXIXRunner.exe"
$auto = "$root\build\auto-pgo"

New-Item -ItemType Directory -Force -Path $ProfileDir,"$ProfileDir\raw",$auto,"$auto\commands","$auto\processed","$root\build\logs" | Out-Null
Get-ChildItem "$ProfileDir\raw" -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem "$auto\commands" -ErrorAction SilentlyContinue | Remove-Item -Force

function Step($name, $block) {
    Write-Host "`n=== $name ==="
    & $block
}

# 1. instrumented build ------------------------------------------------------
Step "instrumented build" {
    & "$root\tools\build-module-tuned.ps1" -GeneratedDir $GeneratedDir -OutDir $OutDir `
        -March $March -ExtraFlags "-fprofile-generate=`"$ProfileDir\raw`""
}
$dll = Join-Path $OutDir "gGW9E78_recomp.dll"
if (-not (Test-Path $dll)) { throw "instrumented module missing: $dll" }

# 2. collect profile ---------------------------------------------------------
Step "profile run (${PlaySeconds}s)" {
    $env:LLVM_PROFILE_FILE = "$ProfileDir\raw\wmxix-%p.profraw"
    $argLine = "--game `"$root\work\game`" --module `"$dll`" --user-dir `"$root\work\user`" " +
               "--automation-dir `"$auto`" --graphics Vulkan --audio Null --allow-interpreter " +
               "--load-state `"$State`""
    $p = Start-Process -FilePath $runner -PassThru -NoNewWindow -ArgumentList $argLine `
         -RedirectStandardOutput "$root\build\logs\pgo-run.out" `
         -RedirectStandardError "$root\build\logs\pgo-run.err"
    Start-Sleep -Seconds $PlaySeconds
    "command=stop" | Set-Content "$auto\commands\stop.txt"
    $deadline = (Get-Date).AddSeconds(60)
    while (-not $p.HasExited -and (Get-Date) -lt $deadline) { Start-Sleep -Seconds 2 }
    if (-not $p.HasExited) { & taskkill /PID $p.Id /T /F 2>&1 | Out-Null }
    Remove-Item Env:\LLVM_PROFILE_FILE -ErrorAction SilentlyContinue
    if (Test-Path "$root\build\logs\pgo-run.err") { Get-Content "$root\build\logs\pgo-run.err" -Tail 6 }
}

$raw = Get-ChildItem "$ProfileDir\raw" -Filter *.profraw -ErrorAction SilentlyContinue
Write-Host "[pgo] profraw files: $($raw.Count)"
if ($raw.Count -eq 0) { throw "no .profraw collected" }

# 3. merge -------------------------------------------------------------------
Step "merge" {
    & $profdata merge -o "$ProfileDir\merged.profdata" $raw.FullName
    & $profdata show --topn=15 --counts "$ProfileDir\merged.profdata" 2>&1 | Select-Object -First 25
}
if (-not (Test-Path "$ProfileDir\merged.profdata")) { throw "merge failed" }

# 4. final profile-use build -------------------------------------------------
Step "profile-use build" {
    & "$root\tools\build-module-tuned.ps1" -GeneratedDir $GeneratedDir -OutDir $OutDir `
        -March $March -ExtraFlags "-fprofile-use=`"$ProfileDir\merged.profdata`" -Wno-profile-instr-out-of-date -Wno-profile-instr-unprofiled"
}
Write-Host "`n[pgo] final module: $dll exists=$(Test-Path $dll)"

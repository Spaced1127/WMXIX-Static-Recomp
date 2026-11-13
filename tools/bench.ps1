# Measure an uncapped run from a save state.
#
# EmulationSpeed = 0 disables the frame limiter, so the reported fps is what the
# build can actually sustain (headroom), not a vsync-capped 59.94.
#
#   tools\bench.ps1 -Module <dll> -Tag stock
#   tools\bench.ps1 -Tag jit            # runtime JIT reference, no static module
param(
    [string]$Module,
    [string]$Tag = "bench",
    [int]$Seconds = 40,
    [int]$Warmup = 15,
    [int]$Resolution = 1,
    [double]$Speed = 0.0,
    [string]$IdlePc = "",
    [switch]$Jit,
    [string]$State = "H:\Projects\WWE WMXIIIV\work\states\gameplay.state"
)
$ErrorActionPreference = 'Continue'
$root   = "H:\Projects\WWE WMXIIIV"
$runner = "$root\lib\ModernGekko-Template\lib\ModernGekko\build\WMXIXRunner.exe"
$user   = "$root\work\bench-user"
$auto   = "$root\build\auto-bench"
$logs   = "$root\build\logs"

New-Item -ItemType Directory -Force -Path $user,"$user\Config",$auto,"$auto\commands","$auto\processed",$logs | Out-Null
Get-ChildItem "$auto\commands" -ErrorAction SilentlyContinue | Remove-Item -Force

# Bench profile: uncapped, 1x internal resolution, no AA/AF.
if (Test-Path "$root\work\user\Config\GCPadNew.ini") {
    Copy-Item "$root\work\user\Config\GCPadNew.ini" "$user\Config\GCPadNew.ini" -Force
}
@"
[Core]
EmulationSpeed = $Speed
CPUCore = 6
GFXBackend = Vulkan
StaticRecompIdlePC = $IdlePc
[DSP]
Backend = Null
[Display]
Fullscreen = False
"@ | Set-Content "$user\Config\Dolphin.ini"
@"
[Settings]
DumpTextures = False
InternalResolution = $Resolution
ShaderCache = True
ShaderCompilationMode = 2
WaitForShadersBeforeStarting = True
"@ | Set-Content "$user\Config\GFX.ini"

$modArgs = if ($Module) { "--module `"$Module`"" } else { "" }
$loadArgs = if ($State -and (Test-Path $State)) { "--load-state `"$State`"" } else { "" }
if ($Jit) {
    $Module = $null
    $modArgs = ""
    $env:MODERNGEKKO_STATICRECOMP = "0"
} else {
    Remove-Item Env:\MODERNGEKKO_STATICRECOMP -ErrorAction SilentlyContinue
}
$argLine = "--game `"$root\work\game`" $modArgs --user-dir `"$user`" --automation-dir `"$auto`" --graphics Vulkan --audio Null --allow-interpreter $loadArgs"

Write-Host "[bench:$Tag] module=$(if($Module){Split-Path $Module -Leaf}else{'JIT'}) state=$(if(Test-Path $State){'yes'}else{'no'})"
$out = "$logs\bench-$Tag.out"
$err = "$logs\bench-$Tag.err"
$p = Start-Process -FilePath $runner -PassThru -NoNewWindow -ArgumentList $argLine `
     -RedirectStandardOutput $out -RedirectStandardError $err

Start-Sleep -Seconds $Warmup
$samples = @()
$deadline = (Get-Date).AddSeconds($Seconds)
while ((Get-Date) -lt $deadline -and -not $p.HasExited) {
    Start-Sleep -Seconds 2
    if (Test-Path "$auto\status.txt") {
        $st = @{}
        Get-Content "$auto\status.txt" | ForEach-Object {
            if ($_ -match '^([a-z_]+)=(.*)$') { $st[$Matches[1]] = $Matches[2] }
        }
        if ($st['fps']) { $samples += [double]$st['fps'] }
    }
}

"command=stop" | Set-Content "$auto\commands\stop.txt"
Start-Sleep -Seconds 5
if (-not $p.HasExited) { & taskkill /PID $p.Id /T /F 2>&1 | Out-Null }
Start-Sleep -Seconds 1

if ($samples.Count -gt 0) {
    $avg = ($samples | Measure-Object -Average).Average
    $max = ($samples | Measure-Object -Maximum).Maximum
    $min = ($samples | Measure-Object -Minimum).Minimum
    Write-Host ("[bench:{0}] samples={1} avg={2:N2} min={3:N2} max={4:N2} fps" -f $Tag,$samples.Count,$avg,$min,$max)
    [pscustomobject]@{ Tag=$Tag; Samples=$samples.Count; AvgFps=[math]::Round($avg,2); MinFps=[math]::Round($min,2); MaxFps=[math]::Round($max,2) } |
        Export-Csv "$logs\bench-$Tag.csv" -NoTypeInformation
} else {
    Write-Host "[bench:$Tag] no fps samples - check $err"
    if (Test-Path $err) { Get-Content $err -Tail 15 }
}

# Build DolRecomp and the ModernGekko port tool.
# Logs to build/logs/build-tools.log
$ErrorActionPreference = 'Stop'
. "H:\Projects\WWE WMXIIIV\tools\msvc-env.ps1"

$root = "H:\Projects\WWE WMXIIIV"
$tmpl = Join-Path $root "lib\ModernGekko-Template"
New-Item -ItemType Directory -Force -Path "$root\build\logs" | Out-Null

$log = "$root\build\logs\build-tools.log"
"=== $(Get-Date -Format o) build-tools start ===" | Set-Content $log

function Step([string]$name, [scriptblock]$block) {
    "`n=== $name ===" | Add-Content $log
    & $block 2>&1 | Tee-Object -FilePath $log -Append
    if ($LASTEXITCODE -ne 0) { throw "$name failed with exit code $LASTEXITCODE" }
}

Push-Location $tmpl
try {
    Step "configure DolRecomp" {
        cmake -S lib/DolRecomp -B lib/DolRecomp/build -G Ninja -DCMAKE_BUILD_TYPE=Release
    }
    Step "build dolrecomp" {
        cmake --build lib/DolRecomp/build --target dolrecomp -j 16
    }
    Step "configure ModernGekko" {
        cmake -S lib/ModernGekko -B lib/ModernGekko/build -G Ninja -DCMAKE_BUILD_TYPE=Release
    }
    Step "build moderngekko-port" {
        cmake --build lib/ModernGekko/build --target moderngekko-port -j 16
    }
    "`n=== DONE ===" | Add-Content $log
} finally {
    Pop-Location
}

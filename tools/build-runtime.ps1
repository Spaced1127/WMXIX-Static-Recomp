$ErrorActionPreference = 'Continue'
. "H:\Projects\WWE WMXIIIV\tools\msvc-env.ps1" | Out-Null
Set-Location "H:\Projects\WWE WMXIIIV\lib\ModernGekko-Template"
cmake --build lib/ModernGekko/build --target moderngekko-port moderngekko-run -j 16 2>&1 |
    Tee-Object -FilePath "H:\Projects\WWE WMXIIIV\build\logs\build-runtime.log" |
    Select-Object -Last 50
Write-Output ("EXIT=" + $LASTEXITCODE)

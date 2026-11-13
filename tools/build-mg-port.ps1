$ErrorActionPreference = 'Continue'
. "H:\Projects\WWE WMXIIIV\tools\msvc-env.ps1" | Out-Null
Set-Location "H:\Projects\WWE WMXIIIV\lib\ModernGekko-Template"
cmake --build lib/ModernGekko/build --target moderngekko-port -j 16 2>&1 | Select-Object -Last 60
Write-Output ("EXIT=" + $LASTEXITCODE)

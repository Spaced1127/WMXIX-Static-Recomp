# Dot-source this to put MSVC, Ninja and LLVM on PATH for the current session.
# Usage:  . "H:\Projects\WWE WMXIIIV\tools\msvc-env.ps1"

$vcvars = "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

if (-not (Test-Path $vcvars)) { throw "vcvars64.bat not found at $vcvars" }

# Import the MSVC environment block into this PowerShell session.
cmd /c "`"$vcvars`" >nul 2>&1 && set" | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        Set-Item -Path "env:$($matches[1])" -Value $matches[2]
    }
}

$ninjaDir = "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja"
if (Test-Path (Join-Path $ninjaDir "ninja.exe")) {
    $env:Path = "$ninjaDir;" + $env:Path
}

$llvmDir = "C:\Program Files\LLVM\bin"
if (Test-Path (Join-Path $llvmDir "clang.exe")) {
    $env:Path = "$llvmDir;" + $env:Path
}

Write-Host "[env] cl:" (Get-Command cl.exe -ErrorAction SilentlyContinue).Source
Write-Host "[env] ninja:" (Get-Command ninja.exe -ErrorAction SilentlyContinue).Source
Write-Host "[env] clang:" (Get-Command clang.exe -ErrorAction SilentlyContinue).Source

# Canonical controller layout tests (offline, no pad needed).
#
# Verifies the static profile, write-once behaviour, the keyboard variant, the
# legacy flags still parsing, and that every class value is accepted.
#
#   powershell -File tools\test-controller-layouts.ps1
param([string]$Launcher = '')

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if (-not $Launcher) {
    $Launcher = Join-Path $root 'lib\ModernGekko-Template\lib\ModernGekko\build\launcher.exe'
}
if (-not (Test-Path $Launcher)) { throw "launcher.exe not found; pass -Launcher" }

$work = Join-Path $env:TEMP 'wmxix-controller-tests'
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory $work | Out-Null

$fail = 0
function Check([string]$name, [bool]$ok, [string]$detail = '') {
    if ($ok) { "PASS  $name" } else { "FAIL  $name $detail"; $script:fail++ }
}

# 1. Canonical profile contents.
$dir = Join-Path $work 'canonical'
& $Launcher --user-dir $dir --write-pad-profile 'SDL/0/Test Pad' | Out-Null
$text = [IO.File]::ReadAllText((Join-Path $dir 'Config\GCPadNew.ini'))
Check 'canonical: GCPad1 only'        (([regex]::Matches($text, '\[GCPad\d\]')).Count -eq 1)
Check 'canonical: positional A/B/X/Y' ($text.Contains('Buttons/A = `Button A`') -and $text.Contains('Buttons/X = `Button X`'))
Check 'canonical: plain D-pad'        ($text.Contains('D-Pad/Left = `Pad W`') -and -not $text.Contains('Shoulder L'))
Check 'canonical: triggers'           ($text.Contains('Triggers/L = `Trigger L`'))
Check 'canonical: device'             ($text.Contains('Device = SDL/0/Test Pad'))

# 2. Write-once: a second call (and a hand edit) must not change the file.
$hash1 = (Get-FileHash (Join-Path $dir 'Config\GCPadNew.ini')).Hash
& $Launcher --user-dir $dir --write-pad-profile 'SDL/0/Something Else' | Out-Null
$hash2 = (Get-FileHash (Join-Path $dir 'Config\GCPadNew.ini')).Hash
Check 'write-once: unchanged' ($hash1 -eq $hash2)

# 3. Keyboard variant.
$kdir = Join-Path $work 'keyboard'
& $Launcher --user-dir $kdir --write-pad-profile 'DInput/0/Keyboard Mouse' | Out-Null
$ktext = [IO.File]::ReadAllText((Join-Path $kdir 'Config\GCPadNew.ini'))
Check 'keyboard: RETURN/UP/W'      ($ktext.Contains('Buttons/A = `RETURN`') -and $ktext.Contains('D-Pad/Up = `UP`'))
Check 'keyboard: no pad bindings'  (-not $ktext.Contains('Button A'))

# 4. Legacy flags stay parseable and never fail.
$legacyOk = $true
foreach ($args in @(
        @('--check-migration', $dir),
        @('--pad-info', '030000005e0400008e02000000000000'),
        @('--pad-info', '030000005e0400008e02000000000000', '--pad-layout', 'nintendo'),
        @('--write-pad-profile', 'SDL/0/Legacy Pad', '--pad-guid', '030000005e0400008e02000000000000'))) {
    & $Launcher @args 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { $legacyOk = $false }
}
Check 'legacy flags exit 0' $legacyOk

# 5. Every class value is accepted, junk is rejected.
$classOk = $true
foreach ($class in @('auto', 'positional', 'standard', 'nintendo', 'switch')) {
    $cdir = Join-Path $work ("class-" + $class)
    & $Launcher --user-dir $cdir --controller-layout $class --check-migration $cdir 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { $classOk = $false; "  rejected: $class" }
}
Check 'controller class values accepted' $classOk
$ErrorActionPreference = 'Continue'
& $Launcher --user-dir (Join-Path $work 'junk') --controller-layout 'banana' --check-migration (Join-Path $work 'junk') 2>&1 | Out-Null
$junkExit = $LASTEXITCODE
$ErrorActionPreference = 'Stop'
Check 'controller class junk rejected' ($junkExit -ne 0)

if ($fail -ne 0) { "FAILED: $fail check(s)"; exit 1 }
"PASSED: canonical controller layout"
exit 0
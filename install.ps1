param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$DotbotArgs
)

$ErrorActionPreference = "Stop"

$BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DotbotDir = Join-Path $BaseDir "dotbot"
$DotbotBin = Join-Path $DotbotDir "bin\dotbot"
$Config = Join-Path $BaseDir "install.windows.conf.yaml"

Set-Location $BaseDir

git -C $DotbotDir submodule sync --quiet --recursive
git submodule update --init --recursive dotbot claude/skills-vendor/n8n-skills

$python = Get-Command py -ErrorAction SilentlyContinue
if ($python) {
    & py -3 $DotbotBin -d $BaseDir -c $Config @DotbotArgs
} else {
    $python = Get-Command python -ErrorAction Stop
    & $python.Source $DotbotBin -d $BaseDir -c $Config @DotbotArgs
}
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $BaseDir "scripts\install-windows-config.ps1") -RepoRoot $BaseDir
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

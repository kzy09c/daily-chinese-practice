param([string]$ScratchDirectory = [IO.Path]::GetTempPath())

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $root 'WordEngine.ps1')
$words = @(Import-Csv -LiteralPath (Join-Path $root 'words.txt') -Delimiter '|' -Encoding UTF8)
Test-Vocabulary -Words $words
$path = Join-Path $ScratchDirectory ('daily-chinese-test-' + [guid]::NewGuid().ToString('N') + '.json')
$today = [datetime]'2026-01-02'
function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
try {
    $first = Get-WordState -Words $words -Path $path -Date $today
    Assert-True ($first.characters -in $words.characters) 'Initial random selection is not in the vocabulary.'
    $reopened = Get-WordState -Words $words -Path $path -Date $today
    Assert-True ($reopened.characters -eq $first.characters) 'Reopening changed the daily word.'
    $skipped = Get-WordState -Words $words -Path $path -Date $today -Skip
    Assert-True ($skipped.characters -ne $first.characters) 'Skip did not advance to another word.'
    $reopened = Get-WordState -Words $words -Path $path -Date $today
    Assert-True ($reopened.characters -eq $skipped.characters) 'Skipped selection was not saved.'
    $tomorrow = Get-WordState -Words $words -Path $path -Date $today.AddDays(1)
    Assert-True ($tomorrow.date -eq '2026-01-03') 'Midnight did not change the state date.'
    Assert-True ($tomorrow.characters -ne $skipped.characters) 'The next day did not get another word.'
    $pair = @($words[0], $words[1])
    Save-WordState -Path $path -State ([pscustomobject]@{ date = '2026-01-02'; characters = $pair[0].characters })
    $second = Get-WordState -Words $pair -Path $path -Date $today -Skip
    $third = Get-WordState -Words $pair -Path $path -Date $today -Skip
    Assert-True ($second.characters -eq $pair[1].characters -and $third.characters -eq $pair[0].characters) 'Earlier words could not repeat.'
    Save-WordState -Path $path -State ([pscustomobject]@{ date = '2026-01-02'; characters = 'not-in-vocabulary' })
    $repaired = Get-WordState -Words $words -Path $path -Date $today
    Assert-True ($repaired.characters -in $words.characters) 'Removed vocabulary entry was not replaced.'
    [IO.File]::WriteAllText($path, 'invalid-json')
    $repaired = Get-WordState -Words $words -Path $path -Date $today
    Assert-True ($repaired.characters -in $words.characters) 'Invalid state was not recovered.'
    $yesterday = Get-WordState -Words $words -Path $path -Date $today.AddDays(-1)
    Assert-True ($yesterday.date -eq '2026-01-01') 'A backward clock change was not handled.'
    [pscustomobject]@{ Result = 'Passed'; WordCount = $words.Count; Checks = 'First launch, reopen, skip, saved skip, new day, allowed repeats, removed word, corrupt state, clock change' } | ConvertTo-Json
} finally {
    if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path }
}

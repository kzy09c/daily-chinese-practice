function Test-Vocabulary {
    param([object[]]$Words)
    if ($Words.Count -lt 365) { throw 'The vocabulary needs at least 365 entries.' }
    $seen = @{}
    foreach ($word in $Words) {
        if (-not $word.characters -or -not $word.pinyin -or -not $word.english) {
            throw 'A vocabulary entry is incomplete.'
        }
        if ($seen.ContainsKey($word.characters)) { throw "Duplicate word: $($word.characters)" }
        $seen[$word.characters] = $true
    }
}

function Select-RandomWord {
    param([object[]]$Words, [string]$ExcludeCharacters)
    $eligible = @($Words | Where-Object { $_.characters -ne $ExcludeCharacters })
    if ($eligible.Count -eq 0) { throw 'There are no other words to display.' }
    return $eligible[(Get-Random -Minimum 0 -Maximum $eligible.Count)]
}

function Save-WordState {
    param([string]$Path, [object]$State)
    $fullPath = [IO.Path]::GetFullPath($Path)
    $temporaryPath = $fullPath + '.' + [guid]::NewGuid().ToString('N') + '.tmp'
    try {
        $json = $State | ConvertTo-Json
        [IO.File]::WriteAllText($temporaryPath, $json, (New-Object Text.UTF8Encoding($false)))
        if ([IO.File]::Exists($fullPath)) {
            [IO.File]::Replace($temporaryPath, $fullPath, [NullString]::Value)
        } else {
            [IO.File]::Move($temporaryPath, $fullPath)
        }
    } finally {
        if ([IO.File]::Exists($temporaryPath)) { [IO.File]::Delete($temporaryPath) }
    }
}

function Get-WordState {
    param(
        [object[]]$Words,
        [string]$Path,
        [datetime]$Date = (Get-Date),
        [switch]$Skip
    )
    $day = $Date.ToString('yyyy-MM-dd')
    $previous = $null
    if (Test-Path -LiteralPath $Path) {
        try { $previous = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json }
        catch { $previous = $null }
    }
    $previousWord = $null
    if ($previous -and $previous.characters) {
        $previousWord = @($Words | Where-Object { $_.characters -eq $previous.characters })
    }
    if (-not $Skip -and $previous -and $previous.date -eq $day -and $previousWord.Count -eq 1) {
        return $previous
    }
    $exclude = if ($previous) { [string]$previous.characters } else { '' }
    $next = Select-RandomWord -Words $Words -ExcludeCharacters $exclude
    $state = [pscustomobject]@{ date = $day; characters = $next.characters }
    Save-WordState -Path $Path -State $state
    return $state
}

function Get-MandarinVoices {
    $voices = [Collections.Generic.List[object]]::new()
    $seen = @{}
    foreach ($path in @('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech\Voices', 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Speech_OneCore\Voices')) {
        try {
            $category = New-Object -ComObject SAPI.SpObjectTokenCategory
            $category.SetId($path, $false)
            foreach ($token in $category.EnumerateTokens()) {
                $languages = @($token.GetAttribute('Language') -split ';' | ForEach-Object { $_.Trim().ToLowerInvariant() })
                $mandarin = @($languages | Where-Object { $_ -in @('804', '404', '1004') })
                if ($mandarin.Count -and -not $seen.ContainsKey($token.Id)) {
                    $voices.Add([pscustomobject]@{ Token = $token; Name = $token.GetDescription(); Language = $mandarin[0]; Priority = $(if ('804' -in $languages) { 0 } else { 1 }) })
                    $seen[$token.Id] = $true
                }
            }
        } catch {
            # Some Windows installations expose only one voice category.
        }
    }
    return @($voices | Sort-Object Priority, Name)
}

function New-MandarinSpeaker {
    foreach ($choice in @(Get-MandarinVoices)) {
        $speaker = $null
        try {
            $speaker = New-Object -ComObject SAPI.SpVoice
            $speaker.Voice = $choice.Token
            $speaker.Rate = -1
            $speaker.Volume = 100
            return [pscustomobject]@{ Speaker = $speaker; Name = $choice.Name; Language = $choice.Language }
        } catch {
            if ($speaker) { [Runtime.InteropServices.Marshal]::ReleaseComObject($speaker) | Out-Null }
        }
    }
    return $null
}

function Stop-MandarinSpeech {
    param([object]$Speech)
    if ($Speech) {
        try { $Speech.Speaker.Speak('', 3) | Out-Null } catch { }
    }
}

function Read-MandarinWord {
    param([object]$Speech, [string]$Text)
    if (-not $Speech) { throw 'No Mandarin speech voice is available.' }
    if (-not [string]::IsNullOrWhiteSpace($Text)) {
        # Async + purge old requests + treat the word as plain text.
        $Speech.Speaker.Speak($Text, 19) | Out-Null
    }
}

function Close-MandarinSpeaker {
    param([object]$Speech)
    if ($Speech) {
        Stop-MandarinSpeech -Speech $Speech
        [Runtime.InteropServices.Marshal]::ReleaseComObject($Speech.Speaker) | Out-Null
    }
}

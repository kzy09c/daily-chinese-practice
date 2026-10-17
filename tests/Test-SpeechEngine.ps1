param([string]$OutputPath)

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'SpeechEngine.ps1')
$speech = New-MandarinSpeaker
if (-not $speech) { throw 'Install a Mandarin Windows speech voice before running this test.' }
try {
    if ($OutputPath) {
        $stream = New-Object -ComObject SAPI.SpFileStream
        try {
            $stream.Open([IO.Path]::GetFullPath($OutputPath), 3, $false)
            $speech.Speaker.AudioOutputStream = $stream
            $word = [string][char]0x6743 + [string][char]0x8861
            $speech.Speaker.Speak($word, 16) | Out-Null
            $stream.Close()
        } finally {
            [Runtime.InteropServices.Marshal]::ReleaseComObject($stream) | Out-Null
        }
        $bytes = [IO.File]::ReadAllBytes([IO.Path]::GetFullPath($OutputPath))
        if ($bytes.Length -le 44 -or [Text.Encoding]::ASCII.GetString($bytes,0,4) -ne 'RIFF') { throw 'Mandarin speech did not produce a valid audio file.' }
    }
    [pscustomobject]@{ Result = 'Passed'; Voice = $speech.Name; Language = $speech.Language; AudioBytes = $(if ($OutputPath) { $bytes.Length } else { 0 }) } | ConvertTo-Json
} finally {
    Close-MandarinSpeaker -Speech $speech
}

$ErrorActionPreference = 'Stop'
$shell = New-Object -ComObject WScript.Shell
$expectedScript = Join-Path $PSScriptRoot 'DailyChinese.ps1'
foreach ($folder in @([Environment]::GetFolderPath('Startup'), [Environment]::GetFolderPath('Desktop'))) {
    $path = Join-Path $folder 'Daily Chinese.lnk'
    if (Test-Path -LiteralPath $path) {
        $link = $shell.CreateShortcut($path)
        if ($link.Arguments.Contains($expectedScript)) {
            Remove-Item -LiteralPath $path
            Write-Output "Removed: $path"
        }
    }
}
Write-Output 'Automatic startup is removed. Close any open Daily Chinese card.'

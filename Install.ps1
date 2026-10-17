$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot 'DailyChinese.ps1'
$powershellPath = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
$shell = New-Object -ComObject WScript.Shell
$folders = @([Environment]::GetFolderPath('Startup'), [Environment]::GetFolderPath('Desktop'))
foreach ($folder in $folders) {
    if (-not (Test-Path -LiteralPath $folder)) { throw "Shortcut folder is unavailable: $folder" }
    $linkPath = Join-Path $folder 'Daily Chinese.lnk'
    $link = $shell.CreateShortcut($linkPath)
    if ((Test-Path -LiteralPath $linkPath) -and -not $link.Arguments.Contains($scriptPath)) {
        throw "A different Daily Chinese shortcut already exists: $linkPath"
    }
    $link.TargetPath = $powershellPath
    $link.Arguments = '-NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $scriptPath + '"'
    $link.WorkingDirectory = $PSScriptRoot
    $link.Description = 'A new Chinese word every day, with pinyin and an English meaning.'
    $link.WindowStyle = 7
    $link.IconLocation = (Join-Path $env:WINDIR 'System32\shell32.dll') + ',21'
    $link.Save()
    Write-Output (Join-Path $folder 'Daily Chinese.lnk')
}

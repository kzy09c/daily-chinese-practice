param(
    [switch]$Validate,
    [string]$PreviewPath
)

$ErrorActionPreference = 'Stop'
$appRoot = $PSScriptRoot
. (Join-Path $appRoot 'WordEngine.ps1')
. (Join-Path $appRoot 'SpeechEngine.ps1')
$words = @(Import-Csv -LiteralPath (Join-Path $appRoot 'words.txt') -Delimiter '|' -Encoding UTF8)
Test-Vocabulary -Words $words
if ($Validate) {
    [pscustomobject]@{ Result = 'Passed'; WordCount = $words.Count; Selection = 'Random daily and on skip'; Repeats = 'Allowed; immediate duplicate excluded' } | ConvertTo-Json
    return
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
[xml]$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Daily Chinese" Width="420" Height="400" WindowStyle="None"
        ResizeMode="NoResize" AllowsTransparency="True" Background="Transparent"
        ShowInTaskbar="True" Topmost="False" FontFamily="Segoe UI" UseLayoutRounding="True">
  <Border Margin="12" Padding="24,20" CornerRadius="20" Background="#FCF8F0" BorderBrush="#DED9CD" BorderThickness="1">
    <Border.Effect><DropShadowEffect BlurRadius="16" ShadowDepth="3" Opacity="0.20"/></Border.Effect>
    <Grid>
      <Grid.RowDefinitions>
        <RowDefinition Height="34"/><RowDefinition Height="25"/><RowDefinition Height="88"/>
        <RowDefinition Height="39"/><RowDefinition Height="*"/><RowDefinition Height="50"/><RowDefinition Height="23"/>
      </Grid.RowDefinitions>
      <Grid x:Name="DragArea" Background="Transparent" Cursor="SizeAll">
        <TextBlock Text="DAILY CHINESE / LEVEL UP" FontSize="12" FontWeight="SemiBold" Foreground="#47635D" VerticalAlignment="Center"/>
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
          <Button x:Name="MinimizeButton" Content="&#x2013;" Width="28" Height="26" Margin="0,0,4,0" Background="Transparent" BorderThickness="0" Foreground="#47635D" ToolTip="Minimize" Cursor="Hand"/>
          <Button x:Name="CloseButton" Content="&#x00D7;" Width="28" Height="26" FontSize="19" Background="Transparent" BorderThickness="0" Foreground="#47635D" ToolTip="Close until you reopen it or sign in again" Cursor="Hand"/>
        </StackPanel>
      </Grid>
      <TextBlock x:Name="DateText" Grid.Row="1" Foreground="#6B776D" FontSize="12"/>
      <TextBlock x:Name="CharactersText" Grid.Row="2" Foreground="#173F38" FontFamily="Microsoft YaHei UI" FontSize="56" VerticalAlignment="Center"/>
      <TextBlock x:Name="PinyinText" Grid.Row="3" Foreground="#147C6B" FontSize="24"/>
      <TextBlock x:Name="EnglishText" Grid.Row="4" Foreground="#293B36" FontSize="19" TextWrapping="Wrap" Margin="0,3,0,0"/>
      <Grid Grid.Row="5">
        <Grid.ColumnDefinitions><ColumnDefinition Width="130"/><ColumnDefinition Width="10"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
        <Button x:Name="ReadButton" Content="&#x25B6; Read aloud" Height="36" VerticalAlignment="Center" Background="#E3EEE8" Foreground="#173F38" BorderThickness="0" FontSize="13" FontWeight="SemiBold" Cursor="Hand" ToolTip="Hear the Chinese word in Mandarin (R)"/>
        <Button x:Name="NextButton" Grid.Column="2" Content="Skip / Next word &#x2192;" Height="36" VerticalAlignment="Center" Background="#147C6B" Foreground="White" BorderThickness="0" FontSize="13" FontWeight="SemiBold" Cursor="Hand" ToolTip="Pick another random word. Skipped words can appear again." IsDefault="True"/>
      </Grid>
      <TextBlock Grid.Row="6" Text="A random word each day. Skip anytime." Foreground="#7B8176" FontSize="10.5" VerticalAlignment="Bottom"/>
    </Grid>
  </Border>
</Window>
'@


$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)
$dateText = $window.FindName('DateText')
$charactersText = $window.FindName('CharactersText')
$pinyinText = $window.FindName('PinyinText')
$englishText = $window.FindName('EnglishText')
$statePath = Join-Path $appRoot 'state.json'
$script:displayedDate = ''
$script:mandarinSpeech = $null

function Set-DisplayedWord {
    param([object]$Word, [datetime]$Date)
    Stop-MandarinSpeech -Speech $script:mandarinSpeech
    $dateText.Text = $Date.ToString('dddd, d MMMM yyyy', [Globalization.CultureInfo]::GetCultureInfo('en-AU'))
    $charactersText.Text = $Word.characters
    $charactersText.FontSize = if ($Word.characters.Length -gt 4) { 46 } else { 56 }
    $pinyinText.Text = $Word.pinyin
    $englishText.Text = $Word.english
    $script:displayedDate = $Date.ToString('yyyy-MM-dd')
}

function Update-DailyWord {
    param([switch]$Skip)
    $now = Get-Date
    if ($Skip -or $now.ToString('yyyy-MM-dd') -ne $script:displayedDate) {
        $state = Get-WordState -Words $words -Path $statePath -Date $now -Skip:$Skip
        $word = $words | Where-Object { $_.characters -eq $state.characters } | Select-Object -First 1
        Set-DisplayedWord -Word $word -Date $now
    }
}

function Show-SaveError {
    [Windows.MessageBox]::Show('Could not save your next word. Check that this app folder is writable, then try again.', 'Daily Chinese', 'OK', 'Warning') | Out-Null
}

function Read-DisplayedWord {
    try {
        if (-not $script:mandarinSpeech) { $script:mandarinSpeech = New-MandarinSpeaker }
        if (-not $script:mandarinSpeech) {
            [Windows.MessageBox]::Show('Add a Mandarin voice in Windows Settings > Time & language > Speech > Add voices. Choose Chinese (Simplified, China), then try Read aloud again.', 'Mandarin voice needed', 'OK', 'Information') | Out-Null
            return
        }
        Read-MandarinWord -Speech $script:mandarinSpeech -Text $charactersText.Text
    } catch {
        [Windows.MessageBox]::Show('Windows could not play the pronunciation. Check your sound output and installed Mandarin speech voice, then try again.', 'Daily Chinese', 'OK', 'Warning') | Out-Null
    }
}

if ($PreviewPath) {
    Set-DisplayedWord -Word $words[0] -Date (Get-Date)
    $preview = $window.Content
    $preview.Measure((New-Object Windows.Size(420,400)))
    $preview.Arrange((New-Object Windows.Rect(0,0,420,400)))
    $preview.UpdateLayout()
    $bitmap = New-Object Windows.Media.Imaging.RenderTargetBitmap(420,400,96,96,[Windows.Media.PixelFormats]::Pbgra32)
    $bitmap.Render($preview)
    $encoder = New-Object Windows.Media.Imaging.PngBitmapEncoder
    $encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
    $stream = [IO.File]::Create($PreviewPath)
    try { $encoder.Save($stream) } finally { $stream.Dispose() }
    return
}

$mutex = New-Object Threading.Mutex($false, 'Local\DailyChineseVocabularyCard')
if (-not $mutex.WaitOne(0)) { $mutex.Dispose(); return }
try {
    Update-DailyWord
    $screen = [Windows.SystemParameters]::WorkArea
    $window.Left = [Math]::Max($screen.Left, $screen.Right - $window.Width - 10)
    $window.Top = [Math]::Max($screen.Top, $screen.Bottom - $window.Height - 10)
    $window.FindName('DragArea').Add_MouseLeftButtonDown({
        if ($_.OriginalSource -isnot [Windows.Controls.Button]) { $window.DragMove() }
    })
    $window.FindName('MinimizeButton').Add_Click({ $window.WindowState = 'Minimized' })
    $window.FindName('CloseButton').Add_Click({ $window.Close() })
    $window.FindName('ReadButton').Add_Click({ Read-DisplayedWord })
    $window.FindName('NextButton').Add_Click({
        try { Update-DailyWord -Skip } catch { Show-SaveError }
    })
    $window.Add_KeyDown({
        if ($_.Key -eq 'Escape') { $window.Close() }
        elseif ($_.Key -eq 'R') { Read-DisplayedWord; $_.Handled = $true }
        elseif ($_.Key -eq 'Right') {
            try { Update-DailyWord -Skip } catch { Show-SaveError }
            $_.Handled = $true
        }
    })
    $timer = New-Object Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(30)
    $timer.Add_Tick({
        try { Update-DailyWord } catch { $timer.Stop(); Show-SaveError }
    })
    $timer.Start()
    $window.Add_Closed({ $timer.Stop() })
    $window.ShowDialog() | Out-Null
} finally {
    Close-MandarinSpeaker -Speech $script:mandarinSpeech
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}

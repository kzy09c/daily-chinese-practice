# Daily Chinese

An offline Windows desktop card for learning harder Mandarin vocabulary and
expressions, with simplified Chinese characters, pinyin, and English meanings.


<img src="assets/dancing.gif" alt="Project Demo" width="500">

## Features

- 1,000 distinct words and expressions, with an emphasis on challenging vocabulary for discussion, writing, news, and adult conversation.
- A random word each day, rather than a fixed sequence through the file.
- A **Skip / Next word** button to draw another word immediately.
- Press **Enter** or the **right arrow** to skip without the mouse.
- Your current word is saved when you skip and stays the same when you reopen the app that day.
- Words can repeat on later draws. A draw excludes only the word currently displayed, so skipping always changes the word.
- Refreshes within 30 seconds after the local date changes, or after resuming from sleep.
- Optional automatic launch when the current Windows user signs in.
- Works offline. No accounts, API keys, Python, Node.js, or downloads at runtime.

Here is what it looks like:

![Daily Chinese desktop card](assets/preview.png)

## Requirements

- Windows with Windows PowerShell 5.1 and .NET Framework/WPF.
- A Chinese font such as Microsoft YaHei UI, normally included with Windows.
- An extracted app folder that the current user can write to, for saving their current word.

Verified using Windows PowerShell 5.1 on Windows. macOS and Linux are not supported.

## Run

1. Download or clone this repository and extract it into a permanent folder.
2. Double-click **Open Daily Chinese.cmd**.
3. Drag the top of the card to move it. The dash minimises it; the cross or Escape closes it.
4. Click **Skip / Next word**, or press Enter or the right arrow, whenever you want another word.

Alternatively, run this command from the repository folder:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\DailyChinese.ps1
```

The first launch saves a random word in `state.json`. Each new local calendar date
gets another random word. Reopening the app on the same date restores the saved
word. There is no no-repeat history or complete-cycle schedule.

The launchers use a process-only execution-policy override. They do not change
the computer's saved policy. Organisation policy may still restrict scripts.

## Start automatically at sign-in

Double-click **Enable automatic start.cmd**. This creates **Daily Chinese**
shortcuts on the current user's desktop and in their Windows Startup folder.
Use **Open Daily Chinese.cmd** to open the card immediately.

To remove those shortcuts, double-click **Disable automatic start.cmd**, then
close the open card. App files and saved state remain in place.

Keep the app folder in its installed location. To move it, disable automatic
startup, move the folder, and enable startup again. The installer stops if a
shortcut belonging to a different installation already exists.

Only one Daily Chinese card can run per Windows session, including across copies
of this app. Close the existing card before opening another copy.

## Vocabulary and personal state

Edit `words.txt`, a UTF-8 file with pipe-separated fields:

```text
characters|pinyin|english
推诿|tuīwěi|to shift blame or responsibility
斡旋|wòxuán|to mediate between opposing parties
```

Keep at least 365 entries, unique character strings, and all three fields populated.
Do not put a pipe character inside a field. Short definitions and words up to five
Chinese characters fit the current card best. Restart the app after editing.
The vocabulary is curated, rather than an official HSK syllabus or frequency ranking.

`state.json` stores just the local date and current word. To draw a new word,
use the skip button. If the state file is missing, invalid, dated differently,
or names a word removed from the list, the app draws and saves a new word.
Saving is atomic so a failed write does not partially overwrite the existing state.

Older versions used `settings.json` and a fixed start date. That file is no longer
needed or read. Personal state and legacy settings are excluded by `.gitignore`.

## Validate, test, and preview

Run these commands from the repository folder:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\DailyChinese.ps1 -Validate
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\Test-WordEngine.ps1
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\DailyChinese.ps1 -PreviewPath "$PWD\preview.png"
```

Validation checks the vocabulary count, missing fields, and duplicate words.
Tests cover first launch, same-day reopening, saved skips, date changes, permitted
repeats, changed vocabulary, and recovery from invalid state. Tests use a temporary
state file; validation and preview do not write the user's state or install startup.

The test script accepts `-ScratchDirectory` if a specific writable test folder is needed.

## Files

| File | Purpose |
| --- | --- |
| `DailyChinese.ps1` | WPF interface, skip button, and daily refresh timer |
| `WordEngine.ps1` | Random selection and saved current-word state |
| `words.txt` | Vocabulary, pinyin, and English meanings |
| `tests/Test-WordEngine.ps1` | Checks random selection and persistence |
| `Open Daily Chinese.cmd` | Opens the app without requiring a terminal |
| `Install.ps1` / `Uninstall.ps1` | Add or remove the two shortcuts |
| `Enable automatic start.cmd` / `Disable automatic start.cmd` | Double-click wrappers for shortcut setup |
| `state.json` | Personal state, generated locally and not committed |

## Put this on GitHub

Create an empty repository and upload this folder's contents, including `assets`,
`tests`, `.gitignore`, and `.gitattributes`. Do not upload personal `state.json`,
legacy `settings.json`, or Windows shortcuts.

If using Git, run these commands inside this folder, replacing the final URL:

```bash
git init
git add .
git commit -m "Add Daily Chinese desktop app"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/daily-chinese.git
git push -u origin main
```

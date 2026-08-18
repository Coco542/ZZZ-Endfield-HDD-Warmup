# HDD File Warm-Up for ZZZ & Arknights: Endfield

A simple PowerShell utility that reads selected game files before launching **Zenless Zone Zero (ZZZ)** or **Arknights: Endfield**.

It is primarily intended for players who have the game installed on an **HDD** and experience stuttering or temporary freezes caused by initial file access after launching the game.

## How does it work?

The script recursively goes through the selected game directory, opens each file for reading, reads its contents sequentially, and then closes the file.

This gives Windows an opportunity to cache recently accessed data before the game starts. Windows controls the file cache automatically, so this does **not** guarantee that all data will remain cached until the game is launched.

The goal is simply to perform the initial HDD file access **before** you start playing rather than while the game is loading assets during the first launch.

## What does it do?

- Recursively scans the selected game directory.
- Reads the files sequentially using a 4 MB buffer.
- Closes each file after reading it.
- Shows the number of files read, total data read, speed, elapsed time, and read errors.
- Can skip selected directories.
- Can automatically skip mod folders whose names start with `DISABLED` when using the optional XXMI/ZZMI/EFMI mods path setting.

## What does it NOT do?

The script is completely read-only with regard to the game files. It does **not**:

- modify game files
- delete game files
- replace game files
- inject DLLs
- modify game memory
- interact with the game process
- install additional software
- download anything

## Supported games

- **Zenless Zone Zero (ZZZ)**
- **Arknights: Endfield**

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or newer
- The game installed on an HDD for the intended use case

SSD users can run the script, but the benefit is expected to be small or negligible because SSDs already have much lower access latency.

## Usage

### 1. Download the script

Choose the script for your game:

- `HDD-Warmup-ZenlessZoneZero.ps1`
- `HDD-Warmup-ArknightsEndfield.ps1`

### 2. Check the game path

Open the `.ps1` file in a text editor and find the `$paths` section.

Change the path to the directory where your game is installed if it differs from the default example.

For example:

```powershell
$paths = @(
    'D:\Program Files\HoYoPlay\games\ZenlessZoneZero Game\ZenlessZoneZero_Data'
)
```

### 3. Optional: configure your mod folder

The scripts can optionally detect mod folders whose names start with `DISABLED` and exclude them from the warm-up.

If you do not use the corresponding XXMI/ZZMI/EFMI setup, set `$modsPath` to `$null`.

### 4. Run the script

You can run the `.ps1` file with PowerShell.

If Windows blocks script execution because of your current PowerShell execution policy, you can run the script for this launch only with:

```powershell
powershell.exe -ExecutionPolicy Bypass -File ".\HDD-Warmup-ZenlessZoneZero.ps1"
```

Replace the filename with the Endfield script when appropriate.

You do **not** need to permanently change your PowerShell execution policy for this script.

### 5. Wait for the warm-up to finish

The script waits 5 seconds after starting and then begins reading the selected files.

Do not launch the game until the warm-up has finished.

Depending on the size of the game installation and the speed of your HDD, this may take several minutes or longer.

## HDD usage

High HDD usage while the script is running is **expected**. The script is intentionally reading a large number of game files sequentially.

The script does not make an HDD faster; it simply moves some of the initial file-reading work to **before** the game starts.

The actual benefit depends on your HDD, Windows file-cache behavior, game installation, and system configuration. There is no guarantee that the script will eliminate stuttering or freezes.

## Excluded files and folders

You can add directories that should not be warmed up to `$excludePaths` in the script.

For example, the ZZZ script excludes:

```text
StreamingAssets\Video
```

This prevents large video files from being read unnecessarily.

## Statistics

After the warm-up, the script displays:

- **Files** — number of successfully read files
- **Read** — total amount of data read
- **Errors** — number of files that could not be read
- **Speed** — average read speed during the operation
- **Time** — total elapsed time

If one or more files cannot be read, the script displays a warning at the end. A read error does not stop the entire warm-up process.

## License

This project is licensed under the **MIT License**.

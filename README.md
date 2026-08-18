# HDD File Warm-Up for ZZZ & Arknights: Endfield

A simple PowerShell script that warms up game files before launching
Zenless Zone Zero (ZZZ) or Arknights: Endfield.

## What does it do?

The script opens and reads the selected game files and then closes them.
This allows Windows to cache the data before the game starts.

This may help reduce stuttering and temporary freezes during the first
launch, especially when the game is installed on an HDD.

## Supported games

- Zenless Zone Zero
- Arknights: Endfield

## Important

The script only reads the game files.

It does NOT:

- modify game files
- delete game files
- replace game files
- inject DLLs
- modify game memory
- interact with the game process

It is intended primarily for HDD users. SSD users are unlikely to see
a significant benefit.

## Usage

1. Download `HDD-Warmup.ps1`.
2. Edit the game paths in the script if necessary.
3. Run the script with PowerShell.
4. Wait for the file warm-up to finish.
5. Launch the game.

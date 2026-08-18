# ============================================================
# HDD WARM-UP
# ZENLESS ZONE ZERO
# ============================================================

# Delay after starting the script (seconds)
$startupDelay = 5

# Read buffer size
$bufferSize = 4MB

# Change this path to your game installation directory
$paths = @(
    'D:\XXMI Launcher\ZZMI\ShaderCache',
    'D:\XXMI Launcher\ZZMI\Mods',
    'D:\Program Files\HoYoPlay\games\ZenlessZoneZero Game\ZenlessZoneZero_Data'
)

# Folders that should NOT be warmed up
$excludePaths = @(
    'D:\Program Files\HoYoPlay\games\ZenlessZoneZero Game\ZenlessZoneZero_Data\StreamingAssets\Video'
    # 'D:\Program Files\HoYoPlay\games\ZenlessZoneZero Game\ZenlessZoneZero_Data\StreamingAssets\Blocks'
)

# Optional: path to your ZZMI Mods folder.
# Disabled mod folders whose names start with "DISABLED" will be skipped.
# Set to $null if you do not use ZZMI or do not want this behavior.
$modsPath = 'D:\XXMI Launcher\ZZMI\Mods'

# ============================================================
# STARTUP DELAY
# ============================================================

Write-Host "=========================================="
Write-Host "Zenless Zone Zero HDD Warm-Up"
Write-Host "=========================================="
Write-Host ""
Write-Host "Waiting $startupDelay seconds..."
Start-Sleep -Seconds $startupDelay

# ============================================================
# FIND DISABLED MODS
# ============================================================

if ($null -ne $modsPath -and (Test-Path -LiteralPath $modsPath -PathType Container)) {

    $disabledMods = Get-ChildItem `
        -LiteralPath $modsPath `
        -Directory `
        -Force `
        -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name.StartsWith(
                'DISABLED',
                [System.StringComparison]::OrdinalIgnoreCase
            )
        }

    if ($null -ne $disabledMods) {
        foreach ($disabledMod in $disabledMods) {
            $excludePaths += $disabledMod.FullName
        }
    }
}

# ============================================================
# NORMALIZE EXCLUDED PATHS
# ============================================================

$excludePaths = @(
    $excludePaths |
    Where-Object {
        -not [string]::IsNullOrWhiteSpace($_)
    } |
    ForEach-Object {
        $_.TrimEnd('\')
    }
)

# ============================================================
# SHOW EXCLUDED PATHS
# ============================================================

Write-Host ""
Write-Host "Excluded folders:"
Write-Host "------------------------------------------"

foreach ($excludePath in $excludePaths) {
    Write-Host $excludePath
}

Write-Host "------------------------------------------"

# ============================================================
# FUNCTION: CHECK IF PATH IS EXCLUDED
# ============================================================

function Test-IsExcludedPath {
    param (
        [string]$Path
    )

    foreach ($excludePath in $excludePaths) {

        if (
            $Path.Equals(
                $excludePath,
                [System.StringComparison]::OrdinalIgnoreCase
            ) -or
            $Path.StartsWith(
                $excludePath + '\',
                [System.StringComparison]::OrdinalIgnoreCase
            )
        ) {
            return $true
        }
    }

    return $false
}

# ============================================================
# FUNCTION: ENUMERATE FILES
# ============================================================

function Get-WarmupFiles {
    param (
        [string]$Directory
    )

    # Get files directly inside this directory
    Get-ChildItem `
        -LiteralPath $Directory `
        -File `
        -Force `
        -ErrorAction SilentlyContinue |
        ForEach-Object {

            if (-not (Test-IsExcludedPath $_.FullName)) {
                $_
            }
        }

    # Get subdirectories
    Get-ChildItem `
        -LiteralPath $Directory `
        -Directory `
        -Force `
        -ErrorAction SilentlyContinue |
        ForEach-Object {

            $directoryPath = $_.FullName

            # Completely skip excluded directories
            if (Test-IsExcludedPath $directoryPath) {
                return
            }

            # Recursively process allowed directories
            Get-WarmupFiles -Directory $directoryPath
        }
}

# ============================================================
# PREPARE
# ============================================================

$totalBytes = 0
$totalFiles = 0
$totalErrors = 0
$globalStart = Get-Date

$buffer = New-Object byte[] $bufferSize

# ============================================================
# PROCESS PATHS
# ============================================================

foreach ($path in $paths) {

    if (-not (Test-Path -LiteralPath $path -PathType Container)) {
        Write-Host ""
        Write-Host "NOT FOUND: $path"
        continue
    }

    # If the entire root path is excluded, skip it
    if (Test-IsExcludedPath $path) {
        Write-Host ""
        Write-Host "SKIPPED: $path"
        continue
    }

    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Scanning:"
    Write-Host $path
    Write-Host "=========================================="

    $pathStart = Get-Date
    $pathBytes = 0
    $pathFiles = 0
    $pathErrors = 0

    # --------------------------------------------------------
    # Enumerate files
    # --------------------------------------------------------

    Get-WarmupFiles -Directory $path |
        ForEach-Object {

            $file = $_
            $stream = $null

            try {

                $stream = New-Object System.IO.FileStream(
                    $file.FullName,
                    [System.IO.FileMode]::Open,
                    [System.IO.FileAccess]::Read,
                    [System.IO.FileShare]::ReadWrite,
                    $bufferSize,
                    [System.IO.FileOptions]::SequentialScan
                )

                while (($read = $stream.Read(
                    $buffer,
                    0,
                    $buffer.Length
                )) -gt 0) {

                    $pathBytes += $read
                }

                $pathFiles++

                # ------------------------------------------------
                # Progress
                # ------------------------------------------------

                $pathGB = [math]::Round(
                    $pathBytes / 1GB,
                    2
                )

                $elapsed = (Get-Date) - $pathStart

                if ($elapsed.TotalSeconds -gt 0) {

                    $speedMB = (
                        $pathBytes /
                        1MB /
                        $elapsed.TotalSeconds
                    )

                    Write-Host -NoNewline (
                        "`rFiles: {0} | Read: {1} GB | Speed: {2:N1} MB/s" -f `
                        $pathFiles,
                        $pathGB,
                        $speedMB
                    )
                }
            }

            catch {

                $pathErrors++
                $totalErrors++

                Write-Host ""
                Write-Host "READ ERROR:"
                Write-Host $file.FullName
                Write-Host "ERROR: $($_.Exception.Message)"
            }

            finally {

                if ($null -ne $stream) {
                    $stream.Dispose()
                }
            }
        }

    Write-Host ""

    # --------------------------------------------------------
    # Path statistics
    # --------------------------------------------------------

    $pathTime = (Get-Date) - $pathStart

    $pathGB = [math]::Round(
        $pathBytes / 1GB,
        2
    )

    $pathSpeed = 0

    if ($pathTime.TotalSeconds -gt 0) {

        $pathSpeed = (
            $pathBytes /
            1MB /
            $pathTime.TotalSeconds
        )
    }

    $totalBytes += $pathBytes
    $totalFiles += $pathFiles

    Write-Host ""
    Write-Host "Read:    $pathGB GB"
    Write-Host "Files:   $pathFiles"
    Write-Host "Errors:  $pathErrors"
    Write-Host "Speed:   $([math]::Round($pathSpeed, 1)) MB/s"

    $pathHours = [int]$pathTime.TotalHours

    $pathTimeFormatted = "{0}:{1:00}:{2:00}" -f `
        $pathHours,
        $pathTime.Minutes,
        $pathTime.Seconds

    Write-Host "Time:    $pathTimeFormatted"
}

# ============================================================
# FINAL STATISTICS
# ============================================================

$totalTime = (Get-Date) - $globalStart

$totalGB = [math]::Round(
    $totalBytes / 1GB,
    2
)

$totalSpeed = 0

if ($totalTime.TotalSeconds -gt 0) {

    $totalSpeed = (
        $totalBytes /
        1MB /
        $totalTime.TotalSeconds
    )
}

$totalHours = [int]$totalTime.TotalHours

$totalTimeFormatted = "{0}:{1:00}:{2:00}" -f `
    $totalHours,
    $totalTime.Minutes,
    $totalTime.Seconds

Write-Host ""
Write-Host "=========================================="
Write-Host "HDD WARM-UP FINISHED"
Write-Host "=========================================="
Write-Host "Files:   $totalFiles"
Write-Host "Read:    $totalGB GB"
Write-Host "Errors:  $totalErrors"
Write-Host "Speed:   $([math]::Round($totalSpeed, 1)) MB/s"
Write-Host "Time:    $totalTimeFormatted"
Write-Host "=========================================="

if ($totalErrors -gt 0) {
    Write-Host ""
    Write-Host "WARNING: Some files could not be read."
}

Write-Host ""
Write-Host "Exiting in 5 seconds..."

Start-Sleep -Seconds 5
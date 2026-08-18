# ============================================================
# HDD WARM-UP
# ZZZ + ZZMI
# ============================================================

# Задержка после запуска скрипта
$startupDelay = 5

# Размер буфера чтения
$bufferSize = 4MB

# Папки для прогрева
$paths = @(
    # 'D:\XXMI Launcher\EFMI\ShaderCache'
    # 'D:\XXMI Launcher\EFMI\Mods'
    'D:\Program Files\GRYPHLINK\games\EndField Game\Endfield_Data'
)

# Папки, которые НЕ нужно прогревать
$excludePaths = @(
    # 'D:\Program Files\HoYoPlay\games\ZenlessZoneZero Game\ZenlessZoneZero_Data\StreamingAssets\Video'
    # 'D:\Program Files\HoYoPlay\games\ZenlessZoneZero Game\ZenlessZoneZero_Data\StreamingAssets\Blocks'
)

# ============================================================
# WAIT AFTER WINDOWS START
# ============================================================

Write-Host "=========================================="
Write-Host "ZZZ + ZZMI HDD Warm-Up"
Write-Host "=========================================="
Write-Host ""
Write-Host "Waiting $startupDelay seconds..."
Start-Sleep -Seconds $startupDelay

# ============================================================
# FIND DISABLED MODS
# ============================================================

$modsPath = 'D:\XXMI Launcher\EFMI\Mods'

if (Test-Path -LiteralPath $modsPath -PathType Container) {

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

    $excludePaths += $disabledMods.FullName
}

# ============================================================
# PREPARE
# ============================================================

$totalBytes = 0
$totalFiles = 0
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

    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Scanning:"
    Write-Host $path
    Write-Host "=========================================="

    $pathStart = Get-Date
    $pathBytes = 0
    $pathFiles = 0

    # --------------------------------------------------------
    # Enumerate files
    # --------------------------------------------------------

    Get-ChildItem `
        -LiteralPath $path `
        -Recurse `
        -Force `
        -File `
        -ErrorAction SilentlyContinue |
        Where-Object {

            $filePath = $_.FullName

            -not (
                $excludePaths | Where-Object {

                    $excludePath = $_.TrimEnd('\')

                    $filePath.StartsWith(
                        $excludePath + '\',
                        [System.StringComparison]::OrdinalIgnoreCase
                    ) -or
                    $filePath.Equals(
                        $excludePath,
                        [System.StringComparison]::OrdinalIgnoreCase
                    )
                }
            )
        } |
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
    Write-Host "Speed:   $([math]::Round($pathSpeed, 1)) MB/s"
    Write-Host "Time:    $($pathTime.ToString('hh\:mm\:ss'))"
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

Write-Host ""
Write-Host "=========================================="
Write-Host "HDD WARM-UP FINISHED"
Write-Host "=========================================="
Write-Host "Files:   $totalFiles"
Write-Host "Read:    $totalGB GB"
Write-Host "Speed:   $([math]::Round($totalSpeed, 1)) MB/s"
Write-Host "Time:    $($totalTime.ToString('hh\:mm\:ss'))"
Write-Host "=========================================="

Write-Host ""
Write-Host "Exiting in 5 seconds..."

Start-Sleep -Seconds 5
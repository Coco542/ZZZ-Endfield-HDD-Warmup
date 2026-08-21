# ============================================================
# HDD WARM-UP
# ZENLESS ZONE ZERO
# HDD OPTIMIZED - BLOCKS SPECIALIZED v2.0
# ============================================================

$startupDelay = 5

# ============================================================
# SMALL FILES
# ============================================================

$smallFileThreshold = 1MB
$smallFileWorkers = 2
$smallBufferSize = 64KB

# ============================================================
# MEDIUM FILES
# ============================================================

$mediumFileThreshold = 10MB
$mediumBufferSize = 4MB

# ============================================================
# LARGE FILES
# ============================================================

$largeBufferSize = 8MB

# ============================================================
# PROGRESS SETTINGS
# ============================================================

# Console refresh interval.
# Does NOT affect HDD reading.
$progressIntervalMs = 250

# ============================================================
# PATHS
# ============================================================

$paths = @(
    'D:\XXMI Launcher\ZZMI\ShaderCache',
    'D:\XXMI Launcher\ZZMI\Mods',
    'D:\Program Files\HoYoPlay\games\ZenlessZoneZero Game\ZenlessZoneZero_Data'
)

# ============================================================
# EXCLUDED PATHS
# ============================================================

$excludePaths = @(
    'D:\Program Files\HoYoPlay\games\ZenlessZoneZero Game\ZenlessZoneZero_Data\StreamingAssets\Video'
)

$modsPath = 'D:\XXMI Launcher\ZZMI\Mods'

# ============================================================
# STARTUP
# ============================================================

Clear-Host

Write-Host "=========================================="
Write-Host " ZENLESS ZONE ZERO"
Write-Host " HDD WARM-UP v2.0"
Write-Host "=========================================="
Write-Host ""
Write-Host " Small files:    < $([math]::Round($smallFileThreshold / 1MB, 0)) MB"
Write-Host " Small workers:  $smallFileWorkers"
Write-Host " Small buffer:   $([math]::Round($smallBufferSize / 1KB, 0)) KB"
Write-Host ""
Write-Host " Medium files:   >= $([math]::Round($smallFileThreshold / 1MB, 0)) MB - < $([math]::Round($mediumFileThreshold / 1MB, 0)) MB"
Write-Host " Medium buffer:  $([math]::Round($mediumBufferSize / 1MB, 0)) MB"
Write-Host ""
Write-Host " Large files:    >= $([math]::Round($mediumFileThreshold / 1MB, 0)) MB"
Write-Host " Large buffer:   $([math]::Round($largeBufferSize / 1MB, 0)) MB"
Write-Host ""
Write-Host " Waiting $startupDelay seconds..."

Start-Sleep -Seconds $startupDelay

# ============================================================
# FIND DISABLED MODS
# ============================================================

if (
    $null -ne $modsPath -and
    (Test-Path -LiteralPath $modsPath -PathType Container)
) {

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

    foreach ($disabledMod in $disabledMods) {

        $excludePaths += $disabledMod.FullName
    }
}

# ============================================================
# NORMALIZE EXCLUSIONS
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
# EXCLUSION CHECK
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
# ENUMERATE FILES
# ============================================================

function Get-WarmupFiles {

    param (
        [string]$Directory
    )

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

    Get-ChildItem `
        -LiteralPath $Directory `
        -Directory `
        -Force `
        -ErrorAction SilentlyContinue |
        ForEach-Object {

            if (Test-IsExcludedPath $_.FullName) {
                return
            }

            Get-WarmupFiles `
                -Directory $_.FullName
        }
}

# ============================================================
# FORMAT TIME
# ============================================================

function Format-TimeSpan {

    param (
        [TimeSpan]$Time
    )

    if ($Time.TotalSeconds -lt 0) {
        return "--:--"
    }

    $hours = [int]$Time.TotalHours

    if ($hours -gt 0) {

        return "{0}:{1:00}:{2:00}" -f `
            $hours,
            $Time.Minutes,
            $Time.Seconds
    }

    return "{0:00}:{1:00}" -f `
        $Time.Minutes,
        $Time.Seconds
}

# ============================================================
# PROGRESS DISPLAY
# ============================================================

function Show-Progress {

    param (
        [string]$CurrentPath,
        [long]$BytesRead,
        [long]$TotalBytes,
        [int]$FilesRead,
        [int]$TotalFiles,
        [datetime]$StartTime,
        [string]$CurrentFile,
        [string]$Type,
        [string]$Buffer,
        [int]$Errors
    )

    if ($TotalBytes -gt 0) {

        $percent = (
            $BytesRead /
            $TotalBytes *
            100
        )
    }
    else {

        $percent = 0
    }

    $percent = [math]::Max(
        0,
        [math]::Min(
            100,
            $percent
        )
    )

    # --------------------------------------------------------
    # SPEED
    # --------------------------------------------------------

    $elapsed = (
        Get-Date
    ) - $StartTime

    $speed = 0

    if ($elapsed.TotalSeconds -gt 0) {

        $speed = (
            $BytesRead /
            1MB /
            $elapsed.TotalSeconds
        )
    }

    # --------------------------------------------------------
    # ETA
    # --------------------------------------------------------

    $remainingSeconds = 0

    if (
        $speed -gt 0 -and
        $BytesRead -gt 0
    ) {

        $remainingBytes = (
            $TotalBytes -
            $BytesRead
        )

        $remainingSeconds = (
            $remainingBytes /
            1MB /
            $speed
        )
    }

    $remaining = [TimeSpan]::FromSeconds(
        [math]::Max(
            0,
            $remainingSeconds
        )
    )

    # --------------------------------------------------------
    # PROGRESS BAR
    # --------------------------------------------------------

    $barWidth = 20

    $filled = [int][math]::Floor(
        $barWidth *
        $percent /
        100
    )

    $filled = [math]::Max(
        0,
        [math]::Min(
            $barWidth,
            $filled
        )
    )

    $empty = (
        $barWidth -
        $filled
    )

    $bar = (
        "[" +
        ("█" * $filled) +
        ("░" * $empty) +
        "]"
    )

    # --------------------------------------------------------
    # CURRENT FILE
    # --------------------------------------------------------

    $relativeFile = $CurrentFile

    if (
        -not [string]::IsNullOrWhiteSpace(
            $CurrentFile
        )
    ) {

        try {

            if (
                $CurrentFile.StartsWith(
                    $CurrentPath,
                    [System.StringComparison]::OrdinalIgnoreCase
                )
            ) {

                $relativeFile = $CurrentFile.Substring(
                    $CurrentPath.Length
                ).TrimStart(
                    [char]'\'
                )
            }
        }
        catch {

            $relativeFile = Split-Path `
                -Leaf `
                -Path $CurrentFile
        }
    }

    if (
        [string]::IsNullOrWhiteSpace(
            $relativeFile
        )
    ) {

        $relativeFile = "-"
    }

    if ($relativeFile.Length -gt 45) {

        $relativeFile = (
            "..." +
            $relativeFile.Substring(
                $relativeFile.Length - 42
            )
        )
    }

    # --------------------------------------------------------
    # TIME
    # --------------------------------------------------------

    $elapsedText = Format-TimeSpan $elapsed
    $remainingText = Format-TimeSpan $remaining

    # --------------------------------------------------------
    # DATA
    # --------------------------------------------------------

    $readGB = (
        $BytesRead /
        1GB
    )

    $totalGB = (
        $TotalBytes /
        1GB
    )

    # --------------------------------------------------------
    # BUILD LINE
    # --------------------------------------------------------

    $line = (
        "{0} {1:N1}% | {2:N2}/{3:N2} GB | {4}/{5} files | {6:N1} MB/s | {7} | ETA {8} | {9}"
    ) -f `
        $bar,
        $percent,
        $readGB,
        $totalGB,
        $FilesRead,
        $TotalFiles,
        $speed,
        $elapsedText,
        $remainingText,
        $relativeFile

    # --------------------------------------------------------
    # FIT CONSOLE
    # --------------------------------------------------------

    try {

        $consoleWidth = [Console]::WindowWidth

        if ($consoleWidth -gt 1) {

            if (
                $line.Length -ge (
                    $consoleWidth - 1
                )
            ) {

                $line = $line.Substring(
                    0,
                    $consoleWidth - 1
                )
            }
            else {

                $line = $line.PadRight(
                    $consoleWidth - 1
                )
            }
        }
    }
    catch {
    }

    # --------------------------------------------------------
    # DRAW
    # --------------------------------------------------------

    [Console]::Write(
        "`r" + $line
    )
}

# ============================================================
# SMALL WORKER
# ============================================================

$smallWorkerScript = {

    param (
        [object[]]$Files,
        [int]$BufferSize
    )

    [long]$bytesRead = 0
    $filesRead = 0
    $errors = 0

    $buffer = New-Object byte[] $BufferSize

    foreach ($file in $Files) {

        $stream = $null

        try {

            $stream = New-Object System.IO.FileStream(
                $file.FullName,
                [System.IO.FileMode]::Open,
                [System.IO.FileAccess]::Read,
                [System.IO.FileShare]::ReadWrite,
                $BufferSize,
                [System.IO.FileOptions]::SequentialScan
            )

            while (
                (
                    $read = $stream.Read(
                        $buffer,
                        0,
                        $buffer.Length
                    )
                ) -gt 0
            ) {

                $bytesRead += $read
            }

            $filesRead++
        }

        catch {

            $errors++
        }

        finally {

            if ($null -ne $stream) {

                $stream.Dispose()
            }
        }
    }

    [PSCustomObject]@{
        Bytes  = $bytesRead
        Files  = $filesRead
        Errors = $errors
    }
}

# ============================================================
# TOTAL STATISTICS
# ============================================================

$totalBytes = [long]0
$totalFiles = 0
$totalErrors = 0

$globalStart = Get-Date

# ============================================================
# PROCESS PATHS
# ============================================================

foreach ($path in $paths) {

    if (
        -not (
            Test-Path `
                -LiteralPath $path `
                -PathType Container
        )
    ) {

        Write-Host ""
        Write-Host "NOT FOUND: $path"

        continue
    }

    if (Test-IsExcludedPath $path) {

        continue
    }

    Write-Host ""
    Write-Host "=========================================="
    Write-Host " Scanning:"
    Write-Host " $path"
    Write-Host "=========================================="
    Write-Host ""
    Write-Host " Preparing..."

    # --------------------------------------------------------
    # ENUMERATE
    # --------------------------------------------------------

    $files = @(
        Get-WarmupFiles `
            -Directory $path
    )

    $pathFilesTotal = $files.Count

    [long]$pathTotalBytes = 0

    if ($pathFilesTotal -gt 0) {

        $pathTotalBytes = (
            $files |
            Measure-Object `
                -Property Length `
                -Sum
        ).Sum
    }

    # --------------------------------------------------------
    # GROUP FILES
    # --------------------------------------------------------

    $smallFiles = @(
        $files |
        Where-Object {
            $_.Length -lt $smallFileThreshold
        }
    )

    $mediumFiles = @(
        $files |
        Where-Object {
            $_.Length -ge $smallFileThreshold -and
            $_.Length -lt $mediumFileThreshold
        }
    )

    $largeFiles = @(
        $files |
        Where-Object {
            $_.Length -ge $mediumFileThreshold
        }
    )

    # --------------------------------------------------------
    # PATH START
    # --------------------------------------------------------

    Write-Host ""

    $pathStart = Get-Date

    [long]$pathBytes = 0
    $pathFiles = 0
    $pathErrors = 0

    $script:LastProgressUpdate = [datetime]::MinValue

    # ========================================================
    # SMALL FILES
    # ========================================================

    [long]$smallBytes = 0

    if ($smallFiles.Count -gt 0) {

        $smallBytes = [long](
            ($smallFiles | Measure-Object -Property Length -Sum).Sum
        )

        $pool = [RunspaceFactory]::CreateRunspacePool(
            1,
            $smallFileWorkers
        )

        $pool.Open()

        $runspaces = @()

        $batches = @()

        for (
            $i = 0;
            $i -lt $smallFileWorkers;
            $i++
        ) {

            $batches += ,(
                New-Object System.Collections.Generic.List[object]
            )
        }

        for (
            $i = 0;
            $i -lt $smallFiles.Count;
            $i++
        ) {

            $index = (
                $i %
                $smallFileWorkers
            )

            $batches[$index].Add(
                $smallFiles[$i]
            )
        }

        foreach ($batch in $batches) {

            if ($batch.Count -eq 0) {

                continue
            }

            $powershell = [PowerShell]::Create()

            $powershell.RunspacePool = $pool

            [void]$powershell.AddScript(
                $smallWorkerScript
            )

            [void]$powershell.AddArgument(
                [object[]]$batch.ToArray()
            )

            [void]$powershell.AddArgument(
                $smallBufferSize
            )

            $handle = $powershell.BeginInvoke()

            $runspaces += [PSCustomObject]@{
                PowerShell = $powershell
                Handle = $handle
                BatchSize = $batch.Count
            }
        }

        while ($true) {

            $completed = 0

            foreach ($runspace in $runspaces) {

                if ($runspace.Handle.IsCompleted) {

                    $completed++
                }
            }

            # ------------------------------------------------
            # SMALL PROGRESS
            # ------------------------------------------------

            $estimatedFiles = 0

            foreach ($runspace in $runspaces) {

                if ($runspace.Handle.IsCompleted) {

                    $estimatedFiles += (
                        $runspace.BatchSize
                    )
                }
            }

            if (
                (
                    (Get-Date) -
                    $script:LastProgressUpdate
                ).TotalMilliseconds -ge $progressIntervalMs
            ) {

                $estimatedBytes = 0

                if ($smallFiles.Count -gt 0) {

                    $ratio = (
                        $estimatedFiles /
                        $smallFiles.Count
                    )

                    $estimatedBytes = [long](
                        $smallBytes *
                        $ratio
                    )
                }

                Show-Progress `
                    -CurrentPath $path `
                    -BytesRead (
                        $pathBytes +
                        $estimatedBytes
                    ) `
                    -TotalBytes $pathTotalBytes `
                    -FilesRead (
                        $pathFiles +
                        $estimatedFiles
                    ) `
                    -TotalFiles $pathFilesTotal `
                    -StartTime $pathStart `
                    -CurrentFile "Small files / $smallFileWorkers workers" `
                    -Type "SMALL" `
                    -Buffer "$([math]::Round($smallBufferSize / 1KB, 0)) KB" `
                    -Errors $pathErrors

                $script:LastProgressUpdate = Get-Date
            }

            if (
                $completed -eq
                $runspaces.Count
            ) {

                break
            }

            Start-Sleep -Milliseconds 50
        }

        foreach ($runspace in $runspaces) {

            try {

                $result = $runspace.PowerShell.EndInvoke(
                    $runspace.Handle
                )

                foreach ($item in $result) {

                    $pathBytes += $item.Bytes
                    $pathFiles += $item.Files
                    $pathErrors += $item.Errors
                }
            }

            catch {

                $pathErrors++
            }

            finally {

                $runspace.PowerShell.Dispose()
            }
        }

        $pool.Close()
        $pool.Dispose()
    }

    # ========================================================
    # MEDIUM FILES
    # ========================================================

    if ($mediumFiles.Count -gt 0) {

        $buffer = New-Object byte[] $mediumBufferSize

        foreach ($file in $mediumFiles) {

            $stream = $null

            try {

                $stream = New-Object System.IO.FileStream(
                    $file.FullName,
                    [System.IO.FileMode]::Open,
                    [System.IO.FileAccess]::Read,
                    [System.IO.FileShare]::ReadWrite,
                    $mediumBufferSize,
                    [System.IO.FileOptions]::SequentialScan
                )

                while (
                    (
                        $read = $stream.Read(
                            $buffer,
                            0,
                            $buffer.Length
                        )
                    ) -gt 0
                ) {

                    $pathBytes += $read

                    if (
                        (
                            (Get-Date) -
                            $script:LastProgressUpdate
                        ).TotalMilliseconds -ge $progressIntervalMs
                    ) {

                        Show-Progress `
                            -CurrentPath $path `
                            -BytesRead $pathBytes `
                            -TotalBytes $pathTotalBytes `
                            -FilesRead $pathFiles `
                            -TotalFiles $pathFilesTotal `
                            -StartTime $pathStart `
                            -CurrentFile $file.Name `
                            -Type "MEDIUM" `
                            -Buffer "4 MB" `
                            -Errors $pathErrors

                        $script:LastProgressUpdate = Get-Date
                    }
                }

                $pathFiles++
            }

            catch {

                $pathErrors++
            }

            finally {

                if ($null -ne $stream) {

                    $stream.Dispose()
                }
            }
        }
    }

    # ========================================================
    # LARGE FILES
    # ========================================================

    if ($largeFiles.Count -gt 0) {

        $buffer = New-Object byte[] $largeBufferSize

        foreach ($file in $largeFiles) {

            $stream = $null

            try {

                $stream = New-Object System.IO.FileStream(
                    $file.FullName,
                    [System.IO.FileMode]::Open,
                    [System.IO.FileAccess]::Read,
                    [System.IO.FileShare]::ReadWrite,
                    $largeBufferSize,
                    [System.IO.FileOptions]::SequentialScan
                )

                while (
                    (
                        $read = $stream.Read(
                            $buffer,
                            0,
                            $buffer.Length
                        )
                    ) -gt 0
                ) {

                    $pathBytes += $read

                    if (
                        (
                            (Get-Date) -
                            $script:LastProgressUpdate
                        ).TotalMilliseconds -ge $progressIntervalMs
                    ) {

                        Show-Progress `
                            -CurrentPath $path `
                            -BytesRead $pathBytes `
                            -TotalBytes $pathTotalBytes `
                            -FilesRead $pathFiles `
                            -TotalFiles $pathFilesTotal `
                            -StartTime $pathStart `
                            -CurrentFile $file.Name `
                            -Type "LARGE" `
                            -Buffer "8 MB" `
                            -Errors $pathErrors

                        $script:LastProgressUpdate = Get-Date
                    }
                }

                $pathFiles++
            }

            catch {

                $pathErrors++
            }

            finally {

                if ($null -ne $stream) {

                    $stream.Dispose()
                }
            }
        }
    }

    # ========================================================
    # FINAL PROGRESS
    # ========================================================

    Show-Progress `
        -CurrentPath $path `
        -BytesRead $pathBytes `
        -TotalBytes $pathTotalBytes `
        -FilesRead $pathFiles `
        -TotalFiles $pathFilesTotal `
        -StartTime $pathStart `
        -CurrentFile "Completed" `
        -Type "DONE" `
        -Buffer "-" `
        -Errors $pathErrors

    [Console]::WriteLine("")

    # ========================================================
    # PATH STATISTICS
    # ========================================================

    $pathTime = (
        Get-Date
    ) - $pathStart

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
    $totalErrors += $pathErrors

    Write-Host ""
    Write-Host "=========================================="
    Write-Host " PATH FINISHED"
    Write-Host "=========================================="
    Write-Host " Path:       $path"
    Write-Host " Read:       $([math]::Round($pathBytes / 1GB, 2)) GB"
    Write-Host " Files:      $pathFiles / $pathFilesTotal"
    Write-Host " Errors:     $pathErrors"
    Write-Host " Speed:      $([math]::Round($pathSpeed, 1)) MB/s"
    Write-Host " Time:       $(Format-TimeSpan $pathTime)"
    Write-Host "=========================================="
}

# ============================================================
# FINAL STATISTICS
# ============================================================

$totalTime = (
    Get-Date
) - $globalStart

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
Write-Host " ZENLESS ZONE ZERO"
Write-Host " HDD WARM-UP FINISHED"
Write-Host "=========================================="
Write-Host ""
Write-Host " Files:           $totalFiles"
Write-Host " Read:            $totalGB GB"
Write-Host " Errors:          $totalErrors"
Write-Host " Speed:           $([math]::Round($totalSpeed, 1)) MB/s"
Write-Host " Time:            $(Format-TimeSpan $totalTime)"
Write-Host ""
Write-Host " Small workers:   $smallFileWorkers"
Write-Host " Small threshold: $([math]::Round($smallFileThreshold / 1MB, 0)) MB"
Write-Host " Small buffer:    $([math]::Round($smallBufferSize / 1KB, 0)) KB"
Write-Host " Medium buffer:   $([math]::Round($mediumBufferSize / 1MB, 0)) MB"
Write-Host " Large buffer:    $([math]::Round($largeBufferSize / 1MB, 0)) MB"
Write-Host "=========================================="

if ($totalErrors -gt 0) {

    Write-Host ""
    Write-Host "WARNING: Some files could not be read."
}

Write-Host ""
Write-Host "Exiting in 5 seconds..."

Start-Sleep -Seconds 5
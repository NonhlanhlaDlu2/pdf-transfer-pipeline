param(
    [string]$Date = (Get-Date -Format "yyyy-MM-dd")
)

# -- Configuration -------------------------------------------------------------
# Update these values to match your environment

$SRN_LIST      = @(
    "AB0303",
    "CD1234"
    # Add more SRNs here, one per line, in quotes followed by a comma
)

$SOURCE_FOLDER = "H:\Reports\719"
$READY_FOLDER  = "H:\Reports\Dailys\ACPAS"
$LOG_FOLDER    = "H:\Reports\Dailys\logs"

# -- Setup folders -------------------------------------------------------------
if (-not (Test-Path $READY_FOLDER)) { New-Item -ItemType Directory -Path $READY_FOLDER -Force | Out-Null }
if (-not (Test-Path $LOG_FOLDER))   { New-Item -ItemType Directory -Path $LOG_FOLDER   -Force | Out-Null }

$LogFile = Join-Path $LOG_FOLDER ("transfer_" + (Get-Date -Format "yyyyMMdd") + ".log")

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $line = "{0}  {1,-8}  {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -Path $LogFile -Value $line
    Write-Host $line
}

# -- Validate source folder ----------------------------------------------------
if (-not (Test-Path $SOURCE_FOLDER)) {
    Write-Log "ERROR: Source folder not found: $SOURCE_FOLDER" "ERROR"
    exit 1
}

Write-Log "============================================================"
Write-Log "PDF Transfer Pipeline - starting"
Write-Log "Source folder: $SOURCE_FOLDER"
Write-Log "Ready folder : $READY_FOLDER"
Write-Log "SRNs to process: $($SRN_LIST.Count)"
Write-Log "============================================================"

$totalCopied  = 0
$totalSkipped = 0
$totalFailed  = 0
$totalMissing = 0

# -- Process each SRN ---------------------------------------------------------
foreach ($SRN in $SRN_LIST) {
    $SRN = $SRN.Trim().ToUpper()
    Write-Log "------------------------------------------------------------"
    Write-Log "Processing SRN: $SRN"

    # Match folders where SRN is first 6 chars OR appears after a date prefix
    $allItems     = Get-ChildItem -Path $SOURCE_FOLDER -Directory -ErrorAction SilentlyContinue
    $matchingItems = $allItems | Where-Object {
        $_.Name.StartsWith($SRN) -or $_.Name -match ("^\d+_" + $SRN + "_")
    }

    if ($matchingItems -eq $null -or $matchingItems.Count -eq 0) {
        Write-Log "No folders found for SRN: $SRN" "WARN"
        $totalMissing++
        continue
    }

    Write-Log "Found $($matchingItems.Count) folder(s) for SRN: $SRN"

    foreach ($item in $matchingItems) {
        $destination = Join-Path $READY_FOLDER $item.Name

        # Skip if folder already exists - no duplicates
        if (Test-Path $destination) {
            Write-Log "Skipped (already exists): $($item.Name)" "WARN"
            $totalSkipped++
            continue
        }

        try {
            Copy-Item -Path $item.FullName -Destination $destination -Recurse -Force
            Write-Log "Copied: $($item.Name)"
            $totalCopied++
        } catch {
            Write-Log "FAILED: $($item.Name) - $_" "ERROR"
            $totalFailed++
        }
    }
}

# -- Summary -------------------------------------------------------------------
Write-Log "============================================================"
Write-Log "Transfer complete"
Write-Log "  Copied  : $totalCopied folder(s)"
Write-Log "  Skipped : $totalSkipped folder(s) already existed"
Write-Log "  Missing : $totalMissing SRN(s) had no matching folders"
Write-Log "  Failed  : $totalFailed folder(s)"
Write-Log "============================================================"

Write-Host ""
Write-Host "Transfer complete!" -ForegroundColor Green
Write-Host "  Copied  : $totalCopied" -ForegroundColor White
Write-Host "  Skipped : $totalSkipped (already in folder)" -ForegroundColor Yellow
if ($totalMissing -gt 0) {
    Write-Host "  Missing : $totalMissing SRN(s) had no folders" -ForegroundColor Yellow
}
if ($totalFailed -gt 0) {
    Write-Host "  Failed  : $totalFailed" -ForegroundColor Red
}
Write-Host ""
Write-Host "Files are ready at: $READY_FOLDER" -ForegroundColor Cyan

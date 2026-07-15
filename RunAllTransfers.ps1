# -- Master PDF Transfer Script ------------------------------------------------
# Runs all 6 SRN transfer scripts in sequence
# Scheduled via Task Scheduler to run at 06:00, 12:00 and 20:00 daily

$SCRIPTS_FOLDER = "C:\Scripts\PDFTransfer"
$LOG_FOLDER     = "D:\Reports\Dailys\logs"

if (-not (Test-Path $LOG_FOLDER)) { New-Item -ItemType Directory -Path $LOG_FOLDER -Force | Out-Null }

$LogFile = Join-Path $LOG_FOLDER ("master_transfer_" + (Get-Date -Format "yyyyMMdd") + ".log")

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $line = "{0}  {1,-8}  {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -Path $LogFile -Value $line
    Write-Host $line
}

# -- List of all transfer scripts to run ---------------------------------------
$scripts = @(
    "PDFTransfer_vACPAS.ps1",
    "PDFTransfer_vCALI.ps1",
    "PDFTransfer_vFIN.ps1",
    "PDFTransfer_vFLEXI.ps1",
    "PDFTransfer_vSP2.ps1",
    "PDFTransfer_vSP15.ps1"
)

Write-Log "============================================================"
Write-Log "Master Transfer - starting"
Write-Log "Run time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Log "Scripts to run: $($scripts.Count)"
Write-Log "============================================================"

$successCount = 0
$failCount    = 0

foreach ($script in $scripts) {
    $scriptPath = Join-Path $SCRIPTS_FOLDER $script

    Write-Log "------------------------------------------------------------"
    Write-Log "Running: $script"

    if (-not (Test-Path $scriptPath)) {
        Write-Log "Script not found: $scriptPath" "ERROR"
        $failCount++
        continue
    }

    try {
        & $scriptPath
        Write-Log "Completed: $script" "INFO"
        $successCount++
    } catch {
        Write-Log "FAILED: $script - $_" "ERROR"
        $failCount++
    }
}

Write-Log "============================================================"
Write-Log "Master Transfer complete - $successCount succeeded, $failCount failed"
Write-Log "============================================================"

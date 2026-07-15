[README.md](https://github.com/user-attachments/files/30058987/README.md)
# Automated PDF File Transfer Pipeline

> Automated PowerShell pipeline that collects PDF report folders from a central server location, filters them by SRN (Subscriber Reference Number), and moves them into organised destination folders — replacing a manual daily copy-paste process with a scheduled pipeline that runs three times a day.

---

## Business Problem

In a credit bureau environment, PDF report folders are generated daily and stored in a central server location. Each folder belongs to a specific subscriber identified by a 6-character SRN at the start of the folder name.

Previously, a data operator had to:
1. Remote desktop into the server
2. Manually search through hundreds of folders
3. Identify folders matching each SRN
4. Copy them one by one into the correct destination folders

This process was repeated multiple times a day and was entirely manual.

---

## Solution

A two-layer PowerShell pipeline:

```
H:\Reports\719\ (source - hundreds of mixed folders)
        |
        | PDFTransfer_vACPAS.ps1  - filters by ACPAS SRNs
        | PDFTransfer_vCALI.ps1   - filters by CALI SRNs
        | PDFTransfer_vFIN.ps1    - filters by FIN SRNs
        | PDFTransfer_vFLEXI.ps1  - filters by FLEXI SRNs
        | PDFTransfer_vSP2.ps1    - filters by SP2 SRNs
        | PDFTransfer_vSP15.ps1   - filters by SP15 SRNs
        v
H:\Reports\Dailys\[GROUP]\ (organised destination folders)
        |
        | RunAllTransfers.ps1     - master script runs all 6
        v
Windows Task Scheduler            - runs at 06:00, 12:00, 20:00
```

---

## Tech Stack

| Component | Technology |
|---|---|
| Language | PowerShell 4+ |
| Scheduling | Windows Task Scheduler |
| Server | Windows Server 2012 |
| Authentication | Windows Authentication |

---

## Features

- **SRN-based filtering** -- matches folders by first 6 characters of folder name
- **Dual filename pattern support** -- handles both `SRN_filename` and `YYYYMMDDHHII_SRN_filename` formats
- **Duplicate protection** -- skips folders already in the destination, no overwrites
- **Master runner** -- one script calls all 6 transfer scripts in sequence
- **Three daily runs** -- scheduled at 06:00, 12:00 and 20:00 to catch files as they arrive
- **Full logging** -- every run writes a timestamped log per transfer group
- **Graceful error handling** -- one failed SRN does not stop the rest from running

---

## Project Structure

```
pdf-transfer-pipeline/
|-- RunAllTransfers.ps1          # Master script - runs all 6 transfers
|-- PDFTransfer_Template.ps1     # Template for individual SRN transfer scripts
|-- README.md                    # This file
|-- docs/
|   |-- setup.md                 # Setup and configuration guide
|-- sample_output/
    |-- sample_log.md            # Example log output
```

---

## Setup

### 1. Configure each transfer script

Copy `PDFTransfer_Template.ps1` and create one file per transfer group. Update these values at the top:

```powershell
$SRN_LIST = @(
    "AB0303",
    "AB0304"
    # Add all SRNs for this group
)

$SOURCE_FOLDER = "H:\Reports\719"          # Where all folders come from
$READY_FOLDER  = "H:\Reports\Dailys\ACPAS" # Where this group goes
$LOG_FOLDER    = "H:\Reports\Dailys\logs"
```

### 2. Update the master script

Open `RunAllTransfers.ps1` and update the scripts list and folder path:

```powershell
$SCRIPTS_FOLDER = "C:\Scripts\PDFTransfer"  # Where your scripts live

$scripts = @(
    "PDFTransfer_vACPAS.ps1",
    "PDFTransfer_vCALI.ps1",
    "PDFTransfer_vFIN.ps1",
    "PDFTransfer_vFLEXI.ps1",
    "PDFTransfer_vSP2.ps1",
    "PDFTransfer_vSP15.ps1"
)
```

### 3. Test manually

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\RunAllTransfers.ps1
```

### 4. Schedule with Windows Task Scheduler

- Program: `powershell.exe`
- Arguments: `-ExecutionPolicy Bypass -File "C:\Scripts\PDFTransfer\RunAllTransfers.ps1"`
- Triggers: Daily at **06:00**, **12:00**, and **20:00**
- General: tick "Run whether user is logged on or not" and "Run with highest privileges"

---

## Folder Name Patterns Supported

The script handles two filename formats automatically:

```
# Format 1 - SRN at the start
AB0303_ALL_L702_D_20260610_1_1

# Format 2 - Date prefix before SRN
202601061108_AB0303_ALL_L702_D_20260106_1_1
```

---

## Log Output

Each run writes to `H:\Reports\Dailys\logs\transfer_YYYYMMDD.log`:

```
2026-07-11 06:00:01  INFO      ============================================================
2026-07-11 06:00:01  INFO      PDF Transfer Pipeline - starting
2026-07-11 06:00:01  INFO      Source folder: H:\Reports\719
2026-07-11 06:00:01  INFO      Ready folder : H:\Reports\Dailys\ACPAS
2026-07-11 06:00:01  INFO      SRNs to process: 12
2026-07-11 06:00:01  INFO      ------------------------------------------------------------
2026-07-11 06:00:01  INFO      Processing SRN: AR8888
2026-07-11 06:00:23  INFO      Found 145 folder(s) for SRN: AR8888
2026-07-11 06:00:23  WARN      Skipped (already exists): AR8888_ALL_L702_D_20251104_1_1
2026-07-11 06:00:23  INFO      Copied: AR8888_ALL_L702_D_20260711_1_1
2026-07-11 06:00:23  INFO      ============================================================
2026-07-11 06:00:23  INFO      Transfer complete
2026-07-11 06:00:23  INFO        Copied  : 1 folder(s)
2026-07-11 06:00:23  INFO        Skipped : 144 folder(s) already existed
2026-07-11 06:00:23  INFO        Missing : 0 SRN(s) had no matching folders
2026-07-11 06:00:23  INFO        Failed  : 0 folder(s)
```

---

## Background

Built to automate a repetitive daily manual process at a South African credit bureau. Part of an ongoing data automation initiative to free up data operations time for higher-value work.

---

## Author

**Nonhlanhla** | Senior Data Operator transitioning to Data Engineering

- 6 years experience with SQL Server, SSIS, and data pipeline operations
- AWS Cloud Practitioner certified
- Azure Data Fundamentals certified

---

## Licence

MIT -- free to use, adapt, and build on.

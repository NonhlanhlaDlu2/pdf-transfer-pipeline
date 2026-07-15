[setup.md](https://github.com/user-attachments/files/30058923/setup.md)
# Setup Guide

## Prerequisites

- Windows Server with PowerShell 4 or higher
- Access to the source folder containing PDF report folders
- Write access to the destination folders

## Step 1 -- Verify PowerShell version

Run in PowerShell ISE as Administrator:

```powershell
$PSVersionTable.PSVersion
```

You need Major version 4 or higher.

## Step 2 -- Verify source folder access

```powershell
Test-Path "H:\Reports\719"
Get-ChildItem "H:\Reports\719" | Select-Object -First 5
```

## Step 3 -- Create destination folders

The scripts create these automatically, but you can pre-create them:

```powershell
New-Item -ItemType Directory -Path "H:\Reports\Dailys\ACPAS"  -Force
New-Item -ItemType Directory -Path "H:\Reports\Dailys\CALI"   -Force
New-Item -ItemType Directory -Path "H:\Reports\Dailys\FIN"    -Force
New-Item -ItemType Directory -Path "H:\Reports\Dailys\FLEXI"  -Force
New-Item -ItemType Directory -Path "H:\Reports\Dailys\SP2"    -Force
New-Item -ItemType Directory -Path "H:\Reports\Dailys\SP15"   -Force
New-Item -ItemType Directory -Path "H:\Reports\Dailys\logs"   -Force
```

## Step 4 -- Test a single transfer script

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
.\PDFTransfer_vACPAS.ps1
```

Check the log at `H:\Reports\Dailys\logs\transfer_YYYYMMDD.log`

## Step 5 -- Test the master script

```powershell
.\RunAllTransfers.ps1
```

All 6 scripts should run in sequence.

## Step 6 -- Schedule with Task Scheduler

1. Open Task Scheduler
2. Click Create Task
3. General tab:
   - Name: PDF Transfer Pipeline
   - Tick: Run whether user is logged on or not
   - Tick: Run with highest privileges
4. Triggers tab - add 3 triggers:
   - Daily at 06:00
   - Daily at 12:00
   - Daily at 20:00
5. Actions tab:
   - Program: powershell.exe
   - Arguments: -ExecutionPolicy Bypass -File "C:\Scripts\PDFTransfer\RunAllTransfers.ps1"
6. Settings tab:
   - Tick: Run task as soon as possible after a scheduled start is missed

## Troubleshooting

**No folders found for SRN**
- Verify the SRN is exactly 6 characters
- Check the folder exists in the source: `Get-ChildItem "H:\Reports\719" | Where-Object { $_.Name.StartsWith("AB0303") }`

**InitializeDefaultDrives error**
- This is a harmless server profile error in PowerShell ISE
- The script continues running normally despite this message

**Folders skipped unexpectedly**
- The folder already exists in the destination
- This is by design - duplicate protection prevents overwrites
- Delete the destination folder manually if you need to re-copy it

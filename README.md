# Automated Remediation of SQL Server Backup Failures and Root Cause Analysis

## Table of Contents

- [Overview](#overview)
- [Summary at a Glance](#summary-at-a-glance)
- [Tools and Technologies Used](#tools-and-technologies-used)
- [Project Context](#project-context)
- [Project Structure](#project-structure)
- [Incident Trigger](#incident-trigger)
- [Investigation and Remediation Steps](#investigation-and-remediation-steps)

  - [1. Initial Space Recovery](#1-initial-space-recovery)
  - [2. Storage Analysis](#2-storage-analysis)
  - [3. SQL Server Maintenance Plan Review](#3-sql-server-maintenance-plan-review)
  - [4. Manual Backup Management](#4-manual-backup-management)
  - [5. Additional Drive Cleanup](#5-additional-drive-cleanup)
  - [6. SQL Space and Backup Analysis](#6-sql-space-and-backup-analysis)

- [Failure Root Cause Identification](#failure-root-cause-identification)
- [Permanent Fixes and Testing](#permanent-fixes-and-testing)
- [Root Cause Summary](#root-cause-summary)
- [Preventative Measures](#preventative-measures)
- [Skills Showcased](#skills-showcased)
- [Lessons Learned](#lessons-learned)
- [Conclusion](#conclusion)

## Overview

This project documents a high-impact incident I resolved as a Cloud Engineer at **SEIDOR Networks** for the client **[HCE Medical Group](https://www.hcemedicalgroup.com)**. A critical alert was raised due to low disk space on their production SQL Server (`HCE-SQL01`).

Through a structured and step-by-step approach, I diagnosed the root causes, retained backups and an offline database, and implemented automated cleanup scripts, SQL configuration fixes, and long-term monitoring controls. This resolved the issue and prevented future backup failures. The project showcases technical troubleshooting, database administration, scripting, and preventative system design.

## Summary at a Glance

> Resolved SQL Server backup failure by automating disk cleanups, isolating maintenance job faults, and implementing long-term monitoring to prevent recurrence. The issue was identified in a production environment and fully mitigated within two working days. Full backup functionality was restored within 24 hours, followed by three days of post-resolution monitoring.

---

## Tools and Technologies Used

| Tool / Technology      | Purpose                                                    | Link                                                                                |
| ---------------------- | ---------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| SQL Server             | Database engine used for backup and maintenance operations | [Link](https://www.microsoft.com/en-us/sql-server)                                  |
| PowerShell             | Automated cleanup and user profile management scripts      | [Link](https://learn.microsoft.com/en-us/powershell/)                               |
| Windows Server         | Operating system hosting the SQL services                  | [Link](https://www.microsoft.com/en-us/windows-server)                              |
| N-Central RMM          | Triggered disk space alerts and monitored server health    | [Link](https://www.n-able.com/products/n-central-rmm/network-and-device-management) |
| TreeSize Free          | Used to visualise and analyse disk space usage             | [Link](https://www.jam-software.com/treesize_free)                                  |
| WinDirStat             | Disk usage statistics and cleanup planning                 | [Link](https://sourceforge.net/projects/windirstat/)                                |
| Everything Search Tool | Assisted in locating large files across drives quickly     | [Link](https://www.voidtools.com/downloads/)                                        |

---

## Project Context

This issue occurred in a live production environment where consistent backups were critical. I was directly responsible for responding to infrastructure alerts and worked independently to investigate and implement the full solution. Time sensitivity was crucial due to the risk of backup failures and potential data loss.

---

## Project Structure

```
automated-sql-backup-remediation/
├── images
├── pwsh-scripts
│   ├── cleanup-recycle-bin.ps1
│   └── cleanup-user-temp.ps1
├── README.md
└── sql-scripts
    ├── sql-check-free-disk.sql
    ├── sql-estimate-db-sizes.sql
    ├── sql-last-full-backups.sql
    └── sql-recent-backups-location.sql
```

---

## Incident Trigger

An urgent alert was triggered by the N-Central RMM tool for critically low disk space on the production SQL Server `HCE-SQL01`. Specifically, the D: drive—designated for SQL data and backups—had dropped to only **12.88 GB free** out of 750 GB total capacity.

![disk-alert.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/disk-alert.png)

---

## Investigation and Remediation Steps

### 1. Initial Space Recovery

To stabilise the system and begin freeing space:

- Logged into `HCE-SQL01` and executed Disk Cleanup.
- Deleted temp files using a CLI batch command:

```cmd
del /q /f /s %temp%\*
```

![del-temp-files.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/del-temp-files.png)

---

### 2. Storage Analysis

To diagnose the space usage breakdown:

- Installed **WinDirStat** and **TreeSize** for comprehensive drive analysis.
- Identified `.bak` SQL backups as the main contributor to saturation.

![treesize-rpt-1.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/treesize-rpt-1.png)
![treesize-rpt-2.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/treesize-rpt-2.png)
![treesize-rpt-3.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/treesize-rpt-3.png)

---

### 3. SQL Server Maintenance Plan Review

- Verified that a backup cleanup task existed but was not executing.
- Job history revealed consistent failures related to disk space exhaustion.

![sql-maintenance-plan-1.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/sql-maintenance-plan-1.png)
![sql-maintenance-plan-2.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/sql-maintenance-plan-2.png)
![job-history.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/job-history.png)

---

### 4. Manual Backup Management

- Compressed old `.bak` files to reclaim disk space.

![compressed-baks.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/compressed-baks.png)

- Migrated files to alternate drives with sufficient storage.

![mv-baks-e-drive.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/mv-baks-e-drive.png)
![mv-baks-f-drive.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/mv-baks-f-drive.png)

---

### 5. Additional Drive Cleanup

- Executed PowerShell scripts to remove temp data and recycle bin contents across user profiles.

```powershell
Get-ChildItem -Path "C:\Users" -Directory | ForEach-Object {
    $tempPath = Join-Path $_.FullName "AppData\Local\Temp"
    if (Test-Path $tempPath) {
        Remove-Item "$tempPath\*" -Force -Recurse -ErrorAction SilentlyContinue
    }
}
```

```powershell
$users = Get-ChildItem -Path "C:\Users" -Directory |
         Where-Object { $_.Name -notin @("Default", "Public") }
foreach ($user in $users) {
    $userSID = (Get-Acl $user.FullName).Owner
    $userBin = "C:\$Recycle.Bin\$userSID"
    if (Test-Path $userBin) {
        Remove-Item "$userBin\*" -Force -Recurse -ErrorAction SilentlyContinue
    }
}
```

> The cleanup scripts are stored in the `pwsh-scripts/` directory.

---

### 6. SQL Space and Backup Analysis

To accurately assess storage needs and validate backup behaviours, I executed a sequence of SQL diagnostic queries that provided key insights into database sizes, recent backup history, backup destinations, and available drive capacity.

**a. Estimating Current Database Sizes**

The query below aggregates size data across all online databases, showing both megabytes and gigabytes. This helped assess how much space each database consumes and plan capacity accordingly.

```sql
SELECT
    d.name AS DatabaseName,
    CONVERT(DECIMAL(10,2), SUM(mf.size) * 8 / 1024) AS EstimatedSizeMB,
    CONVERT(DECIMAL(10,2), SUM(mf.size) * 8 / 1024 / 1024) AS EstimatedSizeGB
FROM
    sys.master_files mf
JOIN
    sys.databases d ON d.database_id = mf.database_id
WHERE
    d.state = 0  -- Online databases
GROUP BY
    d.name
ORDER BY
    EstimatedSizeGB DESC;
```

![sql-query-1.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/sql-query-1.png)

---

**b. Verifying the Last Full Backups and Sizes**

This query provided a quick overview of the last completed full backups, along with the size and compressed size for each database. It confirmed that backup operations had been occurring, albeit inconsistently due to job failures.

```sql
SELECT
    database_name,
    MAX(backup_finish_date) AS last_backup,
    MAX(backup_size / 1024 / 1024) AS size_MB,
    MAX(compressed_backup_size / 1024 / 1024) AS compressed_size_MB
FROM msdb.dbo.backupset
WHERE type = 'D' -- Full backups
GROUP BY database_name
ORDER BY compressed_size_MB DESC;
```

![sql-query-2.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/sql-query-2.png)

---

**c. Mapping Backup Destinations by Drive**

To ensure backups were being written to the correct drives and not inadvertently consuming C:\ or system partitions, I queried the physical device paths of recent full backups across the last 7 days. This also revealed if multiple drives were being used inappropriately.

```sql
SELECT
    bs.database_name,
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.backup_size / 1024 / 1024 AS backup_size_mb,
    bmf.physical_device_name,
    LEFT(bmf.physical_device_name, 1) AS drive_letter
FROM msdb.dbo.backupset bs
JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
WHERE bs.backup_start_date >= DATEADD(DAY, -7, GETDATE()) -- last 7 days
  AND bs.type = 'D'  -- Full database backup
ORDER BY bs.backup_start_date DESC;
```

![sql-query-3.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/sql-query-3.png)

---

**d. Measuring Free Space on Drives**

Lastly, I executed the undocumented but reliable `xp_fixeddrives` stored procedure to display real-time free space (in MB) for all available drives. This allowed me to align estimated backup sizes with available capacity.

```sql
EXEC xp_fixeddrives;

-- Optional: Estimate total required space for upcoming backup
-- Example:
-- Drive D: needs 34,200 MB
-- Drive E: needs 12,000 MB
```

![sql-query-4.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/sql-query-4.png)

---

> All SQL diagnostic scripts are available in the `sql-scripts/` directory.

---

## Failure Root Cause Identification

The SQL Agent job logs revealed the core issue:

- The backup job failed entirely because it attempted to process an offline database (`MP_LIVE`), which halted execution of all subsequent steps—including cleanup.

![man-job-fail.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/man-job-fail.png)
![log-file-path.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/log-file-path.png)
![log-txt-ouput.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/log-txt-ouput.png)

---

## Permanent Fixes and Testing

- Modified the SQL Maintenance Plan to exclude offline databases during the backup cycle.

![updated-plan-1.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/updated-plan-1.png)
![updated-plan-2.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/updated-plan-2.png)

- Retested the job to verify that it completed without errors.

![man-job-success.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/man-job-success.png)

- Removed temporary logs and archived older backups in a designated `Compressed Older Backups` folder.

![disk-alert-resolved.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/disk-alert-resolved.png)
![cleared-disk-space.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/cleared-disk-space.png)

---

## Root Cause Summary

The primary failure stemmed from a maintenance plan attempting to back up an offline database. This caused the entire job to abort before reaching the cleanup stage. As a result, backup files accumulated over time, exhausting available disk space and compounding system instability.

---

## Preventative Measures

- Configured SQL Agent jobs to skip inaccessible databases.
- Set automated alerts for:

  - Low disk thresholds:

    - D: Drive = 35.5 GB
    - E: Drive = 12.5 GB

  - Any future SQL Agent failures.

- Validated backups daily for one week post-resolution.

---

## Skills Showcased

- **SQL Server Administration** – Maintenance plans, backup management, and failure isolation.
- **PowerShell Automation** – System-level scripts to perform consistent, user-wide cleanup.
- **Root Cause Analysis** – Correlating job logs, file growth, and service behaviour.
- **Monitoring & Observability** – Leveraging RMM alerts and log files for early detection.
- **Incident Response** – Restored stability within a critical 48-hour SLA.
- **Documentation** – Reproducible report reflecting real-world cloud engineering responsibility.

---

## Lessons Learned

- Job chains must account for partial failures. An offline database should not break the entire backup pipeline.
- Cleanup tasks should be fail-safe and decoupled from backup completion status.
- Compression and relocation are safer alternatives to deletion under pressure.
- Visibility into log output is essential during postmortems and troubleshooting.

---

## Conclusion

This project reflects my ability to respond decisively under production pressure, solve complex infrastructure issues independently, and implement long-term fixes through automation and preventative design. It highlights the mindset and execution expected of a Cloud Engineer responsible for production reliability and business continuity.

---

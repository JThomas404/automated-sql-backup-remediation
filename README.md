# Automated Remediation of SQL Server Backup Failures and Root Cause Analysis

## Table of Contents

- [Overview](#overview)
- [Summary at a Glance](#summary-at-a-glance)
- [Tools and Technologies Used](#tools-and-technologies-used)
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

> Resolved SQL Server backup failure by automating disk cleanups, isolating maintenance job faults, and implementing long-term monitoring to prevent recurrence. Issue was identified in production and mitigated within 2 working days, with full backup functionality restored within 24 hours and post-monitoring conducted over 3 additional days.

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

## Incident Trigger

- The RMM platform triggered an alert for low disk space on the SQL Server `HCE-SQL01`.
- Specifically, the **D: drive** (dedicated to SQL Data and backups) had only **12.88 GB free** of 750 GB.

![disk-alert.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/disk-alert.png)

## Investigation and Remediation Steps

### 1. Initial Space Recovery

To begin immediate recovery:

- Logged into `HCE-SQL01`.
- Ran built-in Windows Disk Cleanup.
- Cleared user temp files using the command:

```cmd
del /q /f /s %temp%\*
```

![del-temp-files.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/del-temp-files.png)

### 2. Storage Analysis

To analyse storage usage:

- Installed **WinDirStat** to visualise file distribution.
- Generated a **TreeSize** report for detailed usage insights.
- Identified large `.bak` SQL backup files as the primary source of drive saturation.

![treesize-rpt-1.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/treesize-rpt-1.png)
![treesize-rpt-2.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/treesize-rpt-2.png)
![treesize-rpt-3.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/treesize-rpt-3.png)

### 3. SQL Server Maintenance Plan Review

Upon reviewing the SQL Server Maintenance Plan:

- Confirmed that a cleanup task existed to delete backups older than 14 days.

![sql-maintenance-plan-1.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/sql-maintenance-plan-1.png)
![sql-maintenance-plan-2.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/sql-maintenance-plan-2.png)

- However, this step was not executing properly due to low disk space.
- The cleanup failed, and the backup job continued, leading to backup file accumulation.

![job-history.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/job-history.png)

### 4. Manual Backup Management

To restore available space:

- Compressed older backups.

![compressed-baks.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/compressed-baks.png)

- Manually moved them to other drives with available space.

![mv-baks-e-drive.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/mv-baks-e-drive.png)
![mv-baks-f-drive.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/mv-baks-f-drive.png)

- Verified file integrity after transfer.

### 5. Additional Drive Cleanup

To remove residual clutter and stale data:

- Executed PowerShell scripts to clean each user profile’s temp folder.
- Emptied each user’s Recycle Bin.

> All the PowerShell scripts can be located in the `pwsh-scripts` directory.

### 6. SQL Space and Backup Analysis

To verify backup size and drive requirements:

- Used SQL queries to assess:

  - Space needed per database
  - Backup sizes
  - Destination paths
  - Compared with drive free space using `xp_fixeddrives`

![sql-query-1.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/sql-query-1.png)
![sql-query-2.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/sql-query-2.png)
![sql-query-3.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/sql-query-3.png)
![sql-query-4.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/sql-query-4.png)

> All the SQL queries can be located in the `sql-scripts` directory.

## Failure Root Cause Identification

After redirecting SQL Agent job logs to a local `.txt` file, the root cause was confirmed:

- The job failed because it attempted to back up a database (`MP_LIVE`) that was **offline**.

![man-job-fail-1.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/man-job-fail-1.png)
![log-file-path.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/log-file-path.png)
![log-txt-ouput.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/log-txt-ouput.png)

> Error: "Database 'MP_LIVE' cannot be opened because it is offline. BACKUP DATABASE is terminating abnormally."

## Permanent Fixes and Testing

- Updated the SQL Maintenance Plan to **ignore offline databases**.

![updated-plan-1.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/updated-plan-1.png)
![updated-plan-2.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/updated-plan-2.png)

- Manually reran the job, which completed successfully.

![man-job-success.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/man-job-success.png)

- Removed the temporary job log file.
- Archived compressed backups to `D:\Compressed Older Backups`.

The ticket resolved and the alert unflagged.

![disk-alert-resolved.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/disk-alert-resolved.png)

The disk space was now showing a healthy amount of free disk space — from **12.88 GB** to **129 GB** free on SQL Data Drive (D:).

![cleared-disk-space.png](https://github.com/JThomas404/automated-sql-backup-remediation/raw/main/images/cleared-disk-space.png)

## Root Cause Summary

The most critical issue was the Maintenance Plan’s lack of logic to skip offline databases and its sequential dependency on cleanup. When the cleanup task failed due to low disk space, backups continued without deleting older files. Then, when encountering an offline database (`MP_LIVE`), the entire backup job failed, compounding the storage problem.

## Preventative Measures

- Verified that the backup jobs executed successfully over several days.
- Enabled alerting for:

  - Failed SQL Agent jobs
  - Low disk space thresholds:

    - D: Drive — 35.5 GB
    - E: Drive — 12.5 GB

- Reconfigured the Maintenance Plan to skip offline databases automatically.

## Skills Showcased

**Impact Metrics**:

- Recovered disk space: from **12.88 GB** to **129 GB** free on SQL Data Drive (D:)
- Time to resolution: **2 working days**, plus **3 days** post-resolution monitoring
- Backup restoration: **fully operational within 24 hours**

**Key Skills**:

- **Database Management** – Administered SQL Server maintenance plans and backup scheduling
- **Troubleshooting** – Used logs and scripts to isolate complex SQL Server issues
- **Root Cause Diagnostics** – Applied investigative methods to trace cascading failures
- **PowerShell Automation** – Developed custom scripts for system-wide cleanup
- **Monitoring and Alerting** – Integrated SQL alerts with RMM thresholds
- **Capacity Planning** – Interpreted file system and database usage with TreeSize and SQL
- **Documentation** – Presented a detailed, reproducible incident report
- **Preventative Design** – Hardened backup systems to avoid repeat failures

## Lessons Learned

- Disk space constraints can silently disable critical tasks (e.g. cleanup routines), leading to compounding failures.
- Backup routines must account for offline or transitioning databases.
- Observability (logging, alerting) is vital for diagnosing backup job failures.
- Manual cleanups are not sustainable—automation must be part of long-term recovery.
- Working under production risk requires caution and planning. Rather than deleting old backups, I opted to compress and safely relocate them, test restoration manually, and gradually restore order.

## Conclusion

This project demonstrates my ability to analyse, remediate, and future-proof production SQL Server environments using a blend of scripting, root cause analysis, and preventative configuration. The structured response ensured minimal downtime and restored reliable backup operations without data loss.

---

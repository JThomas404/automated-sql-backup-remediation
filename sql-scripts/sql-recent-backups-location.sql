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
  AND bs.type = 'D'  -- 'D' = Full database backup
ORDER BY bs.backup_start_date DESC;

SELECT
    database_name,
    MAX(backup_finish_date) AS last_backup,
    MAX(backup_size / 1024 / 1024) AS size_MB,
    MAX(compressed_backup_size / 1024 / 1024) AS compressed_size_MB
FROM msdb.dbo.backupset
WHERE type = 'D' -- Full backups
GROUP BY database_name
ORDER BY compressed_size_MB DESC;

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

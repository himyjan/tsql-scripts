-----------------------------------------------------------------
-- Monitor replication jobs
--
-- rudi@babaluga.com, go ahead license
-----------------------------------------------------------------

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

WITH LastError AS (
    SELECT
        j.job_id,
        j.name AS JobName,
        jh.run_status,
        jh.run_date,
        jh.run_time,
        jh.message,
        ROW_NUMBER() OVER (PARTITION BY j.job_id ORDER BY jh.run_date DESC, jh.run_time DESC) AS rn
    FROM msdb.dbo.sysjobs j
    INNER JOIN msdb.dbo.syscategories c ON j.category_id = c.category_id
    INNER JOIN msdb.dbo.sysjobhistory jh ON j.job_id = jh.job_id
    WHERE c.name IN ('REPL-Distribution', 'REPL-LogReader', 'REPL-Snapshot')
    AND j.enabled = 1
)
SELECT
    job_id,
    JobName,
    run_status,
    CASE
        WHEN run_status = 0 THEN 'Failed'
        WHEN run_status = 1 THEN 'Success'
        WHEN run_status = 2 THEN 'Retry'
        WHEN run_status = 3 THEN 'Cancelled'
        WHEN run_status = 4 THEN 'In Progress'
        ELSE 'Unknown'
    END AS run_status_desc,
    run_date,
    run_time,
    message
FROM LastError
WHERE rn = 1
ORDER BY run_date DESC, run_time DESC
OPTION (RECOMPILE, MAXDOP 1);

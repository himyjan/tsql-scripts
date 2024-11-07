---------------------------------------------------------------------------------------------------
-- Estimate compression savings for all tables and indices in a database
-- code adapted from Glenn Gerry : 
-- https://www.sqlskills.com/blogs/glenn/estimating-data-compression-savings-in-sql-server-2012/

-- rudi@babaluga.com, go ahead license
---------------------------------------------------------------------------------------------------

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET STATISTICS IO OFF;

DECLARE @CompressionType nvarchar(60) = N'PAGE'; -- desired data compression type (PAGE, ROW, or NONE)

IF OBJECT_ID('tempdb..#compression_savings') IS NOT NULL
	DROP TABLE #compression_savings

CREATE TABLE #compression_savings (
    object_name sysname,
    schema_name sysname,
    index_id int,
    partition_number int,
    size_with_current_compression_setting bigint,
    size_with_requested_compression_setting bigint,
    sample_size_with_current_compression_setting bigint,
    sample_size_with_requested_compression_setting bigint
)

DECLARE cur CURSOR FAST_FORWARD
FOR
    SELECT 
        i.index_id, 
        p.partition_number,
        OBJECT_NAME(t.[object_id]),
        SCHEMA_NAME(t.schema_id)
    FROM sys.indexes i
    JOIN sys.tables t ON i.[object_id] = t.[object_id]
	JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
    WHERE t.type_desc = N'USER_TABLE'
	AND t.is_ms_shipped = 0
    ORDER BY i.index_id;

OPEN cur;

DECLARE @idx int, @part int;
DECLARE @Schema sysname, @Table sysname;

FETCH NEXT FROM cur INTO @idx, @part, @Table, @Schema;

WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            INSERT INTO #compression_savings
            EXEC sp_estimate_data_compression_savings @Schema, @Table, @idx, @part, @CompressionType;
        END TRY
        BEGIN CATCH
            PRINT 'Error estimating compression savings for ' + QUOTENAME(@Schema) + '.' + QUOTENAME(@Table) + ' index ' + @idx + ' partition ' + @part + ': ' + ERROR_MESSAGE();
        END CATCH

        FETCH NEXT FROM cur INTO @idx, @part, @Table, @Schema;
    END

CLOSE cur;
DEALLOCATE cur;

;WITH cte AS (
    SELECT QUOTENAME(schema_name) + '.' + QUOTENAME(object_name) as [table],
        i.name as [index],
		CASE i.type_desc
			WHEN 'NONCLUSTERED' THEN 'NC'
			WHEN 'CLUSTERED' THEN 'CL'
			ELSE i.type_desc
		END as t,
		cs.partition_number,
		p.data_compression_desc as [compression],
        100 - CAST((100.0 * size_with_requested_compression_setting) / NULLIF(size_with_current_compression_setting, 0) as decimal(5, 2)) as [% to gain],
        CAST(size_with_current_compression_setting / 1024.0 as decimal (20,2)) as [current size MB],
        CAST(size_with_requested_compression_setting / 1024.0 as decimal (20,2)) as [compressed size MB]
    FROM #compression_savings cs
    JOIN sys.indexes i ON cs.index_id = i.index_id AND i.object_id = OBJECT_ID(QUOTENAME(schema_name) + '.' + QUOTENAME(object_name))
	JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id AND cs.partition_number = p.partition_number
)
SELECT *,
    [current size MB] - [compressed size MB] as [saved size MB],
    SUM([current size MB]) OVER () as [total current MB],
    SUM([compressed size MB]) OVER () as [total MB compressed],
    SUM([current size MB] - [compressed size MB]) OVER () as [total saved MB]
FROM cte;
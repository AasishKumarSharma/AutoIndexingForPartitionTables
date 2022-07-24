-- TARGET SQL SERVER: MSSQL SERVER 2016+
-- =============================================
-- Author:		Aasish Kumar Sharma
-- Create date: 2022-07-04
-- Description:	Rebuild fragmented indexes for selected partition tables.
-- =============================================
ALTER PROCEDURE [web].[AutoIndexingForPartitionTables]
	@CommaSeparatedPartitionedTableNamesForIndexing NVARCHAR(MAX) = N'PartitionedTable1, PartitionedTable2, PartitionTable3'
AS 
BEGIN

	DECLARE 
		@FragmentationPercentFrom INT = 20
		, @FragmentationPercentTo INT = 100
		, @SQL_INDEX NVARCHAR(MAX) = N'';

	-- Generate sql script to execute.
	WITH TBL_OBJ AS 
		(
			SELECT  RTRIM(LTRIM([value])) AS OBJ_NAME FROM STRING_SPLIT(@CommaSeparatedPartitionedTableNamesForIndexing, ',')
		)  
	
	SELECT 
		@SQL_INDEX = STUFF((SELECT DISTINCT CONCAT(N'; ' + CHAR(13) + CHAR(10) + 'ALTER INDEX ALL ON [', TBL_IX.[Schema], '].[', TBL_IX.[Table], '] REBUILD PARTITION = ', TBL_IX.partition_number, ' WITH (ONLINE = OFF)' + CHAR(13) + CHAR(10))
	FROM (
			SELECT 
				dbschemas.[name] AS 'Schema',
				dbtables.[name] AS 'Table',
				dbindexes.[name] AS 'Index',
				indexstats.avg_fragmentation_in_percent AS 'Frag (%)',
				indexstats.avg_fragment_size_in_pages AS 'Frag (pages)',
				indexstats.page_count AS 'Page count',
				indexstats.partition_number
			FROM 
				TBL_OBJ
				INNER JOIN sys.tables dbtables ON dbtables.[name] = TBL_OBJ.OBJ_NAME
				CROSS APPLY
				sys.dm_db_index_physical_stats (DB_ID(), dbtables.[object_id], NULL, NULL, NULL) AS indexstats	
				INNER JOIN sys.schemas dbschemas ON dbtables.[schema_id] = dbschemas.[schema_id]
				INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]	
					AND indexstats.index_id = dbindexes.index_id	
			WHERE 
				dbindexes.[name] IS NOT NULL
				AND indexstats.avg_fragmentation_in_percent BETWEEN @FragmentationPercentFrom AND @FragmentationPercentTo	
		) AS TBL_IX 
		FOR XML PATH(''), type).value('.', 'nvarchar(max)'), 1, 2, '');

	--SELECT @SQL_INDEX;
	PRINT (@SQL_INDEX);
	EXEC (@SQL_INDEX);

END  

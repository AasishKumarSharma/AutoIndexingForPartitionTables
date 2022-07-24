# Auto Indexing for Partationed Tables in MSSQL
## Rebuild fragmented indexes for selected partitioned tables.

- Currently, this MSSQL Stored Procedure will rebuild all the indexes of that particular partition of the selected partitioned table whose index fragementation level is above 20%. 
- This phenomenon can be modified by changing the alter command in the autogenerating script. 
- Also, the fragementation level could be redefined as required.
- Besides, it only requires a nvarchar data type of parameter. That will contain comma separated names of the partitioned tables.

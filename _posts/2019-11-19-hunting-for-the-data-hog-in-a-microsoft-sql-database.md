---
layout: post
title: Hunting for the Data Hog in a Microsoft SQL Database
date: 2019-11-19 08:00:00 +0400
author: larry
image: assets/images/posts/2019-11-19-hunting-for-the-data-hog-in-a-microsoft-sql-database/data-hog-image-main.jpg
imageshadow: true
tags: [SQL, Database]
---

I am not a DBA, but I play one when no one is looking.  I typically get asked, "why is my database so large"?  I have found that it's normally a table that no one is watching.  An application's customer table is always watched by everyone and they often offers suggestions to reduce it's size.  No one is looking at a log stored in the database or over indexing of a large table.
First, I like to gather row counts of each table in a database.  The below SQL query will find user tables in the database and return a count of rows for each table.

```sql
SELECT
SCHEMA_NAME(sOBJ.schema_id) + '.' + sOBJ.name AS [TableName]
,SUM(sPTN.Rows) AS [RowCount]
FROM sys.objects AS sOBJ
INNER JOIN sys.partitions AS sPTN ON sOBJ.object_id = sPTN.object_id
WHERE sOBJ.type = 'U' AND sOBJ.is_ms_shipped = 0x0
AND index_id < 2 -- 0:Heap, 1:Clustered
GROUP BY sOBJ.schema_id , sOBJ.name
ORDER BY [TableName]
---Thank you to <https://www.mssqltips.com/sqlservertip/2537/sql-server-row-count-for-all-tables-in-a-database/>
```

I will often run this sorting by TableName, as well as, by RowCount to get a clear picture of which tables are holding a lot of data rows.  Of course, some times the number of rows in a table aren't the real size problem. I also run the SQL query below to see the real size of a table.

```sql
SELECT
s.name + '.' + t.Name AS [Table Name],
CAST((SUM( DISTINCT au.Total_pages) * 8 ) / 1024.000 / 1024.000 AS NUMERIC(18, 3)) AS [Table's Total Space In GB]
FROM SYS.Tables t INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN SYS.Indexes idx ON t.Object_id = idx.Object_id
INNER JOIN SYS.Partitions part ON idx.Object_id = part.Object_id
AND idx.Index_id = part.Index_id
INNER JOIN SYS.Allocation_units au ON part.Partition_id = au.Container_id
INNER JOIN SYS.Filegroups fGrp ON idx.Data_space_id = fGrp.Data_space_id
INNER JOIN SYS.Database_files Df ON Df.Data_space_id = fGrp.Data_space_id
WHERE t.Is_ms_shipped = 0 AND idx.Object_id > 255
GROUP BY t.Name, s.name
ORDER BY [Table's Total Space In GB] DESC
---Thank You to < https://gauravlal.wordpress.com/2013/07/12/t-sql-query-to-get-database-size-and-table-size-in-gigabytes/>
```
Using these two SQL queries have helped me track down some pretty sneaky data hogs.  I hope these scripts help you in any future data hog culprits.
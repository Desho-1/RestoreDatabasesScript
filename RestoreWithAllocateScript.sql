
===================================================

-- To allow advanced options to be changed.
EXEC sp_configure 'show advanced options', 1
GO
-- To update the currently configured value for advanced options.
RECONFIGURE
GO
-- To enable the feature.
EXEC sp_configure 'xp_cmdshell', 1
GO
-- To update the currently configured value for this feature.
RECONFIGURE
GO

==================================
--Define table for storing databases 
Declare @FilesCmdShell TABLE(
 outputCmd NVARCHAR (MAX)
)

--Define table for storing LogicalNames of backups which will be needed for reallocating (data & logs) when restoring 
Declare @fileListTable TABLE (
LogicalName NVARCHAR(128),
  PhysicalName NVARCHAR(260),
  Type CHAR(1),
  FileGroupName NVARCHAR(128),
  Size numeric(20,0),
  MaxSize numeric(20,0),
  Field bigint,
  CreateLSN numeric(25,0),
  DropLSN numeric(25,0),
  UniqueId uniqueidentifier,
  ReadonlyLSN numeric(25,0),
  ReadWriteLSN numeric(25,0),
  BackupSizeInBytes BigInt,
  SourceBlockSize Int,
  FileGroupId int,
  LogGroupGUID uniqueidentifier,
  DifferentialBaseLSN numeric(25,0),
  DifferentialBaseGUID uniqueidentifier,
  IsReadOnly bit,
  IsPresent bit,
  TDEThumprint varbinary(32),
  SnapshotURL nvarchar(360)
  )
  --counter for loop
  DECLARE @Counter int = 1
  
  --detecting databases and inserting them in the table
 INSERT INTO @FilesCmdShell (outputCmd) EXEC master.sys.xp_cmdshell 'dir /B D:\Database" "Adminstration\Sqlserver\bak\*.bak'
 -- size of the databases
 DECLARE @Size int = (SELECT COUNT(*) FROM @FilesCmdShell)
 
 -- define loop for databases 
 WHILE @Counter < @Size
 BEGIN
-- selecting 1 database each round depending on the counter
 DECLARE @DB NVARCHAR (MAX) = (SELECT outputCmd FROM (SELECT * ,ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum from @FilesCmdShell) as MyTable where MyTable.RowNum=@Counter)
 --updating the backup path with the selected database 
 DECLARE @bakPath NVARCHAR (MAX) = 'D:\Database Adminstration\Sqlserver\bak\' +@DB
 --excute the following command on the backup file of the selected database in order to determine the name of Data & logs
 INSERT INTO @fileListTable EXEC('RESTORE FILELISTONLY FROM DISK = '''+@bakPath+'''')
 -- storing data and logs in variables
 DECLARE @Data NVARCHAR (MAX) = (SELECT [LogicalName] FROM @fileListTable where [Field]=1)
 DECLARE @Log NVARCHAR (MAX) = (SELECT [LogicalName] FROM @fileListTable where [Field]=2)
 -- Building the restore Query based on variabes collected 
 DECLARE @cmd NVARCHAR(MAX) ='RESTORE DATABASE [' + SUBSTRING(@DB, 0,CHARINDEX('.',@DB)) + '] FROM DISK = N''D:\Database Adminstration\Sqlserver\bak\' + SUBSTRING(@DB,0,CHARINDEX ('.',@DB)) +'.bak'' WITH FILE = 1, MOVE N'''+@Data+''' TO N''D:\Database Adminstration\Sqlserver\bak\'+ SUBSTRING(@DB, 0,CHARINDEX('.',@DB)) + '.mdf'', MOVE N'''+@Log+''' TO N''D:\Database Adminstration\Sqlserver\bak\' + SUBSTRING(@DB, 0,CHARINDEX ('.', @DB)) + '.ldf'', NOUNLOAD, STATS = 10'

 select @cmd
 -- move 1 step forward 
 SET @Counter = @Counter + 1;
 -- truncates tables in order to accept new values for the next database without conflict in selecting the LogicalName of data and logs 
 DELETE FROM @fileListTable;
  END
  
==============================================
  
-- To allow xp_cmdshell to be changed.
EXEC sp_configure 'xp_cmdshell', 0
GO
-- To update the currently configured value.
RECONFIGURE
GO


SELECT * FROM SYS.CONFIGURATIONS WHERE Name = 'xp_cmdshell'
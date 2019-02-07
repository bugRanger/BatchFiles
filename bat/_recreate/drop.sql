USE master
GO

IF (EXISTS (SELECT name FROM dbo.sysdatabases WHERE ('[' + name + ']' = N'NAME_BASE' OR name = N'NAME_BASE')))
BEGIN
  EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'NAME_BASE'
	EXEC sp_executesql N'ALTER DATABASE NAME_BASE SET SINGLE_USER WITH ROLLBACK IMMEDIATE'
	EXEC sp_executesql N'DROP DATABASE NAME_BASE'
--	EXEC master.dbo.sp_detach_db @dbname = N'NAME_BASE', @keepfulltextindexfile=N'false'
END
GO

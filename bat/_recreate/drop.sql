USE master
GO
IF (EXISTS (SELECT name FROM dbo.sysdatabases WHERE ('[' + name + ']' = N'NAME_BASE' OR name = N'NAME_BASE')))
	ALTER DATABASE NAME_BASE SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
IF (EXISTS (SELECT name FROM dbo.sysdatabases WHERE ('[' + name + ']' = N'NAME_BASE' OR name = N'NAME_BASE')))
	EXEC master.dbo.sp_detach_db @dbname = N'NAME_BASE'
GO
IF (EXISTS (SELECT name FROM dbo.sysdatabases WHERE ('[' + name + ']' = N'NAME_BASE' OR name = N'NAME_BASE')))
	EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'NAME_BASE'
GO
IF (EXISTS (SELECT name FROM dbo.sysdatabases WHERE ('[' + name + ']' = N'NAME_BASE' OR name = N'NAME_BASE')))
	DROP DATABASE IF EXISTS NAME_BASE
GO

USE master
GO
ALTER DATABASE NAME_BASE SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
IF (EXISTS (SELECT name FROM dbo.sysdatabases WHERE ('[' + name + ']' = N'NAME_BASE' OR name = N'NAME_BASE')))
	EXEC dbo.sp_detach_db @dbname = N'NAME_BASE'
GO

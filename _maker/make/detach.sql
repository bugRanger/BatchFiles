USE master
GO
ALTER DATABASE NAME_BASE SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
EXEC master.dbo.sp_detach_db @dbname = N'NAME_BASE'
GO
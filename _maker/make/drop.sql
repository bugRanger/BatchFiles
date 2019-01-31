USE master
GO
ALTER DATABASE NAME_BASE SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
EXEC master.dbo.sp_detach_db @dbname = N'NAME_BASE'
GO
EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'NAME_BASE'
GO
USE master
GO
DROP DATABASE IF EXISTS NAME_BASE
GO

USE master
GO

CREATE DATABASE NAME_BASE
ON PRIMARY (
NAME = N'NAME_BASE',
FILENAME = N'PATH_BASE\NAME_BASE.mdf',
SIZE = 52224 KB,
MAXSIZE = UNLIMITED,
FILEGROWTH = 1024 KB
)
LOG ON (
NAME = N'NAME_BASE_log',
FILENAME = N'PATH_BASE\NAME_BASE_log.ldf',
SIZE = 135936 KB,
MAXSIZE = UNLIMITED,
FILEGROWTH = 10 %
)
GO

ALTER DATABASE NAME_BASE
SET
ANSI_NULL_DEFAULT OFF,
ANSI_NULLS OFF,
ANSI_PADDING OFF,
ANSI_WARNINGS OFF,
ARITHABORT OFF,
AUTO_CLOSE OFF,
AUTO_CREATE_STATISTICS ON,
AUTO_SHRINK OFF,
AUTO_UPDATE_STATISTICS ON,
AUTO_UPDATE_STATISTICS_ASYNC OFF,
CONCAT_NULL_YIELDS_NULL OFF,
CURSOR_CLOSE_ON_COMMIT OFF,
CURSOR_DEFAULT GLOBAL,
DATE_CORRELATION_OPTIMIZATION OFF,
DB_CHAINING OFF,
MULTI_USER,
NUMERIC_ROUNDABORT OFF,
PAGE_VERIFY CHECKSUM,
PARAMETERIZATION SIMPLE,
QUOTED_IDENTIFIER OFF,
READ_COMMITTED_SNAPSHOT OFF,
RECOVERY FULL,
RECURSIVE_TRIGGERS OFF,
TRUSTWORTHY OFF
WITH ROLLBACK IMMEDIATE
GO

ALTER DATABASE NAME_BASE
COLLATE cyrillic_general_ci_as
GO

ALTER DATABASE NAME_BASE
SET DISABLE_BROKER
GO

ALTER DATABASE NAME_BASE
SET ALLOW_SNAPSHOT_ISOLATION OFF
GO
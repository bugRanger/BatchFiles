@echo off
REM Example: call "C:\..\{this}.bat" "C:\..\{CatalogWithSqlFiles}\" "{Server}" "{BaseName}" "{login}" "{password}" "{BasePath(use_only_for_recreate)}"
REM {this} - ��� �������� ������������ �����.
REM {CatalogWithSqlFiles} - ������� �������� ������ ��� ����������.
REM {Server} - ������ (���/�����)
REM {BaseName} - ������������ ���� ������.
REM {login} - ������������.
REM {password} - ������ ������������.
REM {BasePath(use_only_for_recreate)} - ���� �� ����� �������� ����, ��� ����� ��������. 
REM ��������! ���� �������� ������������ ��� ��������������� ������������ ���� ������.

REM ��������� ���������� � ���������, �.�. � ��� ���� ������� � ����� �������� (����� ������� �� ����� ��������� �����������).
setlocal enabledelayedexpansion
setlocal enableextensions 
set UPDATAPATH=%1
set PROVIDER=%2
set NAMEBASE=%3
set USERNAME=%4
set PASSWORD=%5
set PATHBASE=%6
set MAKEPATH=make\
set DIRMAKE=__make\
set DIRUPDATE=__update\
set DIRCONTENT=__content\
REM ����������...
cd /d %~dp0
REM ������� �������...
RD /S /Q %DIRMAKE%
RD /S /Q %DIRUPDATE%
RD /S /Q %DIRCONTENT%

REM �������� ���� � ���� ������ ��� ����� ��� ���������� ������������...
IF NOT EXIST "%PATHBASE%%NAMEBASE%*.mdf" (
IF NOT EXIST "%PATHBASE%" GOTO SkipRecreate)
REM �������������� �������...
call %MAKEPATH%replace.bat %MAKEPATH% "detach.sql" "_detach.sql" "NAME_BASE" %NAMEBASE%
call %MAKEPATH%replace.bat %MAKEPATH% "drop.sql" "_drop.sql" "NAME_BASE" %NAMEBASE%
call %MAKEPATH%replace.bat %MAKEPATH% "make.sql" "__make.sql" "NAME_BASE" %NAMEBASE%
call %MAKEPATH%replace.bat %MAKEPATH% "__make.sql" "_make.sql" "PATH_BASE" %PATHBASE%
REM �������������� ������� ��� ����������...
del "%MAKEPATH%__*.sql"
xcopy %MAKEPATH%_*.sql %DIRMAKE% /Y /C /R /S /I /Q
del "%MAKEPATH%_*.sql"
xcopy %UPDATAPATH%%MAKEPATH%*.sql %DIRCONTENT% /Y /C /R /S /I /Q
REM ��������� ���� ������...
sqlcmd -S %PROVIDER% -U %USERNAME% -P %PASSWORD% -i %DIRMAKE%_drop.sql
REM ������� ���� ������...
del %PATHBASE%%NAMEBASE%*.mdf
del %PATHBASE%%NAMEBASE%*.ldf
REM ������� ���� ������...
sqlcmd -S %PROVIDER% -U %USERNAME% -P %PASSWORD% -i %DIRMAKE%_make.sql
REM ����������� ���� ������...
for /R %DIRCONTENT% %%G in (*.sql) do sqlcmd -S %PROVIDER% -U %USERNAME% -P %PASSWORD% -d %NAMEBASE% -i "%%G"
:SkipRecreate

REM �������������� �������...
xcopy %UPDATAPATH%*.sql %DIRUPDATE% /Y /C /R /S /I /Q
REM ������� ������ �� ��������������.
RD /S /Q %DIRUPDATE%%MAKEPATH%

REM ��������� ���� ������...
for /R %DIRUPDATE% %%G in (*.sql) do call :RunScript "%%G"
REM ��������� ������ ��� ������...
for /R %DIRUPDATE% %%G in (*.err) do sqlcmd -S %PROVIDER% -U %USERNAME% -P %PASSWORD% -d %NAMEBASE% -i "%%G"
REM �������� ���� � ���� ������ ��� ����� ��� ���������� �����������...
IF NOT EXIST "%PATHBASE%%NAMEBASE%*.mdf" (
IF NOT EXIST "%PATHBASE%" GOTO SkipDetach)
REM ���������� ���� ������...
sqlcmd -S %PROVIDER% -U %USERNAME% -P %PASSWORD% -i %DIRMAKE%_detach.sql
:SkipDetach
REM ������� �������...
RD /S /Q %DIRCONTENT%
RD /S /Q %DIRUPDATE%
RD /S /Q %DIRMAKE%
REM ����������...
cd /d %cd%
pause

GOTO :END
:RunScript
	sqlcmd -S %PROVIDER% -U %USERNAME% -P %PASSWORD% -d %NAMEBASE% -b -i %1
	IF "%ERRORLEVEL%"=="1" (
		copy /Y %1 "%~dp1\%~n1.err")
:END
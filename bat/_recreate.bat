@echo off
REM Example: call {This}.bat "{Server}" "{BaseName}" "{login}" "{password}" "{BasePath}" {Silent} {LogFile}
REM 1. {Server} - ������ (���/�����)
REM 2. {BaseName} - ������������ ���� ������.
REM 3. {login} - ������������.
REM 4. {password} - ������ ������������.
REM 5. {BasePath(use_only_for_recreate)} - ���� �� ����� �������� ����, ��� ����� ��������. ��������! ���� �������� ������������ ��� ��������������� ������������ ���� ������.
REM 6. {Silent} - ����� �����(0 - off, 1 - on. off �� ���������).
REM 7. {LogFile} - ���� ��� ����� ����������� ����������.
REM Example>call _recreate.bat "192.168.70.26" "Dev44_Atlan" "sa" "testSA" "C:\Temp" 1 ".\result.log"

SET PROVIDER=%1
SET NAMEBASE=%2
SET USERNAME=%3
SET PASSWORD=%4
SET PATHBASE=%5
SET SILENT=%6
SET LOGFILE=%7
SET MAKEPATH=.\_recreate\
SET DIRMAKE=.\__recreate\
SET DIRLOG=%~dp0
SET DIRLOG=%DIRLOG%logs
REM Color for rows
SET ESC=
SET RESC=%ESC%[0m
SET Red=%ESC%[91m
SET Cyan=%ESC%[36m
SET BCyan=%ESC%[96m
SET Green=%ESC%[92m
SET Yellow=%ESC%[93m
SET Tooltip=%ESC%[90m

REM ��������� ���������� � ���������, �.�. � ��� ���� ������� � ����� �������� (����� ������� �� ����� ��������� �����������).
SetLocal enabledelayedexpansion
SetLocal enableextensions 
	REM �������� �� ���������
	IF [%SILENT%] EQU [] set SILENT=1
	IF [%PATHBASE%] EQU [] set PATHBASE=""
	
	REM ����������...
	cd /d %~dp0
	REM ������� �������...
	rd /S /Q %DIRMAKE% >NUL 2>&1

	REM �������� ���� � ���� ������ ��� ����� ��� ���������� ������������...
	REM IF NOT EXIST "%PATHBASE%%NAMEBASE%*.mdf" (
	REM IF NOT EXIST "%PATHBASE%" GOTO SkipRecreate)
	REM �������������� �������...
	call %MAKEPATH%replace.bat %MAKEPATH% "detach.sql" "_detach.sql" "NAME_BASE" %NAMEBASE%
	call %MAKEPATH%replace.bat %MAKEPATH% "drop.sql" "_drop.sql" "NAME_BASE" %NAMEBASE%
	call %MAKEPATH%replace.bat %MAKEPATH% "make.sql" "__make.sql" "NAME_BASE" %NAMEBASE%
	call %MAKEPATH%replace.bat %MAKEPATH% "__make.sql" "_make.sql" "PATH_BASE" %PATHBASE%
	REM �������������� ������� ��� ����������...
	del "%MAKEPATH%__*.sql" >NUL 2>&1
	xcopy %MAKEPATH%_*.sql %DIRMAKE% /Y /C /R /S /I /Q >NUL
	del "%MAKEPATH%_*.sql" >NUL 2>&1
	REM ��������� ���� ������...
	REM call :RunScript 0 "%DIRMAKE%_detach.sql" "Detach base - %NAMEBASE%"
	call :RunScript 0 "%DIRMAKE%_drop.sql" "Drop base - %NAMEBASE%"
	REM ������� ���� ������...
	REM del %PATHBASE%%NAMEBASE%*.mdf >NUL 2>&1
	REM del %PATHBASE%%NAMEBASE%*.ldf >NUL 2>&1
	REM ������� ���� ������...
	call :RunScript 0 "%DIRMAKE%_make.sql" "Create base - %NAMEBASE%"
:SkipRecreate
	REM ������� �������...
	rd /S /Q %DIRMAKE% >NUL 2>&1 
	REM ����������...
	cd /d %cd%
( 
	EndLocal
)
GOTO :EOF
:RunScript
	IF NOT EXIST "%DIRLOG%" mkdir "%DIRLOG%"
	REM �������� ����� ��� ������������ ����.
	set /a TM=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%%TIME:~9,2%
	set /a TM=%TM: =0%
	REM �������� ������������ ��� ��������, �������(quotes) ������ �� �������.
	set ACT=%3
	set ACT=%ACT:"=%
	REM ��������� ������� ������ ����.
	IF [%LOGFILE%] EQU [] set LOG="%DIRLOG%\%TM%_%~n2.log"
	IF [%LOGFILE%] NEQ [] set LOG=%LOGFILE%
	REM ����� � ������� � � ���.
	IF [%SILENT%] EQU [1] (
		echo %time%:[%1] [%Yellow%QUERY%RESC%] ^> %ACT%
		@echo %time%:[%1] [QUERY] ^> %ACT% >> %LOG%
	)
	REM ��������� ������...
	sqlcmd -S %PROVIDER% -U %USERNAME% -P %PASSWORD% -b -i %2 -r0 1> NUL 2>> %LOG%
	REM �������� �� ������...
	IF !ERRORLEVEL! EQU 0 (
		echo %time%:[%1] [%Green%READY%RESC%] ^< %ACT%
		@echo %time%:[%1] [READY] ^< %ACT% >> %LOG%
		set /A SUCCESS=!SUCCESS!+1
	)
	IF !ERRORLEVEL! NEQ 0 (
		echo %time%:[%1] [%Red%ERROR%RESC%] ^< %ACT%
		@echo %time%:[%1] [ERROR] ^< %ACT% >> %LOG%
	)
	set /A TOTAL=!TOTAL!+1
GOTO :EOF
@echo off
REM call {This}.bat "{Folder}" "{Provider}" "Base" "{Login}" "{Password}"
REM {Folder} - ����� � ������� ����������.
REM {Provider} - ������ ����.
REM {Base} - ���� ������.
REM {Login} - ������������.
REM {Password} - ������ ������������.
REM {Silent} - ����� �����(0 - off, 1 - on).
REM Example>call _update.bat "C:\Temp" "192.168.70.26" "Dev44_Atlan" "sa" "testSA" 0

REM Settings
SET UPDATAPATH=%1
SET PROVIDER=%2
SET NAMEBASE=%3
SET USERNAME=%4
SET PASSWORD=%5
SET SILENT=%6
REM Color for rows
SET ESC=
SET RESC=%ESC%[0m
SET Red=%ESC%[91m
SET Green=%ESC%[92m
SET Blue=%ESC%[96m
SET Tooltip=%ESC%[90m
SET DIRLOG=%~dp0\logs
SET /a SUCCESS = 0
SET /a TOTAL = 0

SetLocal enabledelayedexpansion	
	REM ������� �������...
	IF EXIST "%DIRLOG%" RD /S /Q "%DIRLOG%"
	REM ��������� �������...
	for /R %UPDATAPATH% %%G in (*.sql) do call :RunScript "%%G"
	IF %SUCCESS% NEQ %TOTAL% echo %time%: %Red%Total number does not match the number of successful%RESC%
	IF %SUCCESS% EQU %TOTAL% echo %time%: %Green%Total number corresponds to the number of successful%RESC%
	echo %time%: %Blue%Count - %SUCCESS%/%TOTAL%%RESC%
EndLocal
GOTO :EOF
:RunScript
	IF NOT EXIST "%DIRLOG%" mkdir "%DIRLOG%"
	REM �������� ����� �.
	set /a TM=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%%TIME:~9,2%	
	set /a TM=%TM: =0%
	REM ��������� ������...
	sqlcmd -S %PROVIDER% -U %USERNAME% -P %PASSWORD% -d %NAMEBASE% -b -i %1 -r%SILENT% 1> NUL 2> "%DIRLOG%\%TM%_%~n1.log"
	REM �������� �� ������...
	IF !ERRORLEVEL! EQU 0 (
		echo %time%: [%Green%READY%] %1
		set /A SUCCESS=SUCCESS%+1
	)
	IF !ERRORLEVEL! NEQ 0 (
		echo %time%: [%Red%ERROR%RESC%] %1
	)
	set /A TOTAL=%TOTAL%+1

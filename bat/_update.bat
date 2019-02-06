@echo off
REM call {This}.bat "{Folder}" {Provider} "Base" "{Login}" "{Password}" {Attemp} {Silent} {LogFile}
REM 1. {Folder} - ����� � ������� ����������.
REM 2. {Provider} - ������ ����.
REM 3. {Base} - ���� ������.
REM 4. {Login} - ������������.
REM 5. {Password} - ������ ������������.
REM 6. {Attemp} - ������� ���������� ��� ������� ������ (1 �� ���������)
REM 7. {Silent} - ����� �����(0 - off, 1 - on. off �� ���������).
REM 8. {LogFile} - ���� ��� ����� ����������� ����������.
REM Example>call _update.bat "C:\Temp" "192.168.70.26" "Dev44_Atlan" "sa" "testSA" 0 1 ".\result.log"

REM Settings
SET UPDATAPATH=%1
SET PROVIDER=%2
SET NAMEBASE=%3
SET USERNAME=%4
SET PASSWORD=%5
SET ATTEMP=%6
SET SILENT=%7
SET LOGFILE=%8
REM Color for rows
SET ESC=
SET RESC=%ESC%[0m
SET Red=%ESC%[91m
SET Cyan=%ESC%[36m
SET BCyan=%ESC%[96m
SET Green=%ESC%[92m
SET Yellow=%ESC%[93m
SET Tooltip=%ESC%[90m
SET DIRLOG=%~dp0
SET DIRLOG=%DIRLOG%logs

SetLocal EnableDelayedExpansion
	REM �������� �� ���������
	IF [%SILENT%] EQU [] set SILENT=1
	IF [%ATTEMP%] EQU [] set ATTEMP=1
	IF [%ATTEMP%] NEQ [] set /a ATTEMP=ATTEMP+1
	REM ������� �������...
	IF EXIST "%DIRLOG%" RD /S /Q "%DIRLOG%"
	set ERROR_COUNT=1
	for /L %%A in (1,1,%ATTEMP%) do (
		set LAST_ERROR_COUNT=!SUCCESS! - !TOTAL!
		REM �������� �� ���-�� ������ ����� �������.
		IF !ERROR_COUNT! NEQ !LAST_ERROR_COUNT! (
			call :RunExecute %%A
			set /A ERROR_COUNT=!SUCCESS! - !TOTAL!
		)
	)
( 
	EndLocal
	set FOLDER=%UPDATAPATH%
	set /A READY=%READY% + %SUCCESS%
	set /A AMOUNT=%AMOUNT% + %TOTAL%
)
GOTO :EOF
:RunExecute
	set /A SUCCESS=0
	set /A TOTAL=0
	REM ��������� �������...
	for /R %UPDATAPATH% %%G in (*.sql) do call :RunScript %1 "%%G" "%%G"
	IF %SUCCESS% NEQ %TOTAL% echo %time%:[%1] %Red%Total number does not match the number of successful%RESC%
	IF %SUCCESS% EQU %TOTAL% echo %time%:[%1] %Green%Total number corresponds to the number of successful%RESC%
	echo %time%: %Cyan%Count - %SUCCESS%/%TOTAL%%RESC%
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
	)
	@echo %time%:[%1] [%Yellow%QUERY%RESC%] ^> %ACT% >> %LOG%
	REM ��������� ������...
	sqlcmd -S %PROVIDER% -d %NAMEBASE% -U %USERNAME% -P %PASSWORD% -b -i %2 -r0 1> NUL 2>> %LOG%
	REM �������� �� ������...
	IF !ERRORLEVEL! EQU 0 (
		echo %time%:[%1] [%Green%READY%RESC%] ^< %ACT%
		@echo %time%:[%1] [%Green%READY%RESC%] ^< %ACT% >> %LOG%
		set /A SUCCESS=!SUCCESS!+1
	)
	IF !ERRORLEVEL! NEQ 0 (
		echo %time%:[%1] [%Red%ERROR%RESC%] ^< %ACT%
		@echo %time%:[%1] [%Red%ERROR%RESC%] ^< %ACT% >> %LOG%
	)
	set /A TOTAL=!TOTAL!+1
GOTO :EOF
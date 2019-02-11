@echo off
:: call {This}.bat "{UPD_FOLDER}" {UPD_FILE} {DB_PROVIDER} "{DB_NAME}" "{DB_USER}" "{DB_PASS}" {Attemp} {Silent} {LogFile}
:: 1. {UPD_FOLDER} - ����� � ������� ����������.
:: 2. {UPD_FILE} - ������������ ����������� ������.
:: 3. {DB_PROVIDER} - ������ (���/�����).
:: 4. {DB_NAME} - ���� ������.
:: 5. {DB_USER} - ������������.
:: 6. {DB_PASS} - ������ ������������.
:: 7. {Attemp} - ������� ���������� ��� ������� ������ (1 �� ���������)
:: 8. {Silent} - ����� �����(0 - off, 1 - on. off �� ���������).
:: 9. {LogFile} - ���� ��� ����� ����������� ����������.
:: Example>call _update.bat "C:\Temp" "*.sql" "192.168.70.26" "Dev44_Atlan" "sa" "testSA" 0 1

:: Settings
SET UPD_FOLDER=%1
SET UPD_FILE=%2
SET DB_PROVIDER=%3
SET DB_NAME=%4
SET DB_USER=%5
SET DB_PASS=%6
SET ATTEMP=%7
SET SILENT=%8
SET LOGFILE=%9
:: Color for rows
SET ESC=
SET RESC=%ESC%[0m
SET Red=%ESC%[91m
SET Cyan=%ESC%[36m
SET BCyan=%ESC%[96m
SET Green=%ESC%[92m
SET Yellow=%ESC%[93m
SET Tooltip=%ESC%[90m

SET DIRLOG=%~dp0logs

:: ��������� ���������� � ���������, �.�. � ��� ���� ������� � ����� �������� (����� ������� �� ����� ��������� �����������).
SetLocal EnableDelayedExpansion
	:: �������� �� ���������
	IF [%SILENT%] EQU [] set SILENT=1
	IF [%ATTEMP%] EQU [] set ATTEMP=1
	IF [%ATTEMP%] EQU [0] set /a ATTEMP=%ATTEMP%+1
	:: ������� �������...
	:: IF EXIST "%DIRLOG%" RD /S /Q "%DIRLOG%"
	set /a ERROR_COUNT=0
	set /a LAST_ERROR_COUNT=1
	for /L %%A in (1,1,%ATTEMP%) do (
		:: �������� �� ���-�� ������ ����� �������.
		IF !ERROR_COUNT! NEQ !LAST_ERROR_COUNT! (
			call :RunExecute %%A
			set /A ERROR_COUNT=!SUCCESS! - !TOTAL!
		)
		set /a LAST_ERROR_COUNT=!SUCCESS! - !TOTAL!
	)
( 
	EndLocal
	set /A READY=%READY% + %SUCCESS%
	set /A AMOUNT=%AMOUNT% + %TOTAL%
)
GOTO :EOF
:RunExecute
	set /A SUCCESS=0
	set /A TOTAL=0
	:: ��������� �������...
	:: ���� �� ������ ������� ������.
	IF NOT EXIST %UPD_FOLDER% (
		FOR /F "delims=" %%A IN (%UPD_FILE%) DO (
			call :RunScript %1 "%%A" "%%~nxA"
		)
	)
	:: ���� ������ ������� ������.
	IF EXIST %UPD_FOLDER% (
		for /R %UPD_FOLDER% %%G in (%UPD_FILE%) do call :RunScript %1 "%%G" "%%~nxG"
		:: ������� ��������� ����������.
		IF [%SILENT%] LSS [2] IF !SUCCESS! NEQ !TOTAL! (
			echo.%time%:[%1] %Red%Total number does not match the number of successful%RESC%
			@echo.%time%:[%1] Total number does not match the number of successful>>%LOGFILE%
		)
		IF [%SILENT%] LSS [2] IF !SUCCESS! EQU !TOTAL! (
			echo.%time%:[%1] %Green%Total number corresponds to the number of successful%RESC%
			@echo.%time%:[%1] Total number corresponds to the number of successful>>%LOGFILE%
		)
		IF [%SILENT%] LSS [2] (
			echo.%time%:[%1] %BCyan%Count - !SUCCESS!/!TOTAL!%RESC%
			@echo.%time%:[%1] Count - !SUCCESS!/!TOTAL!>>%LOGFILE%
		)
	)
GOTO :EOF
:RunScript
	IF NOT EXIST %2 GOTO :EOF
	IF NOT EXIST "%DIRLOG%" mkdir "%DIRLOG%"
	:: �������� ����� ��� ������������ ����.
	set /a TM=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%%TIME:~9,2%
	set /a TM=%TM: =0%
	:: �������� ������������ ��� ��������, �������(quotes) ������ �� �������.
	set ACT=%3
	set ACT=%ACT:"=%
	set ACT=%ACT:(=^^(%
	set ACT=%ACT:)=^^)%
	:: ��������� ������� ������ ����.
	IF [%LOGFILE%] EQU [] set LOG="%DIRLOG%\%TM%_%~n2.log"
	IF [%LOGFILE%] NEQ [] set LOG=%LOGFILE%
	:: ����� � ������� � � ���.
	IF [%SILENT%] EQU [0] (
		echo.%time%:[%1] [%Yellow%QUERY%RESC%] ^> %ACT%
		@echo.%time%:[%1] [QUERY] ^> %ACT%>>%LOG%
	)
	:: ��������� ������...
	sqlcmd -S %DB_PROVIDER% -d %DB_NAME% -U %DB_USER% -P %DB_PASS% -b -i %2 -r0 1> NUL 2>>%LOG%
	set /A TOTAL=!TOTAL!+1
	:: �������� �� ������...
	IF !ERRORLEVEL! EQU 0 (
		IF [%SILENT%] LSS [3] echo.%time%:[%1] [%Green%READY%RESC%] ^< %ACT%
		@echo.%time%:[%1] [READY] ^< %ACT%>>%LOG%
		set /A SUCCESS=!SUCCESS!+1
	)
	IF !ERRORLEVEL! NEQ 0 (
		IF [%SILENT%] LSS [3] echo.%time%:[%1] [%Red%ERROR%RESC%] ^< %ACT%
		@echo.%time%:[%1] [ERROR] ^< %ACT% ^(%2^)>>%LOG%
		:: ����� ������� � ����� � ������� � ������.
		IF [!TRASH!] NEQ [] (
			@echo.%2 >> !TRASH!
		)
	)
GOTO :EOF
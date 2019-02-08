@echo off
REM EQU - equal
REM NEQ - not equal
REM LSS - less than
REM LEQ - less than or equal
REM GTR - greater than
REM GEQ - greater than or equal
SET _PROVIDER=HUKUMKA\SQLEXPRESS
SET _NAMEBASE=Example
SET _BASEFOLDER="E:\Temp"
SET _BASEFOLDER=%_BASEFOLDER:"=%
SET _UPDFOLDER="C:\Users\Hukuma\Documents\Visual Studio 2015\Projects\SIMADATABASE\"
SET _UPDFOLDER=%_UPDFOLDER:"=%
SET _USERNAME="sa"
SET _PASSWORD="1234"
SET _LOGFOLDER=.\r.log
SET _ATTEMP=2
SET _SILENT=2
SET REGION=3BDFDCFF-63DA-4010-9CAF-3F46CCBBBF73


	:: ��������� �����������.
	set READY=0
	set AMOUNT=0
	:: �������� �����.
	del %_LOGFOLDER% >NUL 2>&1
	:: ------------------------------------------------------------------------------------------------
	:: ����� �������.
	:: ------------------------------------------------------------------------------------------------
	set STARTTIME=%time%
	@echo %STARTTIME%: Start %~nx0 >> %_LOGFOLDER%
	REM �������� ���� ������, �� �������������.
	:: ------------------------------------------------------------------------------------------------
	:: ������� ����.
	:: ------------------------------------------------------------------------------------------------
	echo %time%: Create database...
	call "%~dp0_recreate.bat" "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% %_BASEFOLDER% 0 %_LOGFOLDER%
	REM ��������� ����, ����������� ��� ������ ���������� �������� � ��������� �� ��� �������.
	:: ------------------------------------------------------------------------------------------------
	:: ������������� ������������ �������.
	:: ------------------------------------------------------------------------------------------------
	echo %time%: Make parameters...
	call "%~dp0_update.bat" "" "%_UPDFOLDER%Create Scripts\Parameters.sql" "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER% 
	:: �������� �����.
	del region.sql >NUL 2>&1
	:: ------------------------------------------------------------------------------------------------
	:: ������ �� ��������� ������������ ��������.
	:: ------------------------------------------------------------------------------------------------
	echo DECLARE @parameterValue VARCHAR(MAX), @parameterName VARCHAR(MAX) >> region.sql
	echo SET @parameterValue = '%REGION%' >> region.sql
	echo SET @parameterName = 'SystemUUID' >> region.sql
	echo IF NOT EXISTS (SELECT * FROM [Parametrs] WHERE Parametr_Name = @parameterName) >> region.sql
	echo BEGIN >> region.sql
	echo 	INSERT INTO [Parametrs] (Parametr_Name, Parametr_Value, Coments) >> region.sql
	echo 	VALUES (@parameterName, @parameterValue, '��� ������������ ������������ ��������'); >> region.sql
	echo END >> region.sql
	echo ELSE >> region.sql
	echo BEGIN >> region.sql
	echo 	UPDATE [Parametrs] >> region.sql
	echo 	SET Parametr_Value = @parameterValue >> region.sql
	echo 	WHERE Parametr_Name = @parameterName >> region.sql
	echo END >> region.sql
	:: ������������� ������������ �������.
	call "%~dp0_update.bat" "" "%~dp0region.sql" "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
	REM ���������� ������.
	:: ------------------------------------------------------------------------------------------------
	:: ��������� ������������ ����������.
	:: ------------------------------------------------------------------------------------------------
	echo %time%: Update content...
	:: ������ ��������.
	set TRASH=.\trash.log
	set TEMP=.\trash.tmp
	:: �������� �����.
	del %TRASH% >NUL 2>&1
	REM ������� ����������, � ������ ������ ������ � <c>TRASH</c> ��� ������� ���������� �� ��������� ������������������ �� -1.
	:: ------------------------------------------------------------------------------------------------
	:: ��������� ����������.
	:: ------------------------------------------------------------------------------------------------
	call "%~dp0_update.bat" "%_UPDFOLDER%Stored Procedures\System\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
	call "%~dp0_update.bat" "%_UPDFOLDER%Create Scripts\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
	call "%~dp0_update.bat" "%_UPDFOLDER%Stored Procedures\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
	call "%~dp0_update.bat" "%_UPDFOLDER%Queries\Settings\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
	call "%~dp0_update.bat" "%_UPDFOLDER%Queries\Permissions\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
	call "%~dp0_update.bat" "%_UPDFOLDER%Queries\Parameters\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
	call "%~dp0_update.bat" "%_UPDFOLDER%Queries\WebDocJournal\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
	:: ------------------------------------------------------------------------------------------------
	:: ���������� ����������� ����������, �� ��������.
	:: ------------------------------------------------------------------------------------------------
	SET _READY=%READY%
	SET _AMOUNT=%AMOUNT%
	REM ��������� ������� ��� ���������� ����������.
	:: ------------------------------------------------------------------------------------------------
	:: ��������� ������� ���������� ����������.
	:: ------------------------------------------------------------------------------------------------
	SET STEP=0
:CHECK_TRASH
	:: ��������� �����������.
	set READY=0
	set AMOUNT=0
	:: �������� �������.
	IF NOT EXIST "%TRASH%" GOTO :END_TRASH
	:: ------------------------------------------------------------------------------------------------
	:: ------------------------------------------------------------------------------------------------
	:: ������� �����.
	del %TEMP%>NUL 2>&1
	copy /Y %TRASH% %TEMP%>NUL 2>&1
	:: ������� ����.
	del %TRASH%>NUL 2>&1
	:: ------------------------------------------------------------------------------------------------
	:: �������� ���������� �����.
	:: ------------------------------------------------------------------------------------------------
	for /F "tokens=2 delims=:" %%A in ('find /c /v "" %TEMP%') do set /a count=%%A
	echo %time%:[%count%] Conflict resolution attempt...
	:: �������� � �������� �����������.
	setlocal enableextensions disabledelayedexpansion
	for /f "tokens=1,* delims=�" %%a in ('
        cmd /v:off /e /q /c"set "counter^=10000000" & for /f usebackq^ delims^=^ eol^= %%c in ("%TEMP%") do (set /a "counter+^=1" & echo(�%%c)"
        ^| sort /r
    ') do (
		call "%~dp0_update.bat" "" %%b "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
    )
	:: ------------------------------------------------------------------------------------------------
	:: ------------------------------------------------------------------------------------------------
:END_TRASH
	:: ------------------------------------------------------------------------------------------------
	:: ������ ���������� ����������.
	:: ------------------------------------------------------------------------------------------------
	set /a READY=%_READY%
	set /a AMOUNT=%_AMOUNT%
	:: ------------------------------------------------------------------------------------------------
	:: ������� ������������ �������.
	:: ------------------------------------------------------------------------------------------------
	:: �������� ������� �����.
	set ENDTIME=%time%
	@echo %ENDTIME%: Stop %~nx0 >> %_LOGFOLDER%
	:: ��������� ����� � ������������.
	set /A STARTTIME=(%STARTTIME:~0,2%-100)*360000 + (%STARTTIME:~3,2%-100)*6000 + (%STARTTIME:~6,2%-100)*100 + (%STARTTIME:~9,2%-100)
	set /A ENDTIME=(%ENDTIME:~0,2%-100)*360000 + (%ENDTIME:~3,2%-100)*6000 + (%ENDTIME:~6,2%-100)*100 + (%ENDTIME:~9,2%-100)
	:: ������� �������.
	set /A DURATION=%ENDTIME%-%STARTTIME%
	:: ???: ���� ������� � ����
	if [%ENDTIME%] LSS [%STARTTIME%] set set /A DURATION=%STARTTIME%-%ENDTIME%
	:: �������� ����� ���������� � �����, �������, ��������, ���� ��������.
	set /A DURATIONH=%DURATION% / 360000
	set /A DURATIONM=(%DURATION% - %DURATIONH%*360000) / 6000
	set /A DURATIONS=(%DURATION% - %DURATIONH%*360000 - %DURATIONM%*6000) / 100
	set /A DURATIONHS=(%DURATION% - %DURATIONH%*360000 - %DURATIONM%*6000 - %DURATIONS%*100)
	:: �������� ���� ��� �� ���.
	if [%DURATIONH%] LSS [10] set DURATIONH=0%DURATIONH%
	if [%DURATIONM%] LSS [10] set DURATIONM=0%DURATIONM%
	if [%DURATIONS%] LSS [10] set DURATIONS=0%DURATIONS%
	if [%DURATIONHS%] LSS [10] set DURATIONHS=0%DURATIONHS%
	:: ------------------------------------------------------------------------------------------------
	:: ������� ���� ��� ����������.
	:: ------------------------------------------------------------------------------------------------
	call "%~dp0_logo.bat"
	:: ------------------------------------------------------------------------------------------------
	:: ������� ��������� ����������.
	:: ------------------------------------------------------------------------------------------------
	IF %READY% NEQ %AMOUNT% echo %time%: %Red%Total number does not match the number of successful%RESC%
	IF %READY% EQU %AMOUNT% echo %time%: %Green%Total number corresponds to the number of successful%RESC%
	echo %time%: %BCyan%Total count - %READY%/%AMOUNT%%RESC%
	:: ------------------------------------------------------------------------------------------------
	:: ����� ����������.
	:: ------------------------------------------------------------------------------------------------
	echo.
	echo Total runtime - %DURATIONH%:%DURATIONM%:%DURATIONS%,%DURATIONHS%
	timeout /t 145
GOTO :EOF
:COPY_NUMLINE
	SETLOCAL DisableDelayedExpansion
	for /F "usebackq delims=" %%A in (`"findstr /n ^^ %1"`) do (
		set "var=%%A"
		SETLOCAL EnableDelayedExpansion
		for /f "delims=:" %%I in ("!var!") do IF [%%I] EQU [%2] (
			set "var=!var:*:=!"
			::
			call "%~dp0_update.bat" "" !var! "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
		)
		ENDLOCAL
	)
GOTO :EOF
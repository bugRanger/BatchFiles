@echo off
SET _PROVIDER=(localdb)\MSSQLLocalDB
SET _NAMEBASE=Example
SET _BASEFOLDER="D:\Temp"
SET _BASEFOLDER=%_BASEFOLDER:"=%
SET _UPDFOLDER="D:\Projects\Project.SIM\SIMADATABASE\"
SET _UPDFOLDER=%_UPDFOLDER:"=%
SET _USERNAME=""
SET _PASSWORD=""
SET _LOGFOLDER=.\r.log
SET _ATTEMP=2
SET _SILENT=2
SET REGION=3BDFDCFF-63DA-4010-9CAF-3F46CCBBBF73

:: Задаем каталог.
set TRASH=.\trash.log
set TEMP=.\temp.log
	:: REVERSER READ FILE
    setlocal enableextensions disabledelayedexpansion
    for /f "tokens=1,* delims=¬" %%a in ('
        cmd /v:off /e /q /c"set "counter^=10000000" & for /f usebackq^ delims^=^ eol^= %%c in ("%TEMP%") do (set /a "counter+^=1" & echo(¬%%c)"
        ^| sort /r
    ') do (
    call "%~dp0_update.bat" "" %%b "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
    )
	pause
	GOTO :EOF
	
	REM SetLocal DisableDelayedExpansion
	REM for /F "usebackq delims=" %%A in (`"findstr /n ^^ %TRASH%"`) do (
		REM SetLocal EnableDelayedExpansion
		REM set /a num=%%A
		REM echo %num%
		REM EndLocal
	REM )
	
	del %TEMP%>NUL 2>&1
	copy /Y %TRASH% %TEMP%>NUL 2>&1
	del %TRASH%>NUL 2>&1
	:: ------------------------------------------------------------------------------------------------
	:: Получаем количество строк.
	:: ------------------------------------------------------------------------------------------------
	for /F "tokens=2 delims=:" %%A in ('find /c /v "" %TEMP%') do set /a count=%%A
	echo %time%:[%count%] Conflict resolution attempt...
	for /l %%X in (%count%,-1,1) do call :COPY_NUMLINE %TEMP% %%X
	
	pause
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

	:: ------------------------------------------------------------------------------------------------
	:: Получаем количество строк.
	:: ------------------------------------------------------------------------------------------------
	for /F "tokens=2 delims=:" %%A in ('find /c /v "" %TRASH%') do set /a count=%%A
	echo %time%:[%count%] Conflict resolution attempt...
	:: Удаляем файл.
	del %TEMP% > NUL 2>&1
	:: ------------------------------------------------------------------------------------------------
	:: Получаем первую строку.
	:: ------------------------------------------------------------------------------------------------
	set /p last= < %TRASH%
	:: ------------------------------------------------------------------------------------------------
	:: Проходим по содержимому, игнорируя первую строку.
	:: ------------------------------------------------------------------------------------------------
	SetLocal DisableDelayedExpansion
	for /F "delims=" %%A in (%TRASH%) do (
		SetLocal EnableDelayedExpansion
		IF [!last!] NEQ [%%A] (
			echo.%%A>>%TEMP%
		)
		EndLocal
	)
	:: ------------------------------------------------------------------------------------------------
	:: Добавляем строку в конец.
	:: ------------------------------------------------------------------------------------------------
	echo.%last%>>%TEMP%
	:: Удаляем файл.
	del %TRASH% > NUL 2>&1
	:: ------------------------------------------------------------------------------------------------
	:: Выполняем список.
	:: ------------------------------------------------------------------------------------------------
	for /F "delims=" %%A in (%TEMP%) do (
		call "%~dp0_update.bat" "" %%A "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
	)
pause
GOTO :EOF

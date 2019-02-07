@echo off

SET PROVIDER=HUKUMKA\SQLEXPRESS
SET DATABASE=Example
SET BASEFOLDER="d:\Program Files\Microsoft SQL Server\MSSQL.1\MSSQL\DATA"
SET UPDFOLDER="C:\Users\Hukuma\Documents\Visual Studio 2015\Projects\SIMADATABASE\"
SET UPDFOLDER=%UPDFOLDER:"=%
SET LOGIN=sa
SET PASS=1234
SET LOGFOLDER=.\r.log
SET ATTEMP=2

	set READY=0
	set AMOUNT=0
	set STARTTIME=%time%
	
	@echo %STARTTIME%: Start %~n0%~x0 >> %LOGFOLDER%
	REM Создаем базу.
	REM call "%~dp0_recreate.bat" %PROVIDER% %DATABASE% %LOGIN% %PASS% %BASEFOLDER% 0
	REM Пробное обновление(Накатываем все что не свалиться по региональному признаку или по ошибке).
	call "%~dp0_update.bat" "%UPDFOLDER%Queries\System\" %PROVIDER% %DATABASE% %LOGIN% %PASS% 0 0
	call "%~dp0_update.bat" "%UPDFOLDER%Create Scripts\" %PROVIDER% %DATABASE% "%LOGIN%" "%PASSWORD%" 0 0 %LOGFOLDER%
	REM Устанавливаем региональный признак.
	REM call???
	REM Обновление базы с региональными настройками.
	REM for /L %%A in (1,1,%ATTEMP%) do (
		REM REM Выполняем обновление.
		REM call "%~dp0_update.bat" "%UPDFOLDER%_1\" %PROVIDER% %DATABASE% "%LOGIN%" "%PASSWORD%" 0 0 %LOGFOLDER%
		REM call "%~dp0_update.bat" "%UPDFOLDER%_2\" %PROVIDER% %DATABASE% "%LOGIN%" "%PASSWORD%" 0 0 %LOGFOLDER%
		REM REM В случае успеха выходим.
		REM IF %READY% EQU %AMOUNT% GOTO :RESULT
	REM )	
:RESULT
	REM ------------------------------------------------------------------------------------------------
	REM Подсчет затраченного времени.
	REM ------------------------------------------------------------------------------------------------
	REM Получаем текущее время.
	set ENDTIME=%time%
	REM Переводим время в милисекунды.
	set /A STARTTIME=(%STARTTIME:~0,2%-100)*360000 + (%STARTTIME:~3,2%-100)*6000 + (%STARTTIME:~6,2%-100)*100 + (%STARTTIME:~9,2%-100)
	set /A ENDTIME=(%ENDTIME:~0,2%-100)*360000 + (%ENDTIME:~3,2%-100)*6000 + (%ENDTIME:~6,2%-100)*100 + (%ENDTIME:~9,2%-100)
	REM Находим разницу.
	set /A DURATION=%ENDTIME%-%STARTTIME%
	REM ???: Если разница в днях
	if %ENDTIME% LSS %STARTTIME% set set /A DURATION=%STARTTIME%-%ENDTIME%
	REM Получаем время выполнения в часах, минутах, секундах, мили секундах.
	set /A DURATIONH=%DURATION% / 360000
	set /A DURATIONM=(%DURATION% - %DURATIONH%*360000) / 6000
	set /A DURATIONS=(%DURATION% - %DURATIONH%*360000 - %DURATIONM%*6000) / 100
	set /A DURATIONHS=(%DURATION% - %DURATIONH%*360000 - %DURATIONM%*6000 - %DURATIONS%*100)
	REM Добиваем нули где их нет.
	if %DURATIONH% LSS 10 set DURATIONH=0%DURATIONH%
	if %DURATIONM% LSS 10 set DURATIONM=0%DURATIONM%
	if %DURATIONS% LSS 10 set DURATIONS=0%DURATIONS%
	if %DURATIONHS% LSS 10 set DURATIONHS=0%DURATIONHS%
	echo %DURATIONH%:%DURATIONM%:%DURATIONS%,%DURATIONHS%	
	REM ------------------------------------------------------------------------------------------------
	REM Выводим лого для разделения.
	call "%~dp0_logo.bat"
	REM Выводим результат выполнения.
	IF %READY% NEQ %AMOUNT% echo %time%: %Red%Total number does not match the number of successful%RESC%
	IF %READY% EQU %AMOUNT% echo %time%: %Green%Total number corresponds to the number of successful%RESC%
	echo %time%: %BCyan%Total count - %READY%/%AMOUNT%%RESC%
	@echo %ENDTIME%: Stop %~n0%~x0 >> %LOGFOLDER%
	timeout /t 15
GOTO :EOF
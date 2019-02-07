@echo off
REM EQU - equal
REM NEQ - not equal
REM LSS - less than
REM LEQ - less than or equal
REM GTR - greater than
REM GEQ - greater than or equal
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
SET REGION=3BDFDCFF-63DA-4010-9CAF-3F46CCBBBF73

	set READY=0
	set AMOUNT=0
	set STARTTIME=%time%
	
	del %_LOGFOLDER% >NUL 2>&1
	@echo %STARTTIME%: Start %~n0%~x0 >> %_LOGFOLDER%
	:: Создаем базу.
	REM call "%~dp0_recreate.bat" "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% %_BASEFOLDER% 0 %_LOGFOLDER%
	echo First content...
	:: Устанавливаем региональный признак.
	call "%~dp0_update.bat" "%_UPDFOLDER%Create Scripts\" Parameters.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 1 %_LOGFOLDER% 
	
	del region.sql >NUL 2>&1
	echo DECLARE @parameterValue VARCHAR(MAX), @parameterName VARCHAR(MAX) >> region.sql
	echo SET @parameterValue = '%REGION%' >> region.sql
	echo SET @parameterName = 'SystemUUID' >> region.sql
	echo IF NOT EXISTS (SELECT * FROM [Parametrs] WHERE Parametr_Name = @parameterName) >> region.sql
	echo BEGIN >> region.sql
	echo 	INSERT INTO [Parametrs] (Parametr_Name, Parametr_Value, Coments) >> region.sql
	echo 	VALUES (@parameterName, @parameterValue, 'Тип используемых региональных настроек'); >> region.sql
	echo END >> region.sql
	echo ELSE >> region.sql
	echo BEGIN >> region.sql
	echo 	UPDATE [Parametrs] >> region.sql
	echo 	SET Parametr_Value = @parameterValue >> region.sql
	echo 	WHERE Parametr_Name = @parameterName >> region.sql
	echo END >> region.sql
	:: Устанавливаем региональный признак.
	call "%~dp0_update.bat" "%~dp0" region.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 1 %_LOGFOLDER%
	:: Выполняем региональные обновления.
	echo Merge content...
	:: Очистка папки.
	set STEP=0;
	set TRASH=.\trash.txt
	del %TRASH% >NUL 2>&1
	:: Выполняем обновление.
	call "%~dp0_update.bat" "%_UPDFOLDER%Stored Procedures\System\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 1 %_LOGFOLDER%
	REM call "%~dp0_update.bat" "%_UPDFOLDER%Create Scripts\" Competition*.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 1 %_LOGFOLDER%
	:: Забираем результаты в буфер.
	SET _READY=%READY%
	SET _AMOUNT=%AMOUNT%
	:: Читаем файл.
:CHECK_TRASH
	set /a READY=0
	set /a AMOUNT=0
	IF NOT EXIST %TRASH% GOTO :END_TRASH
:: Указываем выполнение с задержкой, т.к. у нас есть подсчет в цикле итераций (иначе подсчет не будет корректно выполняться).
SetLocal EnableDelayedExpansion
	set last=
	set list=
	:: Собираем список.
	for /f "delims=" %%A in (%TRASH%) do (
		IF [!last!] NEQ [] set list=!list!;%%A
		IF [!last!] EQU [] set last=%%A
		set /a count=!count!+1
	)
	set list=%list%;%last%;
	del %TRASH% >NUL 2>&1
	:: Идем по списку.
	for %%A in (%list%) do ( 
		REM echo %%~nxA 
		@echo %%A >> %TRASH%
		REM call "%~dp0_update.bat" "%%~pdA" %%~nxA "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 2 
	)
	IF %STEP% NEQ !count! IF %READY% NEQ %AMOUNT% (
EndLocal
		set /a STEP=%STEP%+1
		echo.
		GOTO :CHECK_TRASH
	)
:END_TRASH
	REM for /f "tokens=*" %%a in (%TRASH%) do (
		REM echo line=%%a
	REM )
	REM for /L %%S in (1,1,%_ATTEMP%) do (
		REM set /a READY=0
		REM set /a AMOUNT=0
		
		
		REM :: Выполняем обновление.
		REM call "%~dp0_update.bat" "%_UPDFOLDER%Stored Procedures\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 1 %_LOGFOLDER%
		REM :: В случае успеха выходим.
		REM IF %%S NEQ 1 IF %READY% EQU %AMOUNT% GOTO :BREAK_ATTEMP
	REM )
:BREAK_ATTEMP
	set /a READY=%READY% + %_READY%
	set /a AMOUNT=%_AMOUNT%

	REM call "%~dp0_update.bat" "%_UPDFOLDER%Stored Procedures\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 1 %_LOGFOLDER%
	:: call "%~dp0_update.bat" "%_UPDFOLDER%Queries\Settings\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 1 %_LOGFOLDER%
	:: call "%~dp0_update.bat" "%_UPDFOLDER%Queries\Permissions\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 1 %_LOGFOLDER%
	:: call "%~dp0_update.bat" "%_UPDFOLDER%Queries\Parameters\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 1 %_LOGFOLDER%
	:: call "%~dp0_update.bat" "%_UPDFOLDER%Queries\WebDocJournal\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 1 %_LOGFOLDER%

	:: ------------------------------------------------------------------------------------------------
	:: Подсчет затраченного времени.
	:: ------------------------------------------------------------------------------------------------
	:: :: Получаем текущее время.
	:: set ENDTIME=%time%
	:: @echo %ENDTIME%: Stop %~n0%~x0 >> %_LOGFOLDER%
	:: :: Переводим время в милисекунды.
	:: set /A STARTTIME=(%STARTTIME:~0,2%-100)*360000 + (%STARTTIME:~3,2%-100)*6000 + (%STARTTIME:~6,2%-100)*100 + (%STARTTIME:~9,2%-100)
	:: set /A ENDTIME=(%ENDTIME:~0,2%-100)*360000 + (%ENDTIME:~3,2%-100)*6000 + (%ENDTIME:~6,2%-100)*100 + (%ENDTIME:~9,2%-100)
	:: :: Находим разницу.
	:: set /A DURATION=%ENDTIME%-%STARTTIME%
	:: :: ???: Если разница в днях
	:: if %ENDTIME% LSS %STARTTIME% set set /A DURATION=%STARTTIME%-%ENDTIME%
	:: :: Получаем время выполнения в часах, минутах, секундах, мили секундах.
	:: set /A DURATIONH=%DURATION% / 360000
	:: set /A DURATIONM=(%DURATION% - %DURATIONH%*360000) / 6000
	:: set /A DURATIONS=(%DURATION% - %DURATIONH%*360000 - %DURATIONM%*6000) / 100
	:: set /A DURATIONHS=(%DURATION% - %DURATIONH%*360000 - %DURATIONM%*6000 - %DURATIONS%*100)
	:: :: Добиваем нули где их нет.
	:: if %DURATIONH% LSS 10 set DURATIONH=0%DURATIONH%
	:: if %DURATIONM% LSS 10 set DURATIONM=0%DURATIONM%
	:: if %DURATIONS% LSS 10 set DURATIONS=0%DURATIONS%
	:: if %DURATIONHS% LSS 10 set DURATIONHS=0%DURATIONHS%
	:: ------------------------------------------------------------------------------------------------
	:: Выводим лого для разделения.
	call "%~dp0_logo.bat"
	:: Выводим результат выполнения.
	IF %READY% NEQ %AMOUNT% echo %time%: %Red%Total number does not match the number of successful%RESC%
	IF %READY% EQU %AMOUNT% echo %time%: %Green%Total number corresponds to the number of successful%RESC%
	echo %time%: %BCyan%Total count - %READY%/%AMOUNT%%RESC%
	:: Время выполненея.
	echo.
	:: echo Total runtime - %DURATIONH%:%DURATIONM%:%DURATIONS%,%DURATIONHS%
	timeout /t 145
GOTO :EOF
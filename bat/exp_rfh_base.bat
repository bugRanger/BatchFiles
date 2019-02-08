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


	:: Обнуление результатов.
	set READY=0
	set AMOUNT=0
	:: Удаление файла.
	del %_LOGFOLDER% >NUL 2>&1
	:: ------------------------------------------------------------------------------------------------
	:: Время запуска.
	:: ------------------------------------------------------------------------------------------------
	set STARTTIME=%time%
	@echo %STARTTIME%: Start %~nx0 >> %_LOGFOLDER%
	REM Создание базы данных, по необходимости.
	:: ------------------------------------------------------------------------------------------------
	:: Создаем базу.
	:: ------------------------------------------------------------------------------------------------
	echo %time%: Create database...
	call "%~dp0_recreate.bat" "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% %_BASEFOLDER% 0 %_LOGFOLDER%
	REM Настройка базы, необходимая для успеха выполнения скриптов с проверкой на тип региона.
	:: ------------------------------------------------------------------------------------------------
	:: Устанавливаем региональный признак.
	:: ------------------------------------------------------------------------------------------------
	echo %time%: Make parameters...
	call "%~dp0_update.bat" "" "%_UPDFOLDER%Create Scripts\Parameters.sql" "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER% 
	:: Удаление файла.
	del region.sql >NUL 2>&1
	:: ------------------------------------------------------------------------------------------------
	:: Скрипт на изменение региональных настроек.
	:: ------------------------------------------------------------------------------------------------
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
	call "%~dp0_update.bat" "" "%~dp0region.sql" "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
	REM Обновление данных.
	:: ------------------------------------------------------------------------------------------------
	:: Выполняем региональные обновления.
	:: ------------------------------------------------------------------------------------------------
	echo %time%: Update content...
	:: Задаем каталоги.
	set TRASH=.\trash.log
	set TEMP=.\trash.tmp
	:: Удаление файла.
	del %TRASH% >NUL 2>&1
	REM Скрипты обновления, в случае ошибки падают в <c>TRASH</c> для повтора выполнения со смещением последовательности на -1.
	:: ------------------------------------------------------------------------------------------------
	:: Выполняем обновление.
	:: ------------------------------------------------------------------------------------------------
	call "%~dp0_update.bat" "%_UPDFOLDER%Stored Procedures\System\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
	call "%~dp0_update.bat" "%_UPDFOLDER%Create Scripts\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
	call "%~dp0_update.bat" "%_UPDFOLDER%Stored Procedures\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
	call "%~dp0_update.bat" "%_UPDFOLDER%Queries\Settings\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
	call "%~dp0_update.bat" "%_UPDFOLDER%Queries\Permissions\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
	call "%~dp0_update.bat" "%_UPDFOLDER%Queries\Parameters\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
	call "%~dp0_update.bat" "%_UPDFOLDER%Queries\WebDocJournal\" *.sql "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
	:: ------------------------------------------------------------------------------------------------
	:: Сохранение результатов выполнение, до повторов.
	:: ------------------------------------------------------------------------------------------------
	SET _READY=%READY%
	SET _AMOUNT=%AMOUNT%
	REM Выполняем повторы для разрешения конфликтов.
	:: ------------------------------------------------------------------------------------------------
	:: Выполняем попытку разрешения конфликтов.
	:: ------------------------------------------------------------------------------------------------
	SET STEP=0
:CHECK_TRASH
	:: Обнуление результатов.
	set READY=0
	set AMOUNT=0
	:: Проверка наличия.
	IF NOT EXIST "%TRASH%" GOTO :END_TRASH
	:: ------------------------------------------------------------------------------------------------
	:: ------------------------------------------------------------------------------------------------
	:: Создаем копию.
	del %TEMP%>NUL 2>&1
	copy /Y %TRASH% %TEMP%>NUL 2>&1
	:: Удаляем файл.
	del %TRASH%>NUL 2>&1
	:: ------------------------------------------------------------------------------------------------
	:: Получаем количество строк.
	:: ------------------------------------------------------------------------------------------------
	for /F "tokens=2 delims=:" %%A in ('find /c /v "" %TEMP%') do set /a count=%%A
	echo %time%:[%count%] Conflict resolution attempt...
	:: Проходим в обратном направление.
	setlocal enableextensions disabledelayedexpansion
	for /f "tokens=1,* delims=¬" %%a in ('
        cmd /v:off /e /q /c"set "counter^=10000000" & for /f usebackq^ delims^=^ eol^= %%c in ("%TEMP%") do (set /a "counter+^=1" & echo(¬%%c)"
        ^| sort /r
    ') do (
		call "%~dp0_update.bat" "" %%b "%_PROVIDER%" %_NAMEBASE% %_USERNAME% %_PASSWORD% 0 %_SILENT% %_LOGFOLDER%
    )
	:: ------------------------------------------------------------------------------------------------
	:: ------------------------------------------------------------------------------------------------
:END_TRASH
	:: ------------------------------------------------------------------------------------------------
	:: Задаем результаты выполнения.
	:: ------------------------------------------------------------------------------------------------
	set /a READY=%_READY%
	set /a AMOUNT=%_AMOUNT%
	:: ------------------------------------------------------------------------------------------------
	:: Подсчет затраченного времени.
	:: ------------------------------------------------------------------------------------------------
	:: Получаем текущее время.
	set ENDTIME=%time%
	@echo %ENDTIME%: Stop %~nx0 >> %_LOGFOLDER%
	:: Переводим время в миллисекунды.
	set /A STARTTIME=(%STARTTIME:~0,2%-100)*360000 + (%STARTTIME:~3,2%-100)*6000 + (%STARTTIME:~6,2%-100)*100 + (%STARTTIME:~9,2%-100)
	set /A ENDTIME=(%ENDTIME:~0,2%-100)*360000 + (%ENDTIME:~3,2%-100)*6000 + (%ENDTIME:~6,2%-100)*100 + (%ENDTIME:~9,2%-100)
	:: Находим разницу.
	set /A DURATION=%ENDTIME%-%STARTTIME%
	:: ???: Если разница в днях
	if [%ENDTIME%] LSS [%STARTTIME%] set set /A DURATION=%STARTTIME%-%ENDTIME%
	:: Получаем время выполнения в часах, минутах, секундах, мили секундах.
	set /A DURATIONH=%DURATION% / 360000
	set /A DURATIONM=(%DURATION% - %DURATIONH%*360000) / 6000
	set /A DURATIONS=(%DURATION% - %DURATIONH%*360000 - %DURATIONM%*6000) / 100
	set /A DURATIONHS=(%DURATION% - %DURATIONH%*360000 - %DURATIONM%*6000 - %DURATIONS%*100)
	:: Добиваем нули где их нет.
	if [%DURATIONH%] LSS [10] set DURATIONH=0%DURATIONH%
	if [%DURATIONM%] LSS [10] set DURATIONM=0%DURATIONM%
	if [%DURATIONS%] LSS [10] set DURATIONS=0%DURATIONS%
	if [%DURATIONHS%] LSS [10] set DURATIONHS=0%DURATIONHS%
	:: ------------------------------------------------------------------------------------------------
	:: Выводим лого для разделения.
	:: ------------------------------------------------------------------------------------------------
	call "%~dp0_logo.bat"
	:: ------------------------------------------------------------------------------------------------
	:: Выводим результат выполнения.
	:: ------------------------------------------------------------------------------------------------
	IF %READY% NEQ %AMOUNT% echo %time%: %Red%Total number does not match the number of successful%RESC%
	IF %READY% EQU %AMOUNT% echo %time%: %Green%Total number corresponds to the number of successful%RESC%
	echo %time%: %BCyan%Total count - %READY%/%AMOUNT%%RESC%
	:: ------------------------------------------------------------------------------------------------
	:: Время выполнения.
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
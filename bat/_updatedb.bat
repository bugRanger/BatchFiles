@echo off
:: Example: call {This}.bat "{DB_PROVIDER_}" "{DB_NAME_}" "{DB_USER_}" "{DB_PASS_}" "{DB_PATH_}" {REGION_GUID} {UPD_FOLDER_} {ATTEMP_} {SILENT_}
:: 1. {DB_PROVIDER_} - сервер (имя/адрес)
:: 2. {DB_NAME_} - наименование базы данных.
:: 3. {DB_USER_} - пользователь.
:: 4. {DB_PASS_} - пароль пользователя.
:: 5. {DB_PATH_} - путь до место хранения базы, как файла локально. ВНИМАНИЕ! Этот параметр используется для принудительного пересоздания базы данных.
:: 6. {REGION_GUID} - guid используемого региона.
:: 7. {UPD_FOLDER_} - папка с файлами обновления.
:: 8. {ATTEMP_} - повторы выполнения при наличие ошибок (1 по умолчанию)
:: 9. {SILENT_} - тихий режим(0 - off, 1 - on. off по умолчанию).
:: Example>
:: call {This}.bat "192.168.70.26" "Dev44_Atlan" "sa" "1234" "D:\Base" "3BDFDCFF-63DA-4010-9CAF-3F46CCBBBF73" "C:\Update\" 1 1
:: TODO> Необходимо обернуть параметры в ковычки иначе они выпадают при передаче.
:: Settings
SET DB_PROVIDER_=%1
SET DB_NAME_=%2
SET DB_USER_=%3
SET DB_PASS_=%4
SET DB_PATH_=%5
SET DB_PATH_=%DB_PATH_:"=%
SET DB_PATH_="%DB_PATH_%"
SET REGION_GUID=%6
SET REGION_GUID=%REGION_GUID:"=%
SET UPD_FOLDER_=%7
SET UPD_FOLDER_=%UPD_FOLDER_:"=%
SET ATTEMP_=%8
SET SILENT_=%9
:: Если не был указан лог то выпадет ошибка.
SET LOGFILE_=%LOGFILE_%
SET LOGFILE_=%LOGFILE_:"=%
SET LOGFILE_="%LOGFILE_%"

:: Проверка на наличие параметра.
IF [%1] EQU [] (
	echo.Need to specify arguments
	pause
	GOTO :EOF
)

	:: Папка для временных файлов.
	set temp_=.\temp\
	IF NOT EXIST "%temp_%" mkdir "%temp_%"
	:: Обнуление результатов.
	set READY=0
	set AMOUNT=0
	:: Значения по умолчанию
	IF [%SILENT_%] EQU [] set SILENT_=1
	IF [%ATTEMP_%] EQU [] set ATTEMP_=1
	IF [%ATTEMP_%] NEQ [] set /a ATTEMP_=%ATTEMP_%+1
	IF [%LOGFILE_%] EQU [""] set LOGFILE_=.\%~n0.log
	:: Удаление файла.
	REM del %LOGFILE_% >NUL 2>&1
	:: ------------------------------------------------------------------------------------------------
	:: Время запуска.
	:: ------------------------------------------------------------------------------------------------
	set STARTTIME=%time%
	IF [%SILENT%] EQU [0] (
		echo.%STARTTIME%: Start %~nx0
		@echo.%STARTTIME%: Start %~nx0 >> %LOGFILE_%
	)
:: ----------------------------------------------------------------------------------------------------
:: Воссоздание базы данных.
:: ----------------------------------------------------------------------------------------------------
:RECREATE
	:: Проверка наличия.
	IF [%DB_PATH_%] EQU [""] GOTO :END_RECREATE
	:: ------------------------------------------------------------------------------------------------
	:: Создаем базу.
	:: ------------------------------------------------------------------------------------------------
	echo.%time%: Create database...
	@echo.%time%: Create database... >> %LOGFILE_%
	call "%~dp0_recreate.bat" "%DB_PROVIDER_%" %DB_NAME_% %DB_USER_% %DB_PASS_% %DB_PATH_% 0 %LOGFILE_%
	:: ------------------------------------------------------------------------------------------------
	:: Устанавливаем региональный признак.
	:: ------------------------------------------------------------------------------------------------
	echo.%time%: Make parameters...
	@echo.%time%: Make parameters... >> %LOGFILE_%
	call "%~dp0_update.bat" "" "%UPD_FOLDER_%Create Scripts\Parameters.sql" "%DB_PROVIDER_%" %DB_NAME_% %DB_USER_% %DB_PASS_% %ATTEMP_% %SILENT_% %LOGFILE_%
	call "%~dp0_update.bat" "" "%UPD_FOLDER_%Stored Procedures\System\GetBoolSystemUUID.sql" "%DB_PROVIDER_%" %DB_NAME_% %DB_USER_% %DB_PASS_% %ATTEMP_% %SILENT_% %LOGFILE_%
:END_RECREATE
	:: Проверка наличия.
	IF [%REGION_GUID%] EQU [] GOTO :END_REGION
	:: Удаление файла.
	set REGION=%temp_%UpdateRegion.sql
	del %REGION% >NUL 2>&1
	:: ------------------------------------------------------------------------------------------------
	:: Скрипт на изменение региональных настроек.
	:: ------------------------------------------------------------------------------------------------
	echo DECLARE @parameterValue VARCHAR(MAX), @parameterName VARCHAR(MAX) >> %REGION%
	echo SET @parameterValue = '%REGION_GUID%' >> %REGION%
	echo SET @parameterName = 'SystemUUID' >> %REGION%
	echo IF NOT EXISTS (SELECT * FROM [Parametrs] WHERE Parametr_Name = @parameterName) >> %REGION%
	echo BEGIN >> %REGION%
	echo 	INSERT INTO [Parametrs] (Parametr_Name, Parametr_Value, Coments) >> %REGION%
	echo 	VALUES (@parameterName, @parameterValue, 'Тип используемых региональных настроек'); >> %REGION%
	echo END >> %REGION%
	echo ELSE >> %REGION%
	echo BEGIN >> %REGION%
	echo 	UPDATE [Parametrs] >> %REGION%
	echo 	SET Parametr_Value = @parameterValue >> %REGION%
	echo 	WHERE Parametr_Name = @parameterName >> %REGION%
	echo END >> %REGION%
	:: Устанавливаем региональный признак.
	call "%~dp0_update.bat" "" "%REGION%" "%DB_PROVIDER_%" %DB_NAME_% %DB_USER_% %DB_PASS_% %ATTEMP_% %SILENT_% %LOGFILE_%
:END_REGION
	:: ------------------------------------------------------------------------------------------------
	:: Выполняем региональные обновления.
	:: ------------------------------------------------------------------------------------------------
	echo.%time%: Update content...
	@echo.%time%: Update content... >> %LOGFILE_%
	:: Задаем каталоги.
	set TRASH=%temp_%trash.log
	set TEMP=%temp_%trash.tmp
	:: Удаление файла.
	del %TRASH% >NUL 2>&1
	:: Скрипты обновления, в случае ошибки падают в <c>TRASH</c> для повтора выполнения со смещением последовательности на -1.
	:: ------------------------------------------------------------------------------------------------
	:: Выполняем обновление.
	:: ------------------------------------------------------------------------------------------------
	call "%~dp0_update.bat" "%UPD_FOLDER_%Create Scripts\" *.sql "%DB_PROVIDER_%" %DB_NAME_% %DB_USER_% %DB_PASS_% %ATTEMP_% %SILENT_% %LOGFILE_%
	call "%~dp0_update.bat" "%UPD_FOLDER_%Stored Procedures\" *.sql "%DB_PROVIDER_%" %DB_NAME_% %DB_USER_% %DB_PASS_% %ATTEMP_% %SILENT_% %LOGFILE_%
	call "%~dp0_update.bat" "%UPD_FOLDER_%Queries\Settings\" *.sql "%DB_PROVIDER_%" %DB_NAME_% %DB_USER_% %DB_PASS_% %ATTEMP_% %SILENT_% %LOGFILE_%
	call "%~dp0_update.bat" "%UPD_FOLDER_%Queries\Permissions\" *.sql "%DB_PROVIDER_%" %DB_NAME_% %DB_USER_% %DB_PASS_% %ATTEMP_% %SILENT_% %LOGFILE_%
	call "%~dp0_update.bat" "%UPD_FOLDER_%Queries\Parameters\" *.sql "%DB_PROVIDER_%" %DB_NAME_% %DB_USER_% %DB_PASS_% %ATTEMP_% %SILENT_% %LOGFILE_%
	call "%~dp0_update.bat" "%UPD_FOLDER_%Queries\WebDocJournal\" *.sql "%DB_PROVIDER_%" %DB_NAME_% %DB_USER_% %DB_PASS_% %ATTEMP_% %SILENT_% %LOGFILE_%
	call "%~dp0_update.bat" "%UPD_FOLDER_%Queries\FillingOfDirectories\" *.sql "%DB_PROVIDER_%" %DB_NAME_% %DB_USER_% %DB_PASS_% %ATTEMP_% %SILENT_% %LOGFILE_%
	call "%~dp0_update.bat" "%UPD_FOLDER_%Views\" *.sql "%DB_PROVIDER_%" %DB_NAME_% %DB_USER_% %DB_PASS_% %ATTEMP_% %SILENT_% %LOGFILE_%
	:: ------------------------------------------------------------------------------------------------
	:: Сохранение результатов выполнение, до повторов.
	:: ------------------------------------------------------------------------------------------------
	SET _READY=%READY%
:: ----------------------------------------------------------------------------------------------------
:: Выполняем попытку разрешения конфликтов.
:: ----------------------------------------------------------------------------------------------------
:CHECK_TRASH
	REM GOTO :END_TRASH
	:: Проверка наличия.
	IF NOT EXIST "%TRASH%" GOTO :END_TRASH
	:: Создаем копию.
	del %TEMP%>NUL 2>&1
	copy /Y %TRASH% %TEMP%>NUL 2>&1
	:: Удаляем файл.
	del %TRASH%>NUL 2>&1
	:: ------------------------------------------------------------------------------------------------
	:: Получаем количество строк.
	:: ------------------------------------------------------------------------------------------------
	for /F "tokens=2 delims=:" %%A in ('find /c /v "" %TEMP%') do set /a count=%%A
	echo.%time%:[%count%] Conflict resolution...
	@echo.%time%:[%count%] Conflict resolution... >> %LOGFILE_%
	:: Проходим в обратном направление.
	SetLocal EnableExtensions DisableDelayedExpansion
	for /f "tokens=1,* delims=¬" %%a in ('
		cmd /v:off /e /q /c"set "counter^=10000000" & for /f usebackq^ delims^=^ eol^= %%c in ("%TEMP%") do (set /a "counter+^=1" & echo(¬%%c)"
		^| sort /r
	') do (
		call "%~dp0_update.bat" "" %%b "%DB_PROVIDER_%" %DB_NAME_% %DB_USER_% %DB_PASS_% 0 %SILENT_% %LOGFILE_%
	)
	(
		EndLocal
		set /a READY=%READY%
	)
:END_TRASH
	:: ------------------------------------------------------------------------------------------------
	:: Подсчет затраченного времени.
	:: ------------------------------------------------------------------------------------------------
	:: Получаем текущее время.
	set ENDTIME=%time%
	IF [%SILENT%] EQU [0] (
		echo.%ENDTIME%: Stop %~nx0
		@echo.%ENDTIME%: Stop %~nx0 >> %LOGFILE_%
	)
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
	IF %READY% NEQ %AMOUNT% (
		echo.%time%: %Red%Total number does not match the number of successful%RESC%
		@echo.%time%: Total number does not match the number of successful >> %LOGFILE_%
	)
	IF %READY% EQU %AMOUNT% (
		echo.%time%: %Green%Total number corresponds to the number of successful%RESC%
		@echo.%time%: Total number corresponds to the number of successful >> %LOGFILE_%
	)
	echo.%time%: %BCyan%Total count - %READY%/%AMOUNT%%RESC%
	@echo.%time%: Total count - %READY%/%AMOUNT% >> %LOGFILE_%
	:: ------------------------------------------------------------------------------------------------
	:: Время выполнения.
	:: ------------------------------------------------------------------------------------------------
	echo.
	echo.Total runtime - %DURATIONH%:%DURATIONM%:%DURATIONS%,%DURATIONHS%
	@echo.Total runtime - %DURATIONH%:%DURATIONM%:%DURATIONS%,%DURATIONHS% >> %LOGFILE_%
	REM pause
	REM timeout /t 145
GOTO :EOF
@echo off
:: Example: call {This}.bat "{DIR_}" "{NAME_}" "{PROVIDER_}" "{BASE_}" "{USER_}" "{PASS_}" "{URL}" {ATTEMP_} {SILENT_}
:: 1. {DIR_} - Рабочий каталог.
:: 2. {NAME_} - Наименование исп. в обозначение (временная папка с обновлениями, журнал выполнения, файл обновления ревизии)
:: 1. {PROVIDER_} - сервер (имя/адрес)
:: 2. {BASE_} - наименование базы данных.
:: 3. {USER_} - пользователь.
:: 4. {PASS_} - пароль пользователя.
:: 6. {URL} - ссылка на snv.
:: 8. {ATTEMP_} - повторы выполнения при наличие ошибок (1 по умолчанию)
:: 9. {SILENT_} - тихий режим(0 - off, 1 - on. off по умолчанию).
:: Example>
:: call {This}.bat "%~dp0" "%~n0" "192.168.70.26" "Dev44_AltaiKrai" "sa" "testSA" "http://192.168.70.51/AIS/dev.v3/SIMADATABASE" 0 1
:: Settings
SET DIR_=%1
SET DIR_=%DIR_:"=%
SET NAME_=%2
SET NAME_=%NAME_:"=%
SET PROVIDER_=%3
SET PROVIDER_=%PROVIDER_:"=%
SET BASE_=%4
SET BASE_=%BASE_:"=%
SET USER_=%5
SET USER_=%USER_:"=%
SET PASS_=%6
SET PASS_=%PASS_:"=%
SET URL=%7
SET "URL=%URL:"=%"
SET ATTEMP=%8
SET SILENT=%9
SET /a SILENT=%SILENT% + 1

:: Color for rows
SET ESC=
SET RESC=%ESC%[0m
SET Red=%ESC%[91m
SET Cyan=%ESC%[36m
SET BCyan=%ESC%[96m
SET BWhite=%ESC%[97m
SET Green=%ESC%[92m
SET Yellow=%ESC%[93m
SET Tooltip=%ESC%[90m

:: Local settings
SET REVISION_DIR_="%DIR_%%NAME_%\"
SET REVISION_FILE_="%DIR_%%NAME_%.grev"

SET DIRLOG=%DIR_%logs
SET LOGFILE_=%DIR_%%NAME_%.log
SET LOGFILE_=%LOGFILE_:"=%
SET LOGFILE_="%LOGFILE_%"

	:: ------------------------------------------------------------------------------------------------
	:: Время запуска.
	:: ------------------------------------------------------------------------------------------------
	set STARTTIME=%time%
	IF [%SILENT%] EQU [0] (
		echo.%STARTTIME%: Start %~nx0
		@echo.%STARTTIME%: Start %~nx0 >> %LOGFILE_%
	)
	echo.%STARTTIME%: %Cyan%Update the %BCyan%%BASE_%%BWhite%[%PROVIDER_%]%RESC%
	echo.%STARTTIME%: %Cyan%Using data from %BCyan%%URL%%RESC%
	@echo.%STARTTIME%: Update the %BASE_%[%PROVIDER_%] >> %LOGFILE_%
	@echo.%STARTTIME%: Using data from %URL% >> %LOGFILE_%
	:: ------------------------------------------------------------------------------------------------
	:: Проверка наличия.
	:: ------------------------------------------------------------------------------------------------
	IF ["%URL%"] EQU [""] (
		@echo.%time%: You must specify URL >> %LOGFILE_%
		echo.%time%: You must specify URL & goto :EOF
	)

	:: Обнуление результатов.
	set READY=0
	set AMOUNT=0
	:: Удаляем каталог для ревизии.
	rd /S /Q %REVISION_DIR_% >NUL 2>&1
	:: ------------------------------------------------------------------------------------------------
	:: Получаем последнюю успешную версию.
	:: ------------------------------------------------------------------------------------------------
	SET LAST_REVISION=0
	IF EXIST %REVISION_FILE_% set /p LAST_REVISION= <%REVISION_FILE_%
	:: Задаем вопрос.
	CHOICE /C YN /N /T 15 /D N /M "%time%: %Yellow%Retry last update?%RESC% [Enter:Y/%BCyan%N%RESC%]"
	:: Отмена операции повтора, получаем последнюю версию ревизии.
	IF ERRORLEVEL 2 FOR /f "tokens=1 delims=:" %%a IN ("%LAST_REVISION%") DO SET LAST_REVISION=%%a
	:: Получено согласие на обновление от предпоследней версии ревизии.
	IF ERRORLEVEL 0 SET LAST_REVISION=%LAST_REVISION:*:=%
	:: Информируем о последней версии.
	echo.%time%: Last revision version - %LAST_REVISION%
	@echo.%time%: Last revision version - %LAST_REVISION% >> %LOGFILE_%
	:: ------------------------------------------------------------------------------------------------
	:: Получить текущую версию.
	:: ------------------------------------------------------------------------------------------------
	SET CURR_REVISION=0
	for /f %%i in ('svn info --show-item=revision %URL%') do set /a CURR_REVISION=%%i
	echo.%time%: Current revision version - %CURR_REVISION%
	@echo.%time%: Current revision version - %CURR_REVISION% >> %LOGFILE_%
:: ----------------------------------------------------------------------------------------------------
:: Проверка наличия.
:: ----------------------------------------------------------------------------------------------------
IF ["%LAST_REVISION%"] EQU ["%CURR_REVISION%"] (
	@echo.%time%: No revisions available >> %LOGFILE_%
	echo.%time%: %BCyan%No revisions available%RESC% & goto :EOF
)

	echo.%time%: Getting files from revision...
	@echo.%time%: Getting files from revision... >> %LOGFILE_%
	:: Создаем каталог для ревизии.
	IF NOT EXIST %REVISION_DIR_% mkdir %REVISION_DIR_%
	:: Параметры для получения файлов, по типу изменения и расширения.
	set "append=A       "
	set "modified=M       "
	set ext=.sql
	:: Получаем список файлов.
	SetLocal EnableDelayedExpansion
	for /f "delims=" %%A in ('svn diff --summarize -r %CURR_REVISION%:%LAST_REVISION% %URL%') do (
		set file=%%A
		set file=!file:%append%=!
		set file=!file:%modified%=!
		:: Получаем из имени файла информацию о подкаталогах.
		for /f "delims=" %%i in ("!file!") do (
			:: Формируем путь хранения.
			set spath=!file!
			set spath=!spath:%%20= !
			set dpath=%REVISION_DIR_%!file:%URL%=!
			set dpath=!dpath:%%~nxi=!
			set dpath=!dpath:/=\!
			set dpath=!dpath:"=!
			set dpath=!dpath:%%20= !
			set dpath="!dpath!"
			set fname=%%~nxi
			set fname=!fname:%%20= !
		)
		:: Получение файлов только соответствующие типу изменения и расширению.
		IF ["!file!"] NEQ ["%%A"] echo.!file! | FIND /I "%ext%">nul && ( 
			:: Создаем каталог.
			IF NOT EXIST !dpath! mkdir !dpath!
			cd /d !dpath!
			:: Выполняем.
			call :RunScript 1 "!spath!" "!fname!"
		)
	)
	(
		EndLocal
		set /A READY=%READY% + %SUCCESS%
		set /A AMOUNT=%AMOUNT% + %TOTAL%
	)

	:: Вызываем обновление.
	echo.%time%: Execute scripts...
	@echo.%time%: Execute scripts... >> %LOGFILE_%
	call "%~dp0_updatedb.bat" %PROVIDER_% %BASE_% %USER_% %PASS_% "" "" %REVISION_DIR_% %ATTEMP% %SILENT%
	:: Проверка результата.
	IF [%CURR_REVISION%] NEQ [%LAST_REVISION%] echo.%CURR_REVISION%:%LAST_REVISION%>%REVISION_FILE_%

	:: Получаем текущее время.
	set ENDTIME=%time%
	IF [%SILENT%] EQU [0] (
		echo.%ENDTIME%: Stop %~nx0
		@echo.%ENDTIME%: Stop %~nx0 >> %LOGFILE_%
	)
	REM pause
	REM timeout /t 145

GOTO :EOF
:RunScript

	IF NOT EXIST "%DIRLOG%" mkdir "%DIRLOG%"
	:: Получаем время для наименования лога.
	set /a TM=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%%TIME:~9,2%
	set /a TM=%TM: =0%
	:: Получаем наименования для действия, кавычки(quotes) меняем на пустоту.
	set ACT=%3
	set ACT=%ACT:"=%
	set ACT=%ACT:(=^^(%
	set ACT=%ACT:)=^^)%
	:: Проверяем наличие общего лога.
	IF [%LOGFILE_%] EQU [] set LOG="%DIRLOG%\%TM%_%~n2.log"
	IF [%LOGFILE_%] NEQ [] set LOG=%LOGFILE_%
	:: Пишем в консоль и в лог.
	IF [%SILENT%] EQU [0] (
		echo.%time%:[%1] [%Yellow%QUERY%RESC%] ^> %ACT%
		@echo.%time%:[%1] [QUERY] ^> %ACT% >> %LOG%
	)
	:: Форматирование пути.
	set "item=%2"
	set item=!item: =%%20!
	set item=!item:"=!
	:: Выполняем...
	svn export -r %CURR_REVISION% "%item%" 1>nul 2>>%LOG%
	:: Подсчет результатов.
	set /A TOTAL=!TOTAL!+1
	:: Проверка на ошибку...
	IF !ERRORLEVEL! EQU 0 (
		IF [%SILENT%] LSS [3] echo.%time%:[%1] [%Green%READY%RESC%] ^< %ACT%
		@echo.%time%:[%1] [READY] ^< %ACT% >> %LOG%
		set /A SUCCESS=!SUCCESS!+1
	)
	IF !ERRORLEVEL! NEQ 0 (
		IF [%SILENT%] LSS [3] echo.%time%:[%1] [%Red%ERROR%RESC%] ^< %ACT%
		@echo.%time%:[%1] [ERROR] ^< %ACT% ^(%2^) >> %LOG%
		:: Пишем заметку о файле с ошибкой в свалку.
		IF [!TRASH!] NEQ [] (
			@echo.%2 >> !TRASH!
		)
	)
GOTO :EOF
REM :: Извлекаем файл.
REM svn export -r %CURR_REVISION% !file!
REM :: Пример поиска в строке строку.
REM echo.!t! | FIND /I "%ext%">nul && ( Echo.Found "%ext%" ) || ( Echo.Did not find "%ext%" )
REM :: Получения списка изменений.
REM svn diff --summarize -r %CURR_REVISION%:%LAST_REVISION% %URL% >> 1.txt
REM :: Получение локального репозитория.
REM svn checkout -r 17553:17500 http://192.168.70.51/AIS/dev.v3/SIMADATABASE
REM :: Получаем список файлов под обновление.
REM svn diff --summarize -r 17553:17500 http://192.168.70.51/AIS/dev.v3/SIMADATABASE
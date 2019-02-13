@echo off
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
:: ----------------------------------------------------------------------------------------------------
:: Поднимаемся на уровень выше.
:: ----------------------------------------------------------------------------------------------------
cd..
:: Settings
SET PROVIDER_=STUDENTPC\SQLEXPRESS
SET BASE_=AltaiKrai
SET USER_=sa
SET PASS_=1234
SET "URL=http://192.168.70.51/AIS/dev.v3/SIMADATABASE"
SET ATTEMP=0
SET SILENT=1

:: Color for rows
SET ESC=
SET RESC=%ESC%[0m
SET Red=%ESC%[91m
SET Cyan=%ESC%[36m
SET BCyan=%ESC%[96m
SET Green=%ESC%[92m
SET Yellow=%ESC%[93m
SET Tooltip=%ESC%[90m


:: Local settings
SET REVISION_DIR_="%~dp0%~n0\"
SET REVISION_FILE_="%~dp0%~n0.grev"

SET DIRLOG=%~dp0logs
SET LOGFILE_=%~dp0%~n0.log


:: ----------------------------------------------------------------------------------------------------
:: Проверка наличия.
:: ----------------------------------------------------------------------------------------------------
IF ["%URL%"] EQU [""] echo.%time%: You must specify URL & pause & goto :EOF

	:: Обнуление результатов.
	set READY=0
	set AMOUNT=0
	:: Создаем каталог для ревизии.
	rd /S /Q %REVISION_DIR_% >NUL 2>&1
	:: ------------------------------------------------------------------------------------------------
	:: Получаем последнюю успешную версию.
	:: ------------------------------------------------------------------------------------------------
	SET LAST_REVISION=0
	IF EXIST %REVISION_FILE_% set /p LAST_REVISION= <%REVISION_FILE_%
	echo.%time%: Last revision version - %LAST_REVISION%
	:: ------------------------------------------------------------------------------------------------
	:: Получить текущую версию.
	:: ------------------------------------------------------------------------------------------------
	SET CURR_REVISION=0
	for /f %%i in ('svn info --show-item=revision %URL%') do set /a CURR_REVISION=%%i
	echo.%time%: Current revision version - %CURR_REVISION%
:: ----------------------------------------------------------------------------------------------------
:: Проверка наличия.
:: ----------------------------------------------------------------------------------------------------
IF ["%LAST_REVISION%"] EQU ["%CURR_REVISION%"] echo.%time%: No revisions available & pause & goto :EOF

	echo.%time%: Getting files from revision...
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
	IF ERRORLEVEL 0 IF %READY% EQU %AMOUNT% call _updatedb.bat %PROVIDER_% %BASE_% %USER_% %PASS_% "" "" %REVISION_DIR_% 0 1
	:: Проверка результата.
	IF ERRORLEVEL 0 IF %READY% EQU %AMOUNT% echo.%CURR_REVISION%>%REVISION_FILE_%

pause
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
	IF [%LOGFILE%] EQU [] set LOG="%DIRLOG%\%TM%_%~n2.log"
	IF [%LOGFILE%] NEQ [] set LOG=%LOGFILE%
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
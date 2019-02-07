@echo off
REM Example: call {This}.bat "{Server}" "{BaseName}" "{login}" "{password}" "{BasePath}" {Silent} {LogFile}
REM 1. {Server} - сервер (имя/адрес)
REM 2. {BaseName} - наименование базы данных.
REM 3. {login} - пользователь.
REM 4. {password} - пароль пользователя.
REM 5. {BasePath(use_only_for_recreate)} - путь до место хранения базы, как файла локально. ВНИМАНИЕ! Этот параметр используется для принудительного пересоздания базы данных.
REM 6. {Silent} - тихий режим(0 - off, 1 - on. off по умолчанию).
REM 7. {LogFile} - файл для сбора результатов выполнения.
REM Example>call _recreate.bat "192.168.70.26" "Dev44_Atlan" "sa" "testSA" "C:\Temp" 1 ".\result.log"

SET PROVIDER=%1
SET NAMEBASE=%2
SET USERNAME=%3
SET PASSWORD=%4
SET PATHBASE=%5
SET SILENT=%6
SET LOGFILE=%7
SET MAKEPATH=.\_recreate\
SET DIRMAKE=.\__recreate\
SET DIRLOG=%~dp0
SET DIRLOG=%DIRLOG%logs
REM Color for rows
SET ESC=
SET RESC=%ESC%[0m
SET Red=%ESC%[91m
SET Cyan=%ESC%[36m
SET BCyan=%ESC%[96m
SET Green=%ESC%[92m
SET Yellow=%ESC%[93m
SET Tooltip=%ESC%[90m

REM Указываем выполнение с задержкой, т.к. у нас есть подсчет в цикле итераций (иначе подсчет не будет корректно выполняться).
SetLocal enabledelayedexpansion
SetLocal enableextensions 
	REM Значения по умолчанию
	IF [%SILENT%] EQU [] set SILENT=1
	IF [%PATHBASE%] EQU [] set PATHBASE=""
	
	REM Директория...
	cd /d %~dp0
	REM Очищаем скрипты...
	rd /S /Q %DIRMAKE% >NUL 2>&1

	REM Проверка пути к базе данных как флага для выполнения пересоздания...
	REM IF NOT EXIST "%PATHBASE%%NAMEBASE%*.mdf" (
	REM IF NOT EXIST "%PATHBASE%" GOTO SkipRecreate)
	REM Подготавливаем скрипты...
	call %MAKEPATH%replace.bat %MAKEPATH% "detach.sql" "_detach.sql" "NAME_BASE" %NAMEBASE%
	call %MAKEPATH%replace.bat %MAKEPATH% "drop.sql" "_drop.sql" "NAME_BASE" %NAMEBASE%
	call %MAKEPATH%replace.bat %MAKEPATH% "make.sql" "__make.sql" "NAME_BASE" %NAMEBASE%
	call %MAKEPATH%replace.bat %MAKEPATH% "__make.sql" "_make.sql" "PATH_BASE" %PATHBASE%
	REM Подготавливаем скрипты для наполнения...
	del "%MAKEPATH%__*.sql" >NUL 2>&1
	xcopy %MAKEPATH%_*.sql %DIRMAKE% /Y /C /R /S /I /Q >NUL
	del "%MAKEPATH%_*.sql" >NUL 2>&1
	REM Извлекаем базу данных...
	REM call :RunScript 0 "%DIRMAKE%_detach.sql" "Detach base - %NAMEBASE%"
	call :RunScript 0 "%DIRMAKE%_drop.sql" "Drop base - %NAMEBASE%"
	REM Удаляем базу данных...
	REM del %PATHBASE%%NAMEBASE%*.mdf >NUL 2>&1
	REM del %PATHBASE%%NAMEBASE%*.ldf >NUL 2>&1
	REM Создаем базу данных...
	call :RunScript 0 "%DIRMAKE%_make.sql" "Create base - %NAMEBASE%"
:SkipRecreate
	REM Очищаем скрипты...
	rd /S /Q %DIRMAKE% >NUL 2>&1 
	REM Директория...
	cd /d %cd%
( 
	EndLocal
)
GOTO :EOF
:RunScript
	IF NOT EXIST "%DIRLOG%" mkdir "%DIRLOG%"
	REM Получаем время для наименования лога.
	set /a TM=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%%TIME:~9,2%
	set /a TM=%TM: =0%
	REM Получаем наименования для действия, кавычки(quotes) меняем на пустоту.
	set ACT=%3
	set ACT=%ACT:"=%
	REM Проверяем наличие общего лога.
	IF [%LOGFILE%] EQU [] set LOG="%DIRLOG%\%TM%_%~n2.log"
	IF [%LOGFILE%] NEQ [] set LOG=%LOGFILE%
	REM Пишем в консоль и в лог.
	IF [%SILENT%] EQU [1] (
		echo %time%:[%1] [%Yellow%QUERY%RESC%] ^> %ACT%
		@echo %time%:[%1] [QUERY] ^> %ACT% >> %LOG%
	)
	REM Выполняем скрипт...
	sqlcmd -S %PROVIDER% -U %USERNAME% -P %PASSWORD% -b -i %2 -r0 1> NUL 2>> %LOG%
	REM Проверка на ошибку...
	IF !ERRORLEVEL! EQU 0 (
		echo %time%:[%1] [%Green%READY%RESC%] ^< %ACT%
		@echo %time%:[%1] [READY] ^< %ACT% >> %LOG%
		set /A SUCCESS=!SUCCESS!+1
	)
	IF !ERRORLEVEL! NEQ 0 (
		echo %time%:[%1] [%Red%ERROR%RESC%] ^< %ACT%
		@echo %time%:[%1] [ERROR] ^< %ACT% >> %LOG%
	)
	set /A TOTAL=!TOTAL!+1
GOTO :EOF
@echo off
REM call {This}.bat "{UPD_FOLDER}" {UPD_FILE} {DB_PROVIDER} "{DB_NAME}" "{DB_USER}" "{DB_PASS}" {Attemp} {Silent} {LogFile}
REM 1. {UPD_FOLDER} - папка с файлами обновления.
REM 2. {UPD_FILE} - наименование выполняемых файлов.
REM 2. {DB_PROVIDER} - сервер (имя/адрес).
REM 3. {DB_NAME} - база данных.
REM 4. {DB_USER} - пользователь.
REM 5. {DB_PASS} - пароль пользователя.
REM 6. {Attemp} - повторы выполнения при наличие ошибок (1 по умолчанию)
REM 7. {Silent} - тихий режим(0 - off, 1 - on. off по умолчанию).
REM 8. {LogFile} - файл для сбора результатов выполнения.
REM Example>call _update.bat "C:\Temp" "*.sql" "192.168.70.26" "Dev44_Atlan" "sa" "testSA" 0 1 ".\result.log"

REM Settings
SET UPD_FOLDER=%1
SET UPD_FILE=%2
SET DB_PROVIDER=%3
SET DB_NAME=%4
SET DB_USER=%5
SET DB_PASS=%6
SET ATTEMP=%7
SET SILENT=%8
SET LOGFILE=%9
REM Color for rows
SET ESC=
SET RESC=%ESC%[0m
SET Red=%ESC%[91m
SET Cyan=%ESC%[36m
SET BCyan=%ESC%[96m
SET Green=%ESC%[92m
SET Yellow=%ESC%[93m
SET Tooltip=%ESC%[90m

SET DIRLOG=%~dp0logs
SET TRASH=%TRASH%

REM Указываем выполнение с задержкой, т.к. у нас есть подсчет в цикле итераций (иначе подсчет не будет корректно выполняться).
SetLocal EnableDelayedExpansion
	REM Значения по умолчанию
	IF [%SILENT%] EQU [] set SILENT=1
	IF [%ATTEMP%] EQU [] set ATTEMP=1
	IF [%ATTEMP%] NEQ [] set /a ATTEMP=ATTEMP+1
	REM Очищаем скрипты...
	IF EXIST "%DIRLOG%" RD /S /Q "%DIRLOG%"
	set /a ERROR_COUNT=0
	set /a LAST_ERROR_COUNT=1
	for /L %%A in (1,1,%ATTEMP%) do (
		REM Проверка на кол-во ошибок после повтора.
		IF !ERROR_COUNT! NEQ !LAST_ERROR_COUNT! (
			call :RunExecute %%A
			set /A ERROR_COUNT=!SUCCESS! - !TOTAL!
		)
		set /a LAST_ERROR_COUNT=!SUCCESS! - !TOTAL!
	)
( 
	EndLocal
	set FOLDER=%UPD_FOLDER%
	set /A READY=%READY% + %SUCCESS%
	set /A AMOUNT=%AMOUNT% + %TOTAL%
)
GOTO :EOF
:RunExecute
	set /A SUCCESS=0
	set /A TOTAL=0
	REM Выполняем скрипты...
	for /R %UPD_FOLDER% %%G in (%UPD_FILE%) do call :RunScript %1 "%%G" "%%~nxG"
	IF [%SILENT%] LSS [2] IF %SUCCESS% NEQ %TOTAL% (
		echo %time%:[%1] %Red%Total number does not match the number of successful%RESC%
	)
	IF [%SILENT%] LSS [2] IF %SUCCESS% EQU %TOTAL% (
		echo %time%:[%1] %Green%Total number corresponds to the number of successful%RESC%
	)
	IF [%SILENT%] LSS [2] echo %time%: %BCyan%Count - %SUCCESS%/%TOTAL%%RESC%
GOTO :EOF
:RunScript
	IF NOT EXIST %2 GOTO :EOF
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
	IF [%SILENT%] EQU [0] (
		echo %time%:[%1] [%Yellow%QUERY%RESC%] ^> %ACT%
		@echo %time%:[%1] [QUERY] ^> %ACT% >> %LOG%
	)
	REM Выполняем скрипт...
	sqlcmd -S %DB_PROVIDER% -d %DB_NAME% -U %DB_USER% -P %DB_PASS% -b -i %2 -r0 1> NUL 2>> !LOG!
	set /A TOTAL=!TOTAL!+1
	REM Проверка на ошибку...
	IF !ERRORLEVEL! EQU 0 (
		IF [%SILENT%] LSS [3] echo %time%:[%1] [%Green%READY%RESC%] ^< %ACT%
		@echo %time%:[%1] [READY] ^< %ACT% >> %LOG%
		set /A SUCCESS=!SUCCESS!+1
	)
	IF !ERRORLEVEL! NEQ 0 (
		IF [%SILENT%] LSS [3] echo %time%:[%1] [%Red%ERROR%RESC%] ^< %ACT%
		@echo %time%:[%1] [ERROR] ^< %ACT% >> %LOG%
		REM Пишем заметку о файле с ошибкой в свалку.
		IF [!TRASH!] NEQ [] (
			@echo %2 >> !TRASH!
		)
	)
GOTO :EOF
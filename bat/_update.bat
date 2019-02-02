@echo off
REM call {This}.bat "{Folder}" {Provider} "Base" "{Login}" "{Password}" {Silent}
REM {Folder} - папка с файлами обновления.
REM {Provider} - Сервер базы.
REM {Base} - база данных.
REM {Login} - пользователь.
REM {Password} - пароль пользователя.
REM {Silent} - тихий режим(0 - off, 1 - on. off по умолчанию).
REM {Attemp} - повторы выполнения при наличие ошибок (1 по умолчанию)
REM Example>call _update.bat "C:\Temp" "192.168.70.26" "Dev44_Atlan" "sa" "testSA" 0 1

REM Settings
SET UPDATAPATH=%1
SET PROVIDER=%2
SET NAMEBASE=%3
SET USERNAME=%4
SET PASSWORD=%5
SET SILENT=%6
SET ATTEMP=%7
REM Color for rows
SET ESC=
SET RESC=%ESC%[0m
SET Red=%ESC%[91m
SET Green=%ESC%[92m
SET Yellow=%ESC%[93m
SET Tooltip=%ESC%[90m
SET DIRLOG=%~dp0
SET DIRLOG=%DIRLOG%logs

SetLocal enabledelayedexpansion
	REM Значения по умолчанию
	IF [%SILENT%] EQU [] set SILENT=1
	IF [%ATTEMP%] EQU [] set ATTEMP=1
	REM Очищаем скрипты...
	IF EXIST "%DIRLOG%" RD /S /Q "%DIRLOG%"
	set ERROR_COUNT=1
	for /L %%A in (1,1,%ATTEMP%) do (
		set LAST_ERROR_COUNT=!SUCCESS! - !TOTAL!
		REM Проверка на кол-во ошибок после повтора.
		IF !ERROR_COUNT! NEQ !LAST_ERROR_COUNT! (
			call :RunExecute %%A
			set /A ERROR_COUNT=!SUCCESS! - !TOTAL!
		)
	)
( 
	EndLocal
	set FOLDER=%UPDATAPATH%
	set /A READY=%READY% + %SUCCESS%
	set /A AMOUNT=%AMOUNT% + %TOTAL%
)
GOTO :EOF
:RunExecute
	set /A SUCCESS=0
	set /A TOTAL=0
	REM Выполняем скрипты...
	for /R %UPDATAPATH% %%G in (*.sql) do call :RunScript %1 "%%G"
	IF %SUCCESS% NEQ %TOTAL% echo %time%:[%1] %Red%Total number does not match the number of successful%RESC%
	IF %SUCCESS% EQU %TOTAL% echo %time%:[%1] %Green%Total number corresponds to the number of successful%RESC%
	echo %time%: %Yellow%Count - %SUCCESS%/%TOTAL%%RESC%
GOTO :EOF
:RunScript
	IF NOT EXIST "%DIRLOG%" mkdir "%DIRLOG%"
	REM Получаем время в.
	set /a TM=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%%TIME:~9,2%	
	set /a TM=%TM: =0%
	REM Выполняем скрипт...
	sqlcmd -S %PROVIDER% -U %USERNAME% -P %PASSWORD% -d %NAMEBASE% -b -i %2 -r%SILENT% 1> NUL 2> "%DIRLOG%\%TM%_%~n2.log"
	REM Проверка на ошибку...
	IF !ERRORLEVEL! EQU 0 (
		echo %time%:[%1] [%Green%READY%RESC%] %2
		set /A SUCCESS=!SUCCESS!+1
	)
	IF !ERRORLEVEL! NEQ 0 (
		echo %time%:[%1] [%Red%ERROR%RESC%] %2
	)
	set /A TOTAL=!TOTAL!+1
GOTO :EOF
@echo off
REM call {this}.bat "{Provider}" "{Login}" "{Password}" {Silent} "{Timeout}"
REM {Provider} - Сервер базы.
REM {Login} - пользователь.
REM {Password} - пароль пользователя.
REM {Silent} - тихий режим(0 - off, 1 - on).
REM {Timeout} - время ожидания(секунды).
REM Example>call _reconnect.bat %~n0 "sa" "testSA" 0 "45"
REM Settings
SET PROVIDER=%1
SET USERNAME=%2
SET PASSWORD=%3
SET SILENT=%4
SET TIMEOUT=%5
REM Color for rows
SET ESC=
SET RESC=%ESC%[0m
SET Red=%ESC%[91m
SET Green=%ESC%[92m
SET Yellow=%ESC%[93m
SET Tooltip=%ESC%[90m

SetLocal EnableDelayedExpansion
	:Wait
	timeout /t %TIMEOUT%
	call :RunScript
EndLocal

GOTO :END
:RunScript
	echo %time%: [%Yellow%QUERY%RESC%] %PROVIDER% - Wait! Connection attempt...
	sqlcmd -S %PROVIDER% -U %USERNAME% -P %PASSWORD% -Q "print '%time%: [%Green%READY%RESC%] %PROVIDER% - Server responded: %Tooltip%Hehe, eee boy%RESC%';" -r%SILENT% > NUL
	IF !ERRORLEVEL! NEQ 0 (
		echo %time%: [%Red%ERROR%RESC%] %PROVIDER% - %Red%Connection failed%RESC%
		call :RunScript
	)
	IF !ERRORLEVEL! EQU 0 (
		echo %time%: [%Green%READY%RESC%] %PROVIDER% - %Green%Connection successful%RESC%
		call :Wait
	)
	GOTO :Wait
:END
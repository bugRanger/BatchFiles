@echo off
:: Поднимаемся на уровень выше.
cd..
:: Запускаем.
REM Color for rows
SET ESC=
SET RESC=%ESC%[0m
SET Red=%ESC%[91m
SET Green=%ESC%[92m

call _update.bat "D:\Projects\Project.SIM\SIMADATABASE\Create Scripts\" STUDENTPC\MSSQLSERVER14 "AltaiKrai" "sa" "1234" 0
call _update.bat "D:\Projects\Project.SIM\SIMADATABASE\Stored Procedures\" STUDENTPC\MSSQLSERVER14 "AltaiKrai" "sa" "1234" 0

IF %READY% NEQ %AMOUNT% echo %time%: %Red%Total number does not match the number of successful%RESC%
IF %READY% EQU %AMOUNT% echo %time%: %Green%Total number corresponds to the number of successful%RESC%
echo %time%: %Blue%Total count - %READY%/%AMOUNT%%RESC%

pause
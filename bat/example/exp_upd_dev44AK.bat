@echo off
:: Поднимаемся на уровень выше.
cd..
:: Запускаем.
call _update.bat "D:\Projects\Project.SIM\SIMADATABASE\Create Scripts\" STUDENTPC\MSSQLSERVER14 "AltaiKrai" "sa" "1234" 0 0
call _update.bat "D:\Projects\Project.SIM\SIMADATABASE\Stored Procedures\" STUDENTPC\MSSQLSERVER14 "AltaiKrai" "sa" "1234" 0 0

@echo off
:: Запускаем.
call ..\_updatedb.svn.bat "%~dp0" "%~n0" "192.168.70.26" "Dev223_Kemerovo" "sa" "testSA" "http://192.168.70.51/AIS/dev.v3/SIMADATABASE" 0 1
:: Информируем.
IF %READY% NEQ %AMOUNT% echo %time%: %Red%Total number does not match the number of successful%RESC%
IF %READY% EQU %AMOUNT% echo %time%: %Green%Total number corresponds to the number of successful%RESC%
echo %time%: %BCyan%Total count - %READY%/%AMOUNT%%RESC%
:: Ожидаем
IF [%1] EQU [] pause
@echo off
:: Поднимаемся на уровень выше.
cd..
:: Запускаем.
REM cd %Checkout%
REM svn checkout -r 1234 url://repository/path

SET LOGFILE_=%~dp0%~n0.log
REM call _updatedb.bat STUDENTPC\MSSQLSERVER14 AltaiKrai "sa" "1234" "D:\Temp\with space" "D:\Projects\Project.SIM\SIMADATABASE\" "" 0 1
call _updatedb.bat STUDENTPC\SQLEXPRESS AltaiKrai "sa" "1234" "D:\bases\2005" "D:\Projects\Project.SIM\SIMADATABASE\" "" 0 1
pause
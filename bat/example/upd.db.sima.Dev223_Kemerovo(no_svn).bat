@echo off
:: Settings
SET PROVIDER_=192.168.70.26
SET BASE_=Dev223_Kemerovo
SET USER_=sa
SET PASS_=testSA
SET PATH_=
SET REGION_=C0D896EE-89BE-4E79-8C80-1E0DE3948DC6
SET UPDATE_=D:\Projects\Project.SIM\SIMADATABASE\

SET LOGFILE_=%~dp0%~n0.log
SET LOGFILE_=%LOGFILE_:"=%
SET LOGFILE_="%LOGFILE_%"

:: Запускаем.
call ..\_updatedb.bat %PROVIDER_% %BASE_% "%USER_%" "%PASS_%" "%PATH_%" %REGION_% %UPDATE_% 0 2
:: Ожидаем
IF [%1] EQU [] pause

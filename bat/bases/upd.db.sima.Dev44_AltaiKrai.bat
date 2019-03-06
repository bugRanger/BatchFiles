@echo off
SET SKIP=%1
:: Запускаем.
call ..\_updatedb.svn.bat "%~dp0" "%~n0" "192.168.70.26" "Dev44_AltaiKrai" "sa" "testSA" "http://192.168.70.51/AIS/dev.v3/SIMADATABASE" 0 1
:: Ожидаем
IF [%SKIP%] EQU [] pause

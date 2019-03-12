@echo off
:: Запускаем.
call ..\_updatedb.svn.bat "%~dp0" "%~n0" "192.168.70.26" "Dev223_Kemerovo" "sa" "testSA" "http://192.168.70.51/AIS/dev.v3/SIMADATABASE" 0 1
:: Ожидаем
IF [%1] EQU [] pause

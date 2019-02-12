@echo off
:: Поднимаемся на уровень выше.
cd..
:: Запускаем.
REM call _reconnect.bat %~n0 "sa" "testSA" 0 "45"
call _reconnect.bat 192.168.70.26 "sa" "testSA" 0 "45"
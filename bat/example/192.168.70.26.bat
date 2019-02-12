@echo off
:: Поднимаемся на уровень выше.
cd..
:: Запускаем.
call _reconnect.bat %~n0 "sa" "testSA" 0 "45"
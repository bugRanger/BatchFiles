@echo off
:: Поднимаемся на уровень выше.
cd..
:: Запускаем.
call _reconnect.bat HUKUMKA\SQLEXPRESS "sa" "1234" 0 "45"
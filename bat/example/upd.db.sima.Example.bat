@echo off
:: Поднимаемся на уровень выше.
cd..
:: Запускаем.
REM cd %Checkout%
REM svn checkout -r 1234 url://repository/path
REM
call _updatedb.bat (localdb)\MSSQLLocalDB Example "" "" "" "D:\Projects\Project.SIM\SIMADATABASE\" 3BDFDCFF-63DA-4010-9CAF-3F46CCBBBF73 0 1
pause
@echo off
:: Поднимаемся на уровень выше.
cd..
:: Запускаем.
call _update.bat ".\sqlUpdate\" HUKUMKA\SQLEXPRESS "Example" "sa" "1234"
call _update.bat ".\sqlUpdate\" HUKUMKA\SQLEXPRESS "master" "sa" "1234"

IF %READY% NEQ %AMOUNT% echo %time%: %Red%Total number does not match the number of successful%RESC%
IF %READY% EQU %AMOUNT% echo %time%: %Green%Total number corresponds to the number of successful%RESC%
echo %time%: %Yellow%Total count - %READY%/%AMOUNT%%RESC%

timeout /t 45
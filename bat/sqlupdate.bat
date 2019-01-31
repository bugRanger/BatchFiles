@echo off
call _update.bat ".\sqlUpdate\" "HUKUMKA\SQLEXPRESS" "master" "sa" "1234" 0
timeout /t 45
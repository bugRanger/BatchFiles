@echo off

FOR /R "%~dp0" %%A IN (upd.db.sima.*.bat) DO IF [%%~nA] NEQ [%~n0] call "%%A" 1
pause
REM call %%A 1
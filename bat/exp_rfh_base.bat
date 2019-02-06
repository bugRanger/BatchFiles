@echo off

SET PROVIDER=(localdb)\MSSQLLocalDB
SET DATABASE=Example2
SET BASEFOLDER=D:\Temp\
SET UPDFOLDER=D:\Projects\Project.SIM\SIMADATABASE\
SET LOGIN=
SET PASSWORD=
SET LOGFOLDER=.\r.log
SET ATTEMP=2

	@echo %time%: Start %~n0%~x0 >> %LOGFOLDER%
	REM Создаем базу.
	call "%~dp0_recreate.bat" %PROVIDER% %DATABASE% "%LOGIN%" "%PASSWORD%" %BASEFOLDER% 0
	REM Пробное обновление(Накатываем все что не свалиться по региональному признаку или по ошибке).
	call "%~dp0_update.bat" "%UPDFOLDER%Queries\System\" %PROVIDER% %DATABASE% "%LOGIN%" "%PASSWORD%" 0 0
	call "%~dp0_update.bat" "%UPDFOLDER%Create Scripts\" %PROVIDER% %DATABASE% "%LOGIN%" "%PASSWORD%" 0 0 %LOGFOLDER%
	REM Устанавливаем региональный признак.
	REM call???
	REM Обновление базы с региональными настройками.
	for /L %%A in (1,1,%ATTEMP%) do (
		REM Выполняем обновление.
		call "%~dp0_update.bat" "%UPDFOLDER%_1\" %PROVIDER% %DATABASE% "%LOGIN%" "%PASSWORD%" 0 0 %LOGFOLDER%
		call "%~dp0_update.bat" "%UPDFOLDER%_2\" %PROVIDER% %DATABASE% "%LOGIN%" "%PASSWORD%" 0 0 %LOGFOLDER%
		REM Выводим результат выполнения.
		IF %READY% NEQ %AMOUNT% echo %time%: %Red%Total number does not match the number of successful%RESC%
		IF %READY% EQU %AMOUNT% echo %time%: %Green%Total number corresponds to the number of successful%RESC%
		echo %time%: %BCyan%Total count - %READY%/%AMOUNT%%RESC%
		REM В случае успеха выходим.
		IF %READY% EQU %AMOUNT% GOTO :RESULT
	)
:RESULT
	@echo %time%: Stop %~n0%~x0 >> %LOGFOLDER%
	timeout /t 15
GOTO :EOF
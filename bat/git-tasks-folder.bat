@echo off&Setlocal EnableDelayedExpansion
REM SET "DIR_OPTIONS=C:\ProgramData\SmartPTT"
REM SET "DIR_PROJECT=E:\Projects\smartptt\"
REM SET "DIR_TASKS=E:\Projects\Tasks\"
REM SET COPY_PROJECT_FILES= \.vs RadioService\bin\Debug\*.config 

SET "DIR_OPTIONS=%1"
SET "DIR_OPTIONS=%DIR_OPTIONS:"=%
SET "DIR_PROJECT=%2"
SET "DIR_PROJECT=%DIR_PROJECT:"=%
SET "DIR_TASKS=%3"
SET "DIR_TASKS=%DIR_TASKS:"=%
SET "COPY_PROJECT_FILES=%4"
SET "COPY_PROJECT_FILES=%COPY_PROJECT_FILES:"=%
:: Swap project catalog.
cd %DIR_PROJECT%
:: Find current branch.
SET "CURR_BRANCH="
SET "MARK_BRANCH=**"

for /f "delims=" %%A in ('git branch') do (
	set branch=%%A
	set branch=!branch:%MARK_BRANCH%=!
	IF ["!branch!"] NEQ ["%%A"] set CURR_BRANCH=%%A
)
IF ["%CURR_BRANCH%"] EQU [""] GOTO :END
set "DIR_TASK=%DIR_TASKS%%CURR_BRANCH:~2,255%\"
set "DIR_TASK=%DIR_TASK:/=\%"

SET "MODE=%5"
SET "MODE=%MODE:"=%
IF ["%MODE%"] EQU ["1"] GOTO :ENTER_BRANCH
:: ---------------------------------------------------------------------------------------
:: Event: Save branch
:: ---------------------------------------------------------------------------------------
:LEAVE_BRANCH
echo.Task switcher save...
:: Create new task dir.
IF NOT EXIST "%DIR_TASK%" mkdir "%DIR_TASK%" >NUL
:: Copy files.
rd /S /Q %DIR_TASK% >NUL 2>&1
xcopy "%DIR_OPTIONS%" "%DIR_TASK%SmartPTT" /C /Y /R /S /I /Q >NUL

for %%A in (%COPY_PROJECT_FILES%) do (
	for /f %%i in ("%DIR_PROJECT%%%A") do (
		set file=%%~dpnxi
		set file=!file:%DIR_PROJECT%=!
		set file=%DIR_TASK%!file!
		set folder=%%~dpi
		set folder=!folder:%DIR_PROJECT%=!
		set folder=%DIR_TASK%!folder!
		set folder=!folder:\\=\!

		set isfolder=%%A
		set isfolder=!isfolder:~0,1!

		IF ["!isfolder!"] EQU ["\"] xcopy "%%i" "!file!" /C /Y /R /S /I /Q /H >NUL
		IF ["!isfolder!"] NEQ ["\"] (
			IF NOT EXIST "!folder!" mkdir !folder!
			copy "%%i" "!file!" /Y >NUL
		)
	)
)
GOTO :END
:: ---------------------------------------------------------------------------------------
:: Event: Load branch
:: ---------------------------------------------------------------------------------------
:ENTER_BRANCH
echo.Task switcher load...
IF NOT EXIST %DIR_TASK% (
	echo.Not found task folder
	GOTO :END
)
cd %DIR_TASK%
:: Copy files.
xcopy "%DIR_TASK%SmartPTT" "%DIR_OPTIONS%" /C /Y /R /S /I /Q >NUL
SetLocal EnableDelayedExpansion
for %%A in (%COPY_PROJECT_FILES%) do (
	set file=%DIR_PROJECT%%%A
	set file=!file:\\=\!
	
	set isfolder=%%A
	set isfolder=!isfolder:~0,1!
	
	IF ["!isfolder!"] EQU ["\"] xcopy "%DIR_TASK%%%A" "!file!" /C /Y /R /S /I /Q >NUL
	IF ["!isfolder!"] NEQ ["\"] copy "%DIR_TASK%%%A" "!file!" /Y >NUL
)
GOTO :END
:: ---------------------------------------------------------------------------------------
:: The end.
:: ---------------------------------------------------------------------------------------
:END
echo.Task switcher ended.
REM pause
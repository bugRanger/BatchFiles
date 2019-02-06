@echo off 
setlocal enableextensions disabledelayedexpansion
REM Получаем параметры для запуска
set "FILEPATH=%~1"
set "FILENAME=%~2"
set "SAVENAME=%~3"
set "search=%~4"
set "replace=%~5"
REM Создаем копию файла
copy /Y "%FILEPATH%%FILENAME%" "%FILEPATH%%SAVENAME%" > NUL
REM Выполняем поиск и замену...
for /f "delims=" %%i in ('type "%FILEPATH%%SAVENAME%" ^& break ^> "%FILEPATH%%SAVENAME%" ') do (
	set "line=%%i"
	setlocal enabledelayedexpansion
	>>"%FILEPATH%%SAVENAME%" echo(!line:%search%=%replace%!
	endlocal
)
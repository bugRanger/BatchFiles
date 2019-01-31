@echo off
REM Example: call "C:\..\{this}.bat" "C:\..\{CatalogWithSqlFiles}\" "{Server}" "{BaseName}" "{login}" "{password}" "{BasePath(use_only_for_recreate)}"
REM {this} - имя текущего исполняемого файла.
REM {CatalogWithSqlFiles} - Каталог хранения файлов для обновления.
REM {Server} - сервер (имя/адрес)
REM {BaseName} - наименование базы данных.
REM {login} - пользователь.
REM {password} - пароль пользователя.
REM {BasePath(use_only_for_recreate)} - путь до место хранения базы, как файла локально. 
REM ВНИМАНИЕ! Этот параметр используется для принудительного пересоздания базы данных.

REM Указываем выполнение с задержкой, т.к. у нас есть подсчет в цикле итераций (иначе подсчет не будет корректно выполняться).
setlocal enabledelayedexpansion
setlocal enableextensions 
set UPDATAPATH=%1
set PROVIDER=%2
set NAMEBASE=%3
set USERNAME=%4
set PASSWORD=%5
set PATHBASE=%6
set MAKEPATH=make\
set DIRMAKE=__make\
set DIRUPDATE=__update\
set DIRCONTENT=__content\
REM Директория...
cd /d %~dp0
REM Очищаем скрипты...
RD /S /Q %DIRMAKE%
RD /S /Q %DIRUPDATE%
RD /S /Q %DIRCONTENT%

REM Проверка пути к базе данных как флага для выполнения пересоздания...
IF NOT EXIST "%PATHBASE%%NAMEBASE%*.mdf" (
IF NOT EXIST "%PATHBASE%" GOTO SkipRecreate)
REM Подготавливаем скрипты...
call %MAKEPATH%replace.bat %MAKEPATH% "detach.sql" "_detach.sql" "NAME_BASE" %NAMEBASE%
call %MAKEPATH%replace.bat %MAKEPATH% "drop.sql" "_drop.sql" "NAME_BASE" %NAMEBASE%
call %MAKEPATH%replace.bat %MAKEPATH% "make.sql" "__make.sql" "NAME_BASE" %NAMEBASE%
call %MAKEPATH%replace.bat %MAKEPATH% "__make.sql" "_make.sql" "PATH_BASE" %PATHBASE%
REM Подготавливаем скрипты для наполнения...
del "%MAKEPATH%__*.sql"
xcopy %MAKEPATH%_*.sql %DIRMAKE% /Y /C /R /S /I /Q
del "%MAKEPATH%_*.sql"
xcopy %UPDATAPATH%%MAKEPATH%*.sql %DIRCONTENT% /Y /C /R /S /I /Q
REM Извлекаем базу данных...
sqlcmd -S %PROVIDER% -U %USERNAME% -P %PASSWORD% -i %DIRMAKE%_drop.sql
REM Удаляем базу данных...
del %PATHBASE%%NAMEBASE%*.mdf
del %PATHBASE%%NAMEBASE%*.ldf
REM Создаем базу данных...
sqlcmd -S %PROVIDER% -U %USERNAME% -P %PASSWORD% -i %DIRMAKE%_make.sql
REM Перегружаем базу данных...
for /R %DIRCONTENT% %%G in (*.sql) do sqlcmd -S %PROVIDER% -U %USERNAME% -P %PASSWORD% -d %NAMEBASE% -i "%%G"
:SkipRecreate

REM Подготавливаем скрипты...
xcopy %UPDATAPATH%*.sql %DIRUPDATE% /Y /C /R /S /I /Q
REM Удаляем лишние из скопированного.
RD /S /Q %DIRUPDATE%%MAKEPATH%

REM Заполняем базу данных...
for /R %DIRUPDATE% %%G in (*.sql) do call :RunScript "%%G"
REM Повторные вызовы для ошибок...
for /R %DIRUPDATE% %%G in (*.err) do sqlcmd -S %PROVIDER% -U %USERNAME% -P %PASSWORD% -d %NAMEBASE% -i "%%G"
REM Проверка пути к базе данных как флага для выполнения открепления...
IF NOT EXIST "%PATHBASE%%NAMEBASE%*.mdf" (
IF NOT EXIST "%PATHBASE%" GOTO SkipDetach)
REM Открепляем базу данных...
sqlcmd -S %PROVIDER% -U %USERNAME% -P %PASSWORD% -i %DIRMAKE%_detach.sql
:SkipDetach
REM Очищаем скрипты...
RD /S /Q %DIRCONTENT%
RD /S /Q %DIRUPDATE%
RD /S /Q %DIRMAKE%
REM Директория...
cd /d %cd%
pause

GOTO :END
:RunScript
	sqlcmd -S %PROVIDER% -U %USERNAME% -P %PASSWORD% -d %NAMEBASE% -b -i %1
	IF "%ERRORLEVEL%"=="1" (
		copy /Y %1 "%~dp1\%~n1.err")
:END
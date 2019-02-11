@echo off
REM Example: call {This}.bat "{DB_PROVIDER}" "{DB_NAME}" "{DB_USER}" "{DB_PASS}" "{DB_PATH}" {Silent} {LogFile}
REM 1. {DB_PROVIDER} - ������ (���/�����)
REM 2. {DB_NAME} - ������������ ���� ������.
REM 3. {DB_USER} - ������������.
REM 4. {DB_PASS} - ������ ������������.
REM 5. {DB_PATH} - ���� �� ����� �������� ����, ��� ����� ��������. ��������! ���� �������� ������������ ��� ��������������� ������������ ���� ������.
REM 6. {Silent} - ����� �����(0 - off, 1 - on. off �� ���������).
REM 7. {LogFile} - ���� ��� ����� ����������� ����������.
REM Example>call _recreate.bat "192.168.70.26" "Dev44_Atlan" "sa" "testSA" "C:\Temp" 1 ".\result.log"

REM +   Add                set /a "_num=_num+5"
REM +=  Add variable       set /a "_num+=5"
REM -   Subtract (or unary)set /a "_num=_num-5"
REM -=  Subtract variable  set /a "_num-=5"
REM *   Multiply           set /a "_num=_num*5"
REM *=  Multiply variable  set /a "_num*=5"
REM /   Divide             set /a "_num=_num/5"
REM /=  Divide variable    set /a "_num/=5"
REM %   Modulus            set /a "_num=5%%2"
REM %%= Modulus            set /a "_num%%=5" 
REM !   Logical negation  0 (FALSE) ? 1 (TRUE) and any non-zero value (TRUE) ? 0 (FALSE)
REM ~   One's complement (bitwise negation) 
REM &   AND                set /a "_num=5&3"    0101 AND 0011 = 0001 (decimal 1)
REM &=  AND variable       set /a "_num&=3"
REM |   OR                 set /a "_num=5|3"    0101 OR 0011 = 0111 (decimal 7)
REM |=  OR variable        set /a "_num|=3"
REM ^   XOR                set /a "_num=5^3"    0101 XOR 0011 = 0110 (decimal 6)
REM ^=  XOR variable       set /a "_num=^3"
REM <<  Left Shift.    (sign bit ? 0)
REM >>  Right Shift.   (Fills in the sign bit such that a negative number always remains negative.)
REM Neither ShiftRight nor ShiftLeft will detect overflow.
REM <<= Left Shift variable     set /a "_num<<=2"
REM >>= Right Shift variable    set /a "_num>>=2"

REM ( )  Parenthesis group expressions  set /a "_num=(2+3)*5"
REM ,   Commas separate expressions    set /a "_num=2,_result=_num*5"


REM EQU - equal
REM NEQ - not equal
REM LSS - less than
REM LEQ - less than or equal
REM GTR - greater than
REM GEQ - greater than or equal

SET DB_PROVIDER=%1
SET DB_NAME=%2
SET DB_USER=%3
SET DB_PASS=%4
SET DB_PATH=%5
SET SILENT=%6
SET LOGFILE=%7
REM Color for rows
SET ESC=
SET RESC=%ESC%[0m
SET Red=%ESC%[91m
SET Cyan=%ESC%[36m
SET BCyan=%ESC%[96m
SET Green=%ESC%[92m
SET Yellow=%ESC%[93m
SET Tooltip=%ESC%[90m

SET MAKEPATH=.\_recreate\
SET DIRMAKE=.\__recreate\
SET DIRLOG=%~dp0
SET DIRLOG=%DIRLOG%logs

REM ��������� ���������� � ���������, �.�. � ��� ���� ������� � ����� �������� (����� ������� �� ����� ��������� �����������).
SetLocal EnableDelayedExpansion
	REM �������� �� ���������
	IF [%SILENT%] EQU [] set SILENT=1
	IF [%DB_PATH%] EQU [] set DB_PATH=""
	
	REM ����������...
	cd /d %~dp0
	REM ������� �������...
	rd /S /Q %DIRMAKE% >NUL 2>&1

	REM �������� ���� � ���� ������ ��� ����� ��� ���������� ������������...
	REM IF NOT EXIST "%DB_PATH%%DB_NAME%*.mdf" (
	REM IF NOT EXIST "%DB_PATH%" GOTO SkipRecreate)
	REM �������������� �������...
	call %MAKEPATH%replace.bat %MAKEPATH% "detach.sql" "_detach.sql" "NAME_BASE" %DB_NAME%
	call %MAKEPATH%replace.bat %MAKEPATH% "drop.sql" "_drop.sql" "NAME_BASE" %DB_NAME%
	call %MAKEPATH%replace.bat %MAKEPATH% "make.sql" "__make.sql" "NAME_BASE" %DB_NAME%
	call %MAKEPATH%replace.bat %MAKEPATH% "__make.sql" "_make.sql" "PATH_BASE" %DB_PATH%
	REM �������������� ������� ��� ����������...
	del "%MAKEPATH%__*.sql" >NUL 2>&1
	xcopy %MAKEPATH%_*.sql %DIRMAKE% /Y /C /R /S /I /Q >NUL
	del "%MAKEPATH%_*.sql" >NUL 2>&1
	REM ��������� ���� ������...
	REM call :RunScript 0 "%DIRMAKE%_detach.sql" "Detach base - %DB_NAME%"
	call :RunScript 1 "%DIRMAKE%_drop.sql" "Drop base - %DB_NAME%"
	REM ������� ���� ������...
	REM del %DB_PATH%%DB_NAME%*.mdf >NUL 2>&1
	REM del %DB_PATH%%DB_NAME%*.ldf >NUL 2>&1
	REM ������� ���� ������...
	call :RunScript 1 "%DIRMAKE%_make.sql" "Create base - %DB_NAME%"
:SkipRecreate
	REM ������� �������...
	rd /S /Q %DIRMAKE% >NUL 2>&1 
	REM ����������...
	cd /d %cd%
( 
	EndLocal
	set /A READY=%READY% + %SUCCESS%
	set /A AMOUNT=%AMOUNT% + %TOTAL%
)
GOTO :EOF
:RunScript
	IF NOT EXIST %2 GOTO :EOF
	IF NOT EXIST "%DIRLOG%" mkdir "%DIRLOG%"
	REM �������� ����� ��� ������������ ����.
	set /a TM=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%%TIME:~9,2%
	set /a TM=%TM: =0%
	REM �������� ������������ ��� ��������, �������(quotes) ������ �� �������.
	set ACT=%3
	set ACT=%ACT:"=%
	REM ��������� ������� ������ ����.
	IF [%LOGFILE%] EQU [] set LOG="%DIRLOG%\%TM%_%~n2.log"
	IF [%LOGFILE%] NEQ [] set LOG=%LOGFILE%
	REM ����� � ������� � � ���.
	IF [%SILENT%] EQU [0] (
		echo %time%:[%1] [%Yellow%QUERY%RESC%] ^> %ACT%
		@echo %time%:[%1] [QUERY] ^> %ACT%>>%LOG%
	)
	REM ��������� ������...
	sqlcmd -S %DB_PROVIDER% -U %DB_USER% -P %DB_PASS% -b -i %2 -r0 1> NUL 2>>!LOG!
	set /A TOTAL=!TOTAL!+1
	REM �������� �� ������...
	IF !ERRORLEVEL! EQU 0 (
		IF [%SILENT%] LSS [3] echo %time%:[%1] [%Green%READY%RESC%] ^< %ACT%
		@echo %time%:[%1] [READY] ^< %ACT%>>%LOG%
		set /A SUCCESS=!SUCCESS!+1
	)
	IF !ERRORLEVEL! NEQ 0 (
		IF [%SILENT%] LSS [3] echo %time%:[%1] [%Red%ERROR%RESC%] ^< %ACT%
		@echo %time%:[%1] [ERROR] ^< %ACT% ^(%2^)>>%LOG%
		REM ����� ������� � ����� � ������� � ������.
		IF [!TRASH!] NEQ [] (
			@echo %2>>!TRASH!
		)
	)
GOTO :EOF
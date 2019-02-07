@echo off

	set TRASH=.\trash.txt
	del %TRASH% >NUL 2>&1
	
	call _update.bat ".\_update\" table.sql (localdb)\MSSQLLocalDB "master" "" "" 0 1 ".\r.log"
	call _update.bat ".\_update\" *.sql (localdb)\MSSQLLocalDB "master" "" "" 0 3 ".\r.log"

	IF %READY% NEQ %AMOUNT% echo %time%: %Red%Total number does not match the number of successful%RESC%
	IF %READY% EQU %AMOUNT% echo %time%: %Green%Total number corresponds to the number of successful%RESC%
	echo %time%: %BCyan%Total count - %READY%/%AMOUNT%%RESC%

timeout /t 45
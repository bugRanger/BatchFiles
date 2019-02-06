@echo off

	call "%~dp0_recreate.bat" (localdb)\MSSQLLocalDB "Example" "" "" "D:\Temp\" 0

timeout /t 45
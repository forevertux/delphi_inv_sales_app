@echo off
setlocal
cd /d "%~dp0.."
if exist "Win32\Debug\data\inventory.db" (
  del /q "Win32\Debug\data\inventory.db"
  echo Deleted Win32\Debug\data\inventory.db
) else if exist "data\inventory.db" (
  del /q "data\inventory.db"
  echo Deleted data\inventory.db
) else (
  echo No inventory.db found under Win32\Debug\data or data\
)
echo.
echo Copy the database folder to Win32\Debug if needed, then start the app.
pause

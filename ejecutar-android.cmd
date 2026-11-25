@echo off
powershell.exe -NoLogo -NoProfile -ExecutionPolicy RemoteSigned -File "%~dp0ejecutar-android.ps1" %*
exit /b %errorlevel%

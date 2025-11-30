@echo off
echo ========================================
echo EatEase - Add Firewall Rule for Flask
echo ========================================
echo.
echo This script will add a Windows Firewall rule to allow
echo incoming connections to Flask on port 5000
echo.

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script must be run as Administrator!
    echo.
    echo Right-click on this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo Adding firewall rule...
echo.

netsh advfirewall firewall add rule name="Flask Dev Server - EatEase" dir=in action=allow protocol=TCP localport=5000 profile=private

if %errorLevel% equ 0 (
    echo.
    echo SUCCESS! Firewall rule added successfully.
    echo.
    echo Port 5000 is now open for incoming connections on Private networks.
    echo Your phone should now be able to connect to the backend server.
    echo.
    echo Backend URL: http://192.168.0.101:5000
    echo.
) else (
    echo.
    echo ERROR: Failed to add firewall rule.
    echo Error code: %errorLevel%
    echo.
)

pause

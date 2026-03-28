@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Check if the script is running as Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Please run this script as Administrator.
    pause
    exit /b
)

:: List all available drives (C:, D:, E:, etc.)
echo Fetching drive list...
echo --------------------------------------------------
set counter=1
for /f "tokens=1" %%a in ('wmic logicaldisk get name ^| findstr ":"') do (
    set "rawDrive=%%a"
    set "drive[!counter!]=!rawDrive:~0,2!"
    echo !counter!. !rawDrive:~0,2!
    set /a counter+=1
)
echo --------------------------------------------------

:: Prompt user to choose a drive from the list
set /p driveChoice=Enter the number of the drive you want to use (1, 2, 3, etc.): 

:: Check if the user input is valid
set "driveLetter=!drive[%driveChoice%]!"
if "%driveLetter%"=="" (
    echo [ERROR] Invalid choice. Exiting...
    pause
    exit /b
)

set "folderPath=%driveLetter%"

:: Restart the Server service to ensure environment consistency
echo Checking and restarting SMB services...
net stop "lanmanserver" /y >nul 2>&1
net start "lanmanserver" >nul 2>&1

echo.
:: Prompt the user to enter the name for the shared folder
set /p shareName=Enter a name for the shared folder (e.g., Shared_Folder): 

set "fullPath=%folderPath%\%shareName%"

:: 1. Create the folder (if it doesn't exist)
if not exist "%fullPath%" (
    echo Creating folder: "%fullPath%"...
    mkdir "%fullPath%"
)

:: 2. Set NTFS permissions (Everyone: Full Control)
:: (OI) - Object Inherit (files)
:: (CI) - Container Inherit (subfolders)
:: F - Full Control
echo Setting NTFS disk permissions (Everyone: Full Control)...
icacls "%fullPath%" /grant Everyone:(OI)(CI)F /t /q

:: 3. Create the network share
echo Enabling network share (Everyone: Full Control)...
net share "%shareName%"="%fullPath%" /GRANT:everyone,FULL /REMARK:"Auto-shared by Script"

:: Validation and Results
echo.
echo --------------------------------------------------
if %errorlevel% equ 0 (
    echo SUCCESS: The folder has been shared successfully.
    echo Local Path:  %fullPath%
    echo Network Path: \\%COMPUTERNAME%\%shareName%
    echo Permissions: Everyone has been granted Read/Write/Modify access.
) else (
    echo [ERROR] Sharing failed. Please check if the share name is already in use.
)
echo --------------------------------------------------

pause
ENDLOCAL

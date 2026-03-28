@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: Check if the script is running as Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Please run this script as Administrator.
    pause
    exit /b
)

:: List all available drives (C, D, E, etc.)
echo Available drives:
wmic logicaldisk get name

:: Create a list for available drives
set counter=1
for /f "skip=1 tokens=1" %%a in ('wmic logicaldisk get name') do (
    set drive[%counter%]=%%a
    echo !counter!. %%a
    set /a counter+=1
)

:: Prompt user to choose a drive from the list
set /p driveChoice=Enter the number of the drive you want to share (1, 2, 3, etc.): 

:: Check if the user input is valid
set driveLetter=!drive[%driveChoice%]!
if "%driveLetter%"=="" (
    echo Invalid choice. Exiting...
    pause
    exit /b
)

:: Construct the full path to the selected drive
set folderPath=%driveLetter%\

:: Check if the selected drive exists
if not exist "%folderPath%" (
    echo Error: The specified path does not exist: %folderPath%
    pause
    exit /b
)

:: Enable SMB protocol (SMB1 and SMB2 for compatibility)
echo Enabling SMB protocol...
dism /online /enable-feature /featurename:FS-SMB1 /all /norestart
dism /online /enable-feature /featurename:FS-SMB2 /all /norestart
net stop "lanmanserver"
net start "lanmanserver"

:: Prompt the user to enter the name for the shared folder
echo Please enter a name for the shared folder (e.g., "Shared_Folder"):
set /p shareName=Share Name: 

:: Create the shared folder (if it doesn't exist)
if not exist "%folderPath%\%shareName%" (
    echo Folder "%shareName%" does not exist. Creating it...
    mkdir "%folderPath%\%shareName%"
)

:: Create the network share with the specified folder path and name
echo Sharing the folder...
net share "%shareName%"="%folderPath%\%shareName%" /GRANT:everyone,FULL

:: Confirmation that the folder has been shared
echo Finished! The folder "%folderPath%\%shareName%" is now shared as "%shareName%".
pause
ENDLOCAL

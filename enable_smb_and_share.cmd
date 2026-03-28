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

:: [修复 1] 使用 findstr 过滤空行，并截取前两位消除不可见的回车符
set counter=1
for /f "tokens=1" %%a in ('wmic logicaldisk get name ^| findstr ":"') do (
    set "rawDrive=%%a"
    set "drive[!counter!]=!rawDrive:~0,2!"
    echo !counter!. !rawDrive:~0,2!
    set /a counter+=1
)

:: Prompt user to choose a drive from the list
set /p driveChoice=Enter the number of the drive you want to share (1, 2, 3, etc.): 

:: Check if the user input is valid
set "driveLetter=!drive[%driveChoice%]!"
if "%driveLetter%"=="" (
    echo Invalid choice. Exiting...
    pause
    exit /b
)

:: [修复 2] 移除末尾的斜杠，防止后续拼接出现双斜杠 (如 C:\\)
set "folderPath=%driveLetter%"

:: Check if the selected drive exists (Check the root directory)
if not exist "%folderPath%\" (
    echo Error: The specified drive does not exist: %folderPath%
    pause
    exit /b
)

:: [修复 3 & 4] 移除了危险的 SMB1 和无效的 SMB2 DISM 命令，并为 net stop 添加 /y 防止脚本卡住
echo Restarting SMB Service to apply potential state changes...
net stop "lanmanserver" /y >nul 2>&1
net start "lanmanserver" >nul 2>&1

:: Prompt the user to enter the name for the shared folder
echo Please enter a name for the shared folder (e.g., Shared_Folder):
set /p shareName=Share Name: 

:: Create the shared folder (if it doesn't exist)
if not exist "%folderPath%\%shareName%" (
    echo Folder "%shareName%" does not exist. Creating it...
    mkdir "%folderPath%\%shareName%"
)

:: Create the network share with the specified folder path and name
:: 使用标准的 "共享名=绝对路径" 格式
echo Sharing the folder...
net share "%shareName%=%folderPath%\%shareName%" /GRANT:everyone,FULL

:: Confirmation that the folder has been shared
if %errorlevel% equ 0 (
    echo Finished! The folder "%folderPath%\%shareName%" is now shared as "%shareName%".
) else (
    echo Failed to share the folder. Please check your system settings.
)

pause
ENDLOCAL

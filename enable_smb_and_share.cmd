@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] 请以管理员身份运行此脚本。
    pause
    exit /b
)

:: 列出可用磁盘
echo 正在获取磁盘列表...
echo --------------------------------------------------
set counter=1
for /f "tokens=1" %%a in ('wmic logicaldisk get name ^| findstr ":"') do (
    set "rawDrive=%%a"
    set "drive[!counter!]=!rawDrive:~0,2!"
    echo !counter!. !rawDrive:~0,2!
    set /a counter+=1
)
echo --------------------------------------------------

:: 选择磁盘
set /p driveChoice=请输入要共享的磁盘编号 (1, 2, 3...): 

set "driveLetter=!drive[%driveChoice%]!"
if "%driveLetter%"=="" (
    echo [ERROR] 选择无效，脚本退出。
    pause
    exit /b
)

set "folderPath=%driveLetter%"

:: 重启 Server 服务 (可选，确保环境干净)
echo 正在检查并重启共享服务...
net stop "lanmanserver" /y >nul 2>&1
net start "lanmanserver" >nul 2>&1

:: 设置共享名
echo.
set /p shareName=请输入共享文件夹名称 (例如: SharedFiles): 

set "fullPath=%folderPath%\%shareName%"

:: 1. 创建文件夹
if not exist "%fullPath%" (
    echo 正在创建文件夹: "%fullPath%"...
    mkdir "%fullPath%"
)

:: 2. 设置 NTFS 权限 (关键步骤)
:: /grant Everyone:(OI)(CI)F 表示：
:: (OI) - 对象继承 (文件)
:: (CI) - 容器继承 (子文件夹)
:: F - 完全控制 (Full Control)
echo 正在设置 NTFS 磁盘权限 (Everyone: 完全控制)...
icacls "%fullPath%" /grant Everyone:(OI)(CI)F /t /q

:: 3. 创建网络共享
echo 正在开启网络共享 (Everyone: 完全控制)...
net share "%shareName%"="%fullPath%" /GRANT:everyone,FULL /REMARK:"Auto-shared by Script"

:: 验证结果
echo.
echo --------------------------------------------------
if %errorlevel% equ 0 (
    echo 恭喜！共享设置成功。
    echo 本地路径: %fullPath%
    echo 网络路径: \\%COMPUTERNAME%\%shareName%
    echo 权限状态: Everyone 已获得读取/写入/修改权限。
) else (
    echo [ERROR] 共享失败，请检查该名称是否已被占用。
)
echo --------------------------------------------------

pause
ENDLOCAL

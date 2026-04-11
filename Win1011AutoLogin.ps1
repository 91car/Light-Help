# 检查管理员权限，如果没有则自动申请
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 1. Input Section
$User = Read-Host "Input Username"
$Pass = Read-Host "Input Password" -AsSecureString
$PassPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Pass))

# 2. Fix Win10/11 Hello Limit
$LessPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\PasswordLess\Device"
Set-ItemProperty -Path $LessPath -Name "DevicePasswordLessBuildVersion" -Value 0

# 3. Set Auto Login
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$Config = @{
    "AutoAdminLogon"  = "1"
    "DefaultUserName" = $User
    "DefaultPassword" = $PassPlain
    "AutoLogonCount"  = 0
}

foreach ($Key in $Config.Keys) {
    Set-ItemProperty -Path $RegPath -Name $Key -Value $Config[$Key]
}

Write-Host "Settings applied successfully! Please restart." -ForegroundColor Green
Pause
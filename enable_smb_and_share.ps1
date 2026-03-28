# 1. 启用SMB功能
Enable-WindowsOptionalFeature -Online -FeatureName smb1protocol -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName FS-SMB1 -All -NoRestart
Start-Service -Name "LanmanServer"

# 2. 创建一个名为iphone的共享文件夹
$folderPath = "C:\iphone"  # 你可以修改文件夹路径
if (-not (Test-Path -Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory
}

# 3. 设置共享文件夹
$shareName = "iphone"  # 共享名
New-SmbShare -Name $shareName -Path $folderPath -FullAccess "Everyone"

# 4. 设置共享权限
$acl = Get-Acl -Path $folderPath
$permission = "Everyone","FullControl","Allow"
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($permission[0], $permission[1], "ContainerInherit, ObjectInherit", "None", "Allow")
$acl.AddAccessRule($rule)
Set-Acl -Path $folderPath -AclObject $acl

Write-Host "SMB已启用，'iphone' 文件夹已共享！"

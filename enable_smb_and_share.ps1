$ErrorActionPreference = "Stop"

# Enable TLSv1.2 for compatibility with older clients
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# 提示用户输入共享文件夹路径
$folderPath = Read-Host "请输入要共享的文件夹路径（例如：C:\Users\YourUser\Documents\iphone）"

# 验证路径是否存在
if (-not (Test-Path $folderPath)) {
    Write-Host "错误：指定的路径不存在！"
    exit
}

# 随机生成文件名
$rand = Get-Random -Maximum 99999999

# 检查管理员权限
$isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')

# 设置临时文件路径
$FilePath = if ($isAdmin) { "$env:SystemRoot\Temp\SMB_Share_$rand.cmd" } else { "$env:TEMP\SMB_Share_$rand.cmd" }

# 下载批处理脚本
$DownloadURL = 'https://raw.githubusercontent.com/yourusername/yourrepository/main/enable_smb_and_share.cmd'

try {
    $response = Invoke-WebRequest -Uri $DownloadURL -UseBasicParsing
}
catch {
    Write-Host "下载失败，检查 URL 或网络连接"
    exit
}

# 将文件夹路径替换到 CMD 脚本内容中
$content = $response.Content -replace "{FOLDER_PATH}", $folderPath

# 创建临时 .CMD 文件
Set-Content -Path $FilePath -Value $content

# 执行 .CMD 文件
Start-Process $FilePath -Wait

# 删除临时文件
Remove-Item $FilePath -Force

Write-Host "SMB 和共享设置已成功完成！"

$ErrorActionPreference = "Stop"

$backup1 = "E:\Ubuntu-backup.tar"
$backup2 = "E:\StarlinTirkey\Ubuntu-backup.tar"

Write-Host "Checking Ubuntu..." -ForegroundColor Cyan
wsl -l -v

Write-Host "Shutting down WSL..." -ForegroundColor Cyan
wsl --shutdown

Start-Sleep -Seconds 2

Write-Host "Testing Ubuntu launch..." -ForegroundColor Cyan
wsl -d Ubuntu -- echo "Ubuntu launch test successful"

Write-Host "Exporting Ubuntu backup..." -ForegroundColor Cyan
wsl --export Ubuntu $backup1

Write-Host "Copying backup into StarlinTirkey..." -ForegroundColor Cyan
Copy-Item $backup1 $backup2 -Force

Write-Host "Verifying backups..." -ForegroundColor Cyan
if ((Test-Path $backup1) -and (Test-Path $backup2)) {
    Write-Host "Backup completed successfully." -ForegroundColor Green
} else {
    throw "Backup verification failed."
}

$ErrorActionPreference = "Stop"
Write-Host "Creating C:\src directory..."
If (!(Test-Path -Path "C:\src")) {
    New-Item -ItemType Directory -Force -Path "C:\src"
}

Write-Host "Downloading Flutter SDK (This might take a few minutes)..."
Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.3-stable.zip" -OutFile "C:\src\flutter.zip"

Write-Host "Extracting Flutter SDK..."
Expand-Archive -Path "C:\src\flutter.zip" -DestinationPath "C:\src" -Force

Write-Host "Cleaning up zip file..."
Remove-Item -Path "C:\src\flutter.zip" -Force

Write-Host "Adding Flutter to User Path..."
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
If ($userPath -notmatch "C:\\src\\flutter\\bin") {
    $newPath = $userPath + ";C:\src\flutter\bin"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
}

Write-Host "Flutter Installation Complete!"

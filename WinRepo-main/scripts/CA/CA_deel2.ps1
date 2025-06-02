# Install IIS Web Server
Write-Host "Installing IIS Web Server..." -ForegroundColor Cyan

try {
    Install-WindowsFeature Web-Server -IncludeManagementTools -ErrorAction Stop
    Write-Host "IIS Web Server installed successfully." -ForegroundColor Green
} catch {
    Write-Host "Error installing IIS Web Server: $_" -ForegroundColor Red
    exit 1
}

# Install Web Enrollment Service
Write-Host "Installing Certificate Authority Web Enrollment feature..." -ForegroundColor Cyan

try {
    Install-WindowsFeature ADCS-Web-Enrollment -IncludeManagementTools -ErrorAction Stop
    Write-Host "Certificate Authority Web Enrollment feature installed successfully." -ForegroundColor Green
} catch {
    Write-Host "Error installing Web Enrollment feature: $_" -ForegroundColor Red
    exit 1
}

# Configure Web Enrollment Service
Write-Host "Configuring Certificate Authority Web Enrollment..." -ForegroundColor Cyan

try {
    Install-AdcsWebEnrollment -Force -ErrorAction Stop
    Write-Host "Certificate Authority Web Enrollment configured successfully." -ForegroundColor Green
} catch {
    Write-Host "Error configuring Web Enrollment: $_" -ForegroundColor Red
    exit 1
}
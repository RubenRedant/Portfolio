# Step X: Install Active Directory Certificate Services Role
Write-Host "Installing AD CS Certification Authority..." -ForegroundColor Cyan

try {
    Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools -ErrorAction Stop
    Write-Host "AD CS Certification Authority role installed successfully." -ForegroundColor Green
} catch {
    Write-Host "Error installing AD CS Certification Authority role: $_" -ForegroundColor Red
    exit 1
}

# Step X+1: Configure Certification Authority
Write-Host "Configuring Certification Authority..." -ForegroundColor Cyan

try {
    Install-AdcsCertificationAuthority `
        -CAType EnterpriseRootCA `
        -CryptoProviderName "RSA#Microsoft Software Key Storage Provider" `
        -HashAlgorithm SHA256 `
        -KeyLength 2048 `
        -ValidityPeriod Years `
        -ValidityPeriodUnits 5 `
        -CACommonName "$($env:COMPUTERNAME)-CA" `
        -Force -ErrorAction Stop
    Write-Host "Certification Authority configured successfully." -ForegroundColor Green
} catch {
    Write-Host "Error configuring Certification Authority: $_" -ForegroundColor Red
    exit 1
}

# Restart the server to complete CA installation
Write-Host "Restarting the server to complete CA installation..." -ForegroundColor Cyan
Restart-Computer -Force
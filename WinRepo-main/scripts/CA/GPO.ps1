# Define variables
$caName = "WS2-2425-RubenCA" # Replace with the correct CA name
$certPath = "C:\Temp\RootCA.cer"
$gpoName = "Trusted Root Certification Authorities"
$domainDN = "DC=WS2-2425-ruben,DC=hogent" # Replace with your domain's Distinguished Name

# Function to create and configure GPO for Distributing Root CA Certificate
function Configure-RootCAGPO {
    param (
        [string]$GPOName,
        [string]$DomainDN,
        [string]$CertPath
    )
    
    try {
        # Import GroupPolicy module
        Import-Module GroupPolicy -ErrorAction Stop
        
        # Create a new GPO
        $gpo = New-GPO -Name $GPOName -ErrorAction Stop
        Write-Host "GPO '$GPOName' created successfully." -ForegroundColor Green
        
        # Link the GPO to the domain
        New-GPLink -Name $GPOName -Target $DomainDN -ErrorAction Stop
        Write-Host "GPO '$GPOName' linked to domain '$DomainDN' successfully." -ForegroundColor Green
        
        # Configure the GPO to distribute the root CA certificate
        $regPath = "HKLM\Software\Policies\Microsoft\SystemCertificates\AuthRoot\Certificates"
        if (-Not (Test-Path -Path $CertPath)) {
            Write-Host "Certificate file not found at path: $CertPath" -ForegroundColor Red
            throw "Certificate file not found at path: $CertPath"
        }
        
        try {
            $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
            $cert.Import($CertPath)
            $certBytes = $cert.RawData
            $certHash = $cert.Thumbprint
        } catch {
            Write-Host "Error reading certificate file: $_" -ForegroundColor Red
            throw "Error reading certificate file: $_"
        }
                
        $truncatedCertHash = $certHash.Substring(0, [Math]::Min(255, $certHash.Length))
        Set-GPPrefRegistryValue -Name $GPOName -Context Computer -Key $regPath -ValueName $truncatedCertHash -Type Binary -Value $certBytes
        Write-Host "Root CA certificate configured in GPO." -ForegroundColor Green
        
    } catch {
        Write-Host "Error configuring Root CA GPO: $_" -ForegroundColor Red
        exit 1
    }
}

# Main script execution
Write-Host "Starting GPO configuration for Root CA distribution..." -ForegroundColor Cyan

# Step 2: Create and configure the GPO for distributing the root CA certificate
Configure-RootCAGPO -GPOName $gpoName -DomainDN $domainDN -CertPath $certPath

Write-Host "GPO configuration for Root CA distribution completed successfully." -ForegroundColor Green
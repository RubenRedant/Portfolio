#### Configuratie voor CA ####

###############################################################################

# Installeer features voor CA en Web Enrollment
Install-WindowsFeature -Name ADCS-Cert-Authority, Web-Server, Web-WebServer, Web-Mgmt-Tools, Web-Scripting-Tools, Web-Windows-Auth, Web-ISAPI-Ext, Web-ISAPI-Filter, ADCS-Web-Enrollment, ADCS-Enroll-Web-Svc, ADCS-Enroll-Web-Pol -IncludeManagementTools

# Start de W3SVC service
Start-Service W3SVC

# Import de ADCSDeployment module
Import-Module ADCSDeployment

# Installeer CA deze nog niet geinstalleerd is
$CAConfig = "server1\ws2-2425-ruben.hogent"
$CAInstalled = Get-ChildItem -Path Cert:\LocalMachine\CA | Where-Object {$_.Issuer -match "ws2-2425-ruben.hogent"}
if (-not $CAInstalled) {
    Install-AdcsCertificationAuthority -CAType "EnterpriseRootCA" -CACommonName "ws2-2425-ruben.hogent" -KeyLength 2048 -HashAlgorithm SHA256 -Force
    Write-Output "Certification Authority succesvol geinstalleerd."
} else {
    Write-Output "Certification Authority is al geinstalleerd."
}

# Installeer Web Enrollment service
Install-AdcsWebEnrollment

# Installeer Enrollment Web services
Install-AdcsEnrollmentWebService -CAConfig $CAConfig -AuthenticationType Kerberos
Install-AdcsEnrollmentPolicyWebService -AuthenticationType Kerberos -Force

# Herstart IIS services
iisreset

# Maak een GPO aan -> om CA te vertrouwen voor toestellen binnen het domein
Import-Module GroupPolicy
$GPOName = "TrustedRootCa"
if (-not (Get-GPO -Name $GPOName -ErrorAction SilentlyContinue)) {
    New-GPO -Name $GPOName
}

# Zorg ervoor dat de map C:Temp bestaat voor het opslaan van het geëxporteerde CA certificate.
$CertFilePath = "C:\Temp\CA_Cert.cer"
if (-not (Test-Path -Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp"
}


# Exporteer CA certificaat en voeg het toe aan de GPO
$CACert = Get-ChildItem -Path Cert:\LocalMachine\CA | Where-Object { $_.Issuer -match "ws2-2425-ruben.hogent" } | Select-Object -First 1
if ($CACert) {
    Export-Certificate -Cert $CACert -FilePath $CertFilePath
    Write-Output "CA Certificate geexporteerd naar $CertFilePath."
    
    $CertThumbprint = $CACert.Thumbprint
    
    # CA certificaat toevoegen aan GPO
    $PolicyPath = "HKLM\SOFTWARE\Policies\Microsoft\SystemCertificates\AuthRoot\Certificates"
    Set-GPRegistryValue -Name "TrustedRootCa" -Key $PolicyPath -ValueName $CertThumbprint -Type Binary -Value ([System.IO.File]::ReadAllBytes($CertFilePath))
    Write-Output "Root CA Certificaat toegevoegd aan GPO."
} else {
    Write-Output "Error: CA Certificaat niet gevonden."
}

# Link de GPO aan het domein
$Domain = (Get-ADDomain).DistinguishedName
$GPOName = "TrustedRootCa"
New-GPLink -Name $GPOName -Target $Domain -LinkEnabled Yes
Write-Output "GPO '$GPOName' gelinkt aan domein."
# SQL SERVER INSTALLATIE + CONFIGURATIE

#### !!!!! als administrator uitvoeren !!!! ####


param(
    [string]$IsoPath = "D:\setup.exe",
    [string]$InstanceName = "MSSQLSERVER",
    [string]$DataDir = "C:\SQL\Data",
    [string]$LogDir = "C:\SQL\Logs",
    [string]$TempDir = "C:\SQL\TempDB",
    [string]$BackupDir = "C:\SQL\Backup",
    [string]$SaPassword = "Letmeinpls!1",
    [string]$ServiceAccountName = "ws2-2425-ruben.hogent\Administrator",
    [string]$ServiceAccountPassword = "vagrant",
    [string[]]$SystemAdminAccounts = @("ws2-2425-ruben.hogent\Administrator")
)
# Variabelen
$DomainName = "ws2-2425-ruben.hogent"  
$DomainAdminUser = "Administrator"    
$Password = "vagrant"                 

# Beveilig het wachtwoord
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ("$DomainName\$DomainAdminUser", $SecurePassword)

# Voeg de computer toe aan het domein
Write-Host "Computer toevoegen aan het domein $DomainName..." -ForegroundColor Cyan
Add-Computer -DomainName $DomainName -Credential $Credential -Force -Restart


$arguments = @(
    "/Q",
    "/IACCEPTSQLSERVERLICENSETERMS",
    "/ACTION=Install",
    "/FEATURES=SQLENGINE",
    "/INSTANCENAME=$InstanceName",
    "/SECURITYMODE=SQL",
    "/SAPWD=$SaPassword",
    "/SQLSVCACCOUNT=$ServiceAccountName",
    "/SQLSVCPASSWORD=$ServiceAccountPassword",
    "/SQLSYSADMINACCOUNTS=$SystemAdminAccounts",
    "/SQLUSERDBDIR=$DataDir",
    "/SQLUSERDBLOGDIR=$LogDir",
    "/SQLTEMPDBDIR=$TempDir",
    "/SQLBACKUPDIR=$BackupDir",
    "/UPDATEENABLED=False"
)


# Start installatie
Write-Host "SQL Server installatie gestart..." -ForegroundColor Cyan
try {
    Start-Process -FilePath $IsoPath -ArgumentList $arguments -Wait
    Write-Host "SQL Server installatie geslaagd." -ForegroundColor Green
} catch {
    Write-Host "SQL Server installatie mislukt met error: $_" -ForegroundColor Red
    exit 1
}

# Firewall regels om verkeer door poorten van SQL server toe te laten
New-NetFirewallRule -DisplayName "Allow SQL Server TCP 1433" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow
New-NetFirewallRule -DisplayName "Allow SQL Server UDP 1434" -Direction Inbound -Protocol UDP -LocalPort 1434 -Action Allow

# Installeer Sqlserver modules en importeer deze
Write-Host "Importeren van SqlServer module..." -ForegroundColor Cyan
try {
    Install-Module -Name SqlServer -Scope CurrentUser -Force -AllowClobber
    Import-Module SqlServer
    Write-Host "SqlServer module succesvol imported." -ForegroundColor Green
} catch {
    Write-Host "Error tijdens importeren van SqlServer module: $_" -ForegroundColor Red
    exit 1
}

# Stel de Remote Access registry key in
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\MSSQLServer\SuperSocketNetLib\Tcp' -Name RemoteAccessEnabled -Value 1

# Start de SQLBrowser
Set-Service -Name SQLBrowser -StartupType Automatic
Start-Service -Name SQLBrowser


# Restart SQL server service
Restart-Service -Name MSSQLSERVER


# Definieer de variabelen
$serverInstance = "localhost"
$domainGroup = "ws2-2425-ruben\Domain Users"

#domeingebruikers kunnen laten inloggen op de SQL server
# + databases kunnen laten aanmaken

$query = @"
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'$domainGroup')
BEGIN
    CREATE LOGIN [$domainGroup] FROM WINDOWS;
END
ALTER SERVER ROLE [dbcreator] ADD MEMBER [$domainGroup];
"@

$connectionString = "Server=$serverInstance;Database=master;User ID=sa;Password=Letmeinpls!1;TrustServerCertificate=True;"

try {
    Invoke-Sqlcmd -ConnectionString $connectionString -Query $query
    Write-Output "Login voor $domainGroup aangemaakt + de dbcreator rol succesvol toegevoegd op $serverInstance."
} catch {
    Write-Output "Login aanmaken voor $domainGroup gefaald via Invoke-Sqlcmd: $_"
}
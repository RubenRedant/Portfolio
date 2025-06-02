# Define the site and document root
$siteName = "CertSrv"
$webRoot = "C:\inetpub\wwwroot\CertSrv"
$port = 80  # Port for the site (ensure it is not in use)
$defaultDocument = "index.html"  # Change as necessary to your site's default document

# Function to check if the site exists
function SiteExists {
    param($siteName)
    $site = Get-WebSite -Name $siteName -ErrorAction SilentlyContinue
    return $null -ne $site
}

# Function to create the CertSrv site if it doesn't exist
function Create-CertSrvSite {
    Write-Host "Creating CertSrv site..." -ForegroundColor Green

    # Create the site if it doesn't exist
    if (-not (SiteExists -siteName $siteName)) {
        Write-Host "Site $siteName does not exist. Creating it now..." -ForegroundColor Green
        
        # Create the site directory if it doesn't exist
        if (-not (Test-Path $webRoot)) {
            New-Item -Path $webRoot -ItemType Directory -Force
        }

        # Create the IIS site
        New-WebSite -Name $siteName -Port $port -PhysicalPath $webRoot -Force
        Write-Host "Site $siteName created successfully." -ForegroundColor Green
    } else {
        Write-Host "Site $siteName already exists. Skipping creation step." -ForegroundColor Yellow
    }
}

# Function to enable Directory Browsing
function Enable-DirectoryBrowsing {
    Write-Host "Enabling Directory Browsing for site: $siteName" -ForegroundColor Green
    
    # Open IIS Manager and enable Directory Browsing
    if (SiteExists -siteName $siteName) {
        Set-WebConfigurationProperty -Filter "/system.webServer/directoryBrowse" -Name "enabled" -Value "True" -Location $siteName
        Write-Host "Directory Browsing enabled." -ForegroundColor Green
    } else {
        Write-Host "Site $siteName not found. Make sure IIS is installed and the site exists." -ForegroundColor Red
        exit 1
    }
}

# Function to check if the site exists
function SiteExists {
    param (
        [string]$siteName
    )
    
    $site = Get-WebSite -Name $siteName -ErrorAction SilentlyContinue
    return $null -ne $site
}

# Function to configure Default Document without duplicates
function Configure-DefaultDocument {
    Write-Host "Configuring Default Document for site: $siteName" -ForegroundColor Green

    if (SiteExists -siteName $siteName) {
        # Haal de huidige lijst van default documents op
        $currentConfig = Get-WebConfiguration "/system.webServer/defaultDocument/files" -Location $siteName

        # Extraheren van de 'Value' eigenschappen van elk configuratie-element
        $currentDocs = $currentConfig.Collection | ForEach-Object { $_.Value }

        Write-Host "Huidige default documents:" -ForegroundColor Cyan
        $currentDocs | ForEach-Object { Write-Host "- $_" }

        # Controleer of het gewenste default document al bestaat (case-insensitive)
        $documentExists = $false
        foreach ($doc in $currentDocs) {
            if ($doc -ieq $defaultDocument) {
                $documentExists = $true
                break
            }
        }

        if (-not $documentExists) {
            # Voeg het default document toe aan de lijst
            try {
                Add-WebConfigurationProperty -Filter "/system.webServer/defaultDocument/files" `
                                             -Name "." `
                                             -Value @{ value = $defaultDocument } `
                                             -Location $siteName -Force

                Write-Host "Default document '$defaultDocument' toegevoegd." -ForegroundColor Green
            } catch {
                Write-Host "Fout tijdens het toevoegen van het default document '$defaultDocument': $_" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "Default document '$defaultDocument' bestaat al. Duplicatie overslaan." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Site '$siteName' niet gevonden. Zorg ervoor dat IIS is geïnstalleerd en de site bestaat." -ForegroundColor Red
        exit 1
    }
}

# Function to set the correct permissions for IIS_IUSRS group on CertSrv directory
function Set-IISPermissions {
    Write-Host "Setting permissions for IIS_IUSRS on $webRoot" -ForegroundColor Green
    
    # Ensure IIS_IUSRS has Read permissions
    $folderAcl = Get-Acl $webRoot
    $permission = "IIS_IUSRS","Read","Allow"
    
    # Set the permissions
    $folderAcl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($permission[0], $permission[1], "ContainerInherit,ObjectInherit", "None", "Allow")))
    Set-Acl -Path $webRoot -AclObject $folderAcl
    
    Write-Host "Permissions for IIS_IUSRS set successfully." -ForegroundColor Green
}

# Ensure IIS is installed and the site exists
try {
    # Check if IIS is installed
    Import-Module WebAdministration -ErrorAction Stop
} catch {
    Write-Host "IIS is not installed on this machine. Please install IIS before running this script." -ForegroundColor Red
    exit 1
}

# Create CertSrv site if not exists
Create-CertSrvSite

# Perform operations
Enable-DirectoryBrowsing
Configure-DefaultDocument
Set-IISPermissions

# Restart IIS to apply changes
Write-Host "Restarting IIS..." -ForegroundColor Green
iisreset

Write-Host "Directory Browsing enabled, default document configured, and permissions set successfully." -ForegroundColor Green

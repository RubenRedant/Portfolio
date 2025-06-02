# Dit script installeert SQL Server Management Studio (SSMS) en Management Tools op de client

# Controleer of de gebruiker administrator rechten heeft
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Dit script moet worden uitgevoerd met administrator rechten."
    exit
}

function Install-SQLServerManagementStudio {
    Write-Host "Downloading SQL Server Management Studio..."
    $Path = "TEMP:\SSMS"
    $Installer = "SSMS-Setup-ENU.exe"
    $URL = "https://aka.ms/ssmsfullsetup"
    Invoke-WebRequest $URL -OutFile $Path\$Installer

    Write-Host "Installing SQL Server Management Studio..."
    Start-Process -FilePath $Path\$Installer -Args "/install /quiet" -Verb RunAs -Wait
    Remove-Item $Path\$Installer

    # Controleer of de installatie succesvol was
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SSMS is succesvol geïnstalleerd."
    } else {
        Write-Error "Er is een fout opgetreden tijdens de installatie van SSMS."
    }

    # Verwijder het installatiebestand
    Remove-Item -Path $installerPath -Force
}

Install-SQLServerManagementStudio
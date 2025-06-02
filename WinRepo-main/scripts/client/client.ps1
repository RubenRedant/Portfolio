# variabelen
$DomainName = "WS2-2425-ruben.hogent"
$InterfaceAlias = "Ethernet 2"
$PreferredDNSServers = @("192.168.24.10", "192.168.24.20")
$DefaultGateway = "192.168.24.10"
$Username = "Administrator"  
$Password = "vagrant"

# paswoord naar secure string
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force

# Maak credential object
$Credential = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)

# Activeer het administrator account
Write-Host "Activeren van het administrator account..."
try {
    net user administrator /active:yes
    Write-Host "Administrator account succesvol geactiveerd."
} catch {
    Write-Host "Error bij het activeren van het administrator account. Error: $_"
    exit 1
}

# Check if the network adapter is already configured to use DHCP
$NetIPInterface = Get-NetIPInterface -InterfaceAlias $InterfaceAlias -ErrorAction SilentlyContinue

if ($NetIPInterface.Dhcp -eq "Enabled") {
    Write-Host "Network adapter is al ingesteld om DHCP te gebruiken. Overslaan...."
} else {
    # Configure network adapter to obtain IP address via DHCP
    Write-Host "Instellen van netwerkadapter om DHCP te gebruiken..."
    Try {
        Set-NetIPInterface -InterfaceAlias $InterfaceAlias -Dhcp Enabled -ErrorAction Stop
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ResetServerAddresses -ErrorAction Stop
        Write-Host "Netwerkadapter ingesteld om DHCP te gebruiken."
    } Catch {
        Write-Host "Fout bij het instellen van netwerkadapter om DHCP te gebruiken. Error: $_"
        Exit 1
    }
}

# DNS servers
Write-Host "Checken of DNS servers al geconfigureerd zijn..."
$CurrentDNSServers = (Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4).ServerAddresses
if ($CurrentDNSServers -eq $PreferredDNSServers) {
    Write-Host "DNS servers zijn al geconfigureerd. Overslaan..."
} else {
    Write-Host "Configureren van DNS servers..."
    Try {
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $PreferredDNSServers -ErrorAction Stop
        Write-Host "DNS servers geconfigureerd."
    } Catch {
        Write-Host "Fout bij het configureren van DNS servers. Error: $_"
        Exit 1
    }
}

#  default gateway
Write-Host "Checken of default gateway al geconfigureerd is..."
Try {
    $CurrentGateway = (Get-NetRoute -InterfaceAlias $InterfaceAlias -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue).NextHop
    if ($CurrentGateway -eq $DefaultGateway) {
        Write-Host "Default gateway is al geconfigureerd. Overslaan..."
    } else {
        Write-Host "Configureren van default gateway..."
        Try {
            Remove-NetRoute -InterfaceAlias $InterfaceAlias -NextHop $CurrentGateway -Confirm:$false -ErrorAction SilentlyContinue
            New-NetRoute -InterfaceAlias $InterfaceAlias -DestinationPrefix "0.0.0.0/0" -NextHop $DefaultGateway -ErrorAction Stop
            Write-Host "Default gateway geconfigureerd."
        } Catch {
            Write-Host "Fout bij het configureren van default gateway. Error: $_"
            Exit 1
        }
    }
} Catch {
    Write-Host "Fout bij het controleren van default gateway. Error: $_"
    Exit 1
}

# Wachten op toewijzing van IP-adres
Write-Host "Wachten op toewijzing van IP-adres..."
Start-Sleep -Seconds 30

# Controleren of een geldig IP-adres is toegewezen
$IPAddress = (Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 |
              Where-Object { $_.IPAddress -notlike '169.*' }).IPAddress

if ($IPAddress) {
    Write-Host "Geldig IP-adres toegewezen: $IPAddress"
} else {
    Write-Host "Fout: Geen geldig IP-adres toegewezen."
    Exit 1
}

# Verifiëren van DNS van domein
Write-Host "Controleren van DNS van domein $DomainName..."
Try {
    $dcIP = (Resolve-DnsName $DomainName -ErrorAction Stop).IPAddress
    Write-Host "Domein $DomainName resolved naar IP-adres: $dcIP"
} Catch {
    Write-Host "Fout bij het resolven van domein $DomainName. Error: $_"
    Exit 1
}


# Join computer in domein
Write-Host "Checken of computer al in het domein zit..."
Try {
    $CurrentDomain = (Get-WmiObject -Class Win32_ComputerSystem).Domain
    if ($CurrentDomain -eq $DomainName) {
        Write-Host "Computer is al deel van het domein $DomainName. Overslaan..."
    } else {
        Write-Host "Joinen van computer in domein $DomainName..."
        Try {
            Add-Computer -DomainName $DomainName -Credential $Credential -ErrorAction Stop -Verbose
            Write-Host "Computer toegevoegd in domein. Herstart nu..."
            Restart-Computer -Force
        } Catch {
            Write-Host "Fout bij het joinen van domein. Error: $_"
            Exit 1
        }
    }
} Catch {
    Write-Host "Fout bij het controleren van huidige domein. Error: $_"
    Exit 1
}
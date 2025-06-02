# script voor secondary DNS server + AD

# variabelen
$InterfaceAlias = "Ethernet 2"
$StaticIPAddress = "192.168.24.20"
$SubnetMask = 24
$DefaultGateway = "192.168.24.1"
$PreferredDNSServers = @("192.168.24.10", "192.168.24.20")
$PrimaryDNS = "192.168.24.10"
$ZoneName = "WS2-2425-ruben.hogent"
$ReverseZoneName = "24.168.192.in-addr.arpa"

#############################################

$DomainName = "WS2-2425-ruben.hogent"
$Username = "Administrator"
$Password = "vagrant"

# Passwoord naar secure string
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

# Join computer in domein
function Join-ComputerToDomain {
    Write-Host "checken of computer al in het domein zit..."
    Try {
        $CurrentDomain = (Get-WmiObject -Class Win32_ComputerSystem).Domain
        if ($CurrentDomain -eq $DomainName) {
            Write-Host "Computer is al deel van het domein $DomainName. Overslaan..."
        } else {
            Write-Host "toevoegen van computer in domein $DomainName..."
            Try {
                Add-Computer -DomainName $DomainName -Credential $Credential -ErrorAction Stop -Verbose
                Write-Host "Computer toegevoegd in domein. Herstart nu..."
                Restart-Computer -Force
            } Catch {
                Write-Host "Gefaald om domein te joinen. Error: $_"
                Exit 1
            }
        }
    } Catch {
        Write-Host "Gefaald om huidige domein te checken. Error: $_"
        Exit 1
    }
}
####################################################

# Functie om statisch IP-adres in te stellen
function Set-StaticIPAddress {
    Write-Host "Configuring static IP address..."
    $currentIP = Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($currentIP -and $currentIP.IPAddress -eq $StaticIPAddress) {
        Write-Host "Static IP $StaticIPAddress is already configured."
    } else {
        # verwijder bestaand IP-adres
        Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false
        # verwijder bestaande default gateway
        Get-NetRoute -InterfaceAlias $InterfaceAlias -ErrorAction SilentlyContinue | Remove-NetRoute -Confirm:$false
        # instellen van statisch IP-adres en default gateway
        New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $StaticIPAddress -PrefixLength $SubnetMask -DefaultGateway $DefaultGateway
        Write-Host "Static IP $StaticIPAddress configured."
    }
    # controleer of de DNS-servers al geconfigureerd zijn
    $currentDNSServers = (Get-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4).ServerAddresses
    if ($currentDNSServers -eq $PreferredDNSServers) {
        Write-Host "DNS servers zijn al geconfigureerd."
    } else {
        Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses $PreferredDNSServers
        Write-Host "DNS servers geconfigureerd."
    }
}

# Functie om DNS Server rol te installeren
function Install-DNSServerRole {
    Write-Host "Checken van DNS Server rol..."
    $dnsFeature = Get-WindowsFeature -Name DNS
    if ($dnsFeature.Installed) {
        Write-Host "DNS Server rol is al geïnstalleerd."
    } else {
        Write-Host "Installeren van DNS Server rol..."
        Install-WindowsFeature -Name DNS -IncludeManagementTools
        Write-Host "DNS Server rol geïnstalleerd."
    }
}

# Functie om secundaire DNS zones in te stellen
function Set-SecondaryZones {
    Write-Host "instellen van secondary DNS zones..."
    $existingZone = Get-DnsServerZone -Name $ZoneName -ErrorAction SilentlyContinue
    if ($existingZone -and $existingZone.ZoneType -eq "Secondary") {
        Write-Host "Secondary zone $ZoneName bestaat al."
    } else {
        Write-Host "Creëren van secondary zone $ZoneName..."
        Add-DnsServerSecondaryZone -Name $ZoneName -ZoneFile "$ZoneName.dns" -MasterServers $PrimaryDNS
        Write-Host "Secondary zone $ZoneName aangemaakt."
    }

    $existingReverseZone = Get-DnsServerZone -Name $ReverseZoneName -ErrorAction SilentlyContinue
    if ($existingReverseZone -and $existingReverseZone.ZoneType -eq "Secondary") {
        Write-Host "Secondary reverse zone $ReverseZoneName bestaat al."
    } else {
        Write-Host "Creëren van secondary reverse zone $ReverseZoneName..."
        Add-DnsServerSecondaryZone -Name $ReverseZoneName -ZoneFile "$ReverseZoneName.dns" -MasterServers $PrimaryDNS
        Write-Host "Secondary reverse zone $ReverseZoneName aangemaakt."
    }
}

# Main script execution
Set-StaticIPAddress
Install-DNSServerRole
Set-SecondaryZones
Join-ComputerToDomain
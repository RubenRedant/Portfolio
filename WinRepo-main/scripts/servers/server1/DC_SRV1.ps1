# Define parameters
$DomainName = "WS2-2425-ruben.hogent"
$SafeModePassword = ConvertTo-SecureString "Letmeinpls!1" -AsPlainText -Force
$DhcpServerIpAddress = "192.168.24.10"
$LocalAdminPassword = ConvertTo-SecureString "vagrant" -AsPlainText -Force
$ZoneName = "WS2-2425-ruben.hogent"
$ReverseZoneName = "24.168.192.in-addr.arpa"
$SecondaryServer = "192.168.24.20"
$Router = "192.168.24.1"
$DnsServers = "192.168.24.10", "192.168.24.20"
$InterfaceAlias = "Ethernet 2"
$StaticIPAddress = "192.168.24.10"

# Activate the administrator account
Write-Host "Activating the administrator account..."
try {
    net user administrator /active:yes
    Write-Host "Administrator account activated successfully."
} catch {
    Write-Host "Failed to activate the administrator account. Error: $_"
    exit 1
}

# Remove existing IP address configuration
Write-Host "Removing existing IP address configuration..."
try {
    Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 | Remove-NetIPAddress -Confirm:$false
    Write-Host "Existing IP address configuration removed."
} catch {
    Write-Host "Failed to remove existing IP address configuration. Error: $_"
}

# Remove existing default gateway configuration
Write-Host "Removing existing default gateway configuration..."
try {
    Get-NetIPConfiguration -InterfaceAlias $InterfaceAlias | ForEach-Object {
        if ($_.IPv4DefaultGateway) {
            Remove-NetRoute -NextHop $_.IPv4DefaultGateway.NextHop -InterfaceAlias $InterfaceAlias -Confirm:$false
        }
    }
    Write-Host "Existing default gateway configuration removed."
} catch {
    Write-Host "Failed to remove existing default gateway configuration. Error: $_"
}

# Set static IP address and default gateway for Ethernet 2
Write-Host "Setting static IP address and default gateway for $InterfaceAlias..."
try {
    New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $StaticIPAddress -PrefixLength 24 -DefaultGateway $Router
    Write-Host "Static IP address and default gateway set successfully."
} catch {
    Write-Host "Failed to set static IP address and default gateway. Error: $_"
    exit 1
}

# Install and Configure Active Directory Domain Services and DHCP on the primary server
function Install-DC {
    param(
        [string]$DomainName,
        [SecureString]$SafeModePassword,
        [string]$DhcpServerIpAddress,
        [SecureString]$LocalAdminPassword,
        [string]$ZoneName,
        [string]$ReverseZoneName,
        [string]$SecondaryServer,
        [string]$Router,
        [string[]]$DnsServers
    )

    # Install ADDS and DHCP roles
    Install-WindowsFeature -Name AD-Domain-Services, DHCP, DNS -IncludeManagementTools

    # Check if the domain already exists
    Write-Host "Checking if the domain $DomainName already exists..."
    try {
        $domain = Get-ADDomain -Identity $DomainName -ErrorAction Stop
        Write-Host "Domain $DomainName already exists. Skipping forest creation."
    } catch {
        Write-Host "Domain $DomainName does not exist. Creating new AD forest..."
        # Configure a new AD forest
        Install-ADDSForest -DomainName $DomainName -SafeModeAdministratorPassword $SafeModePassword -ForestMode "WinThreshold" -DomainMode "WinThreshold"
        Write-Host "Active Directory configuration completed."
    }

    # Configure DNS zones
    Write-Host "Configuring DNS zones..."
    if (-not (Get-DnsServerZone -Name $ZoneName -ErrorAction SilentlyContinue)) {
        Add-DnsServerPrimaryZone -Name $ZoneName -ZoneFile "$ZoneName.dns"
        Write-Host "Primary forward lookup zone $ZoneName created."
    } else {
        Write-Host "Primary forward lookup zone $ZoneName already exists."
    }

    if (-not (Get-DnsServerZone -Name $ReverseZoneName -ErrorAction SilentlyContinue)) {
        Add-DnsServerPrimaryZone -Name $ReverseZoneName -ZoneFile "$ReverseZoneName.dns"
        Write-Host "Primary reverse lookup zone $ReverseZoneName created."
    } else {
        Write-Host "Primary reverse lookup zone $ReverseZoneName already exists."
    }
    Write-Host "DNS zones succesvol configureerd."

    # Configure zone transfers for the forward lookup zone
    Set-DnsServerPrimaryZone -Name $ZoneName -SecureSecondaries TransferToSecureServers -SecondaryServers $SecondaryServer
    Write-Host "Zone transfer for forward lookup zone $ZoneName configured."

    # Configure zone transfers for the reverse lookup zone
    Set-DnsServerPrimaryZone -Name $ReverseZoneName -SecureSecondaries TransferToSecureServers -SecondaryServers $SecondaryServer
    Write-Host "Zone transfer for reverse lookup zone $ReverseZoneName configured."

    # toevoegen A en PTR records
    Write-Host "Toevoegen van A en PTR records..."
    if (-not (Get-DnsServerResourceRecord -ZoneName $ZoneName -Name "server1" -ErrorAction SilentlyContinue)) {
        Add-DnsServerResourceRecordA -ZoneName $ZoneName -Name "server1" -IPv4Address $DhcpServerIpAddress
        Write-Host "A record voor server1 toegevoegd."
    } else {
        Write-Host "A record voor server1 bestaat al."
    }

    if (-not (Get-DnsServerResourceRecord -ZoneName $ZoneName -Name "server2" -ErrorAction SilentlyContinue)) {
        Add-DnsServerResourceRecordA -ZoneName $ZoneName -Name "server2" -IPv4Address $SecondaryServer
        Write-Host "A record voor server2 toegevoegd."
    } else {
        Write-Host "A record voor server2 bestaat al."
    }

    if (-not (Get-DnsServerResourceRecord -ZoneName $ReverseZoneName -Name "10.24.168.192.in-addr.arpa" -ErrorAction SilentlyContinue)) {
        Add-DnsServerResourceRecordPtr -ZoneName $ReverseZoneName -Name "10.24.168.192.in-addr.arpa" -PtrDomainName "server1.$ZoneName"
        Write-Host "PTR record voor server1 toegevoegd."
    } else {
        Write-Host "PTR record voor server1 bestaat al."
    }

    if (-not (Get-DnsServerResourceRecord -ZoneName $ReverseZoneName -Name "20.24.168.192.in-addr.arpa" -ErrorAction SilentlyContinue)) {
        Add-DnsServerResourceRecordPtr -ZoneName $ReverseZoneName -Name "20.24.168.192.in-addr.arpa" -PtrDomainName "server2.$ZoneName"
        Write-Host "PTR record voor server2 toegevoegd."
    } else {
        Write-Host "PTR record voor server2 bestaat al."
    }
    Write-Host "A en PTR records toegevoegd.." -

    # Reboot van server
    Write-Host "De server reboot nu..."
    Restart-Computer -Force
}

# Call the function to install and configure the Domain Controller
Install-DC -DomainName $DomainName -SafeModePassword $SafeModePassword -DhcpServerIpAddress $DhcpServerIpAddress -LocalAdminPassword $LocalAdminPassword -ZoneName $ZoneName -ReverseZoneName $ReverseZoneName -SecondaryServer $SecondaryServer -Router $Router -DnsServers $DnsServers
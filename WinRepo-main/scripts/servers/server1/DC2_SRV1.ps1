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


# Activate the administrator account
Write-Host "Activating the administrator account..."
try {
    net user administrator /active:yes
    Write-Host "Administrator account activated successfully."
} catch {
    Write-Host "Failed to activate the administrator account. Error: $_"
    exit 1
}


# Maak OU User Account aan, als deze nog niet bestaat
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'UserAccounts'" -SearchBase "DC=ws2-2425-ruben,DC=hogent" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name "UserAccounts" -Path "DC=ws2-2425-ruben,DC=hogent"
} else {
    Write-Host "OU 'UserAccounts' bestaat al."
}

# Maak gebruiker "Ruben" aan in "UserAccounts" OU
New-ADUser -Name "Ruben" `
           -Path "OU=UserAccounts,DC=ws2-2425-ruben,DC=hogent" `
           -AccountPassword $SafeModePassword `
           -Enabled $true `
           -SamAccountName "Ruben" `
           -UserPrincipalName "Ruben@ws2-2425-ruben.hogent" `
           -GivenName "Ruben" `
           -Surname "User"


# Definieer gebruiker en groep
$users = "Ruben"
$group = "Domain Users"

# Lus om te checken ofdat de users al deel zijn van de groep, voeg ze toe indien dat nog niet het geval is
foreach ($user in $users) {
    $isMember = Get-ADGroupMember -Identity $group | Where-Object { $_.SamAccountName -eq $user }

    if ($isMember) {
        Write-Host "$user is al deel van de groep $group ."
    } else {
        try {
            Add-ADGroupMember -Identity $group -Members $user
            Write-Host "$user is nu toegevoegd aan de groep $group ."
        } catch {
            Write-Host "Het toevoegen van $user aan de groep $group is gefaald: $_"
        }
    }
}

function Install-DC-Vervolg {
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

    # Verify network connectivity to the domain controller
    Write-Host "Pinging primary DNS server to verify network connectivity..."
    if (Test-Connection -ComputerName $DhcpServerIpAddress -Count 2 -Quiet) {
        Write-Host "Network connectivity to primary DNS server verified."
    } else {
        Write-Host "Failed to reach primary DNS server. Please check network connectivity."
        exit 1
    }

    # Register the DHCP server in Active Directory
    Write-Host "Registering the DHCP server in Active Directory..."
    try {
        Add-DhcpServerInDC -DnsName $DomainName -IPAddress $DhcpServerIpAddress
        Write-Host "DHCP server registered in Active Directory successfully."
    } catch {
        Write-Host "Failed to register the DHCP server in Active Directory. Error: $_"
        exit 1
    }

    # Configure DHCP scope
    Write-Host "Configuring DHCP scope..."
    try {
        $scope = Get-DhcpServerv4Scope -ScopeId 192.168.24.0 -ErrorAction SilentlyContinue
        if ($null -eq $scope) {
            # Scope does not exist, create it
            Add-DhcpServerv4Scope -Name "Scope1" -StartRange 192.168.24.101 -EndRange 192.168.24.200 -SubnetMask 255.255.255.0 -State Active
            Write-Host "DHCP scope configured successfully."

            # Exclude the last 50 addresses
            Write-Host "Excluding the last 50 addresses from the DHCP scope..."
            Add-DhcpServerv4ExclusionRange -ScopeId 192.168.24.0 -StartRange 192.168.24.151 -EndRange 192.168.24.200
            Write-Host "Exclusion range configured successfully."

            # Set DHCP options
            Write-Host "Setting DHCP options..."
            Set-DhcpServerv4OptionValue -ScopeId 192.168.24.0 -Router $Router
            Set-DhcpServerv4OptionValue -ScopeId 192.168.24.0 -DnsServer $DnsServers
            Set-DhcpServerv4OptionValue -ScopeId 192.168.24.0 -DnsDomain $DomainName
            Write-Host "DHCP options set successfully."
        } else {
            Write-Host "DHCP scope already exists. Skipping scope creation."
        }
    } catch {
        Write-Host "Failed to configure DHCP scope or options. Error: $_"
        exit 1
    }

    Write-Host "Domain Controller, Active Directory, DNS, and DHCP configuration completed."
}



# Call the function to install and configure the Domain Controller
Install-DC-Vervolg -DomainName $DomainName -SafeModePassword $SafeModePassword -DhcpServerIpAddress $DhcpServerIpAddress -LocalAdminPassword $LocalAdminPassword -ZoneName $ZoneName -ReverseZoneName $ReverseZoneName -SecondaryServer $SecondaryServer -Router $Router -DnsServers $DnsServers
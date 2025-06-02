# DHCP Server Setup
# -----------------

# Function to Install DHCP Server Role
function Install-DHCPServer {
    if (Get-WindowsFeature -Name DHCP | Where-Object { $_.Installed -eq $true }) {
        Write-Host "DHCP Server Role is already installed."
    } else {
        Write-Host "Installing DHCP Server Role..."
        Install-WindowsFeature -Name DHCP -IncludeManagementTools -Verbose
        Start-Service -Name DHCPServer
        Set-Service -Name DHCPServer -StartupType Automatic
        Write-Host "DHCP Server Role installed and started."
    }
}

# Function to Configure a DHCP Scope
function Set-DHCPScope {
    param(
        [string]$ScopeName = "HostOnlyNet-Scope",
        [string]$StartRange = "192.168.24.101",
        [string]$EndRange = "192.168.24.200",
        [string]$SubnetMask = "255.255.255.0",
        [string]$Gateway = "192.168.24.1",
        [string]$SubnetID = "192.168.24.0",
        [string]$ExclusionStart = "192.168.24.151",
        [string]$ExclusionEnd = "192.168.24.200"
    )

    # Check if the scope already exists
    $existingScope = Get-DhcpServerv4Scope -ScopeId $SubnetID -ErrorAction SilentlyContinue
    if ($existingScope) {
        Write-Host "Scope $ScopeName already exists. Skipping scope creation."
    } else {
        # Create the DHCP Scope
        Write-Host "Creating DHCP Scope $ScopeName..."
        Add-DhcpServerv4Scope -Name $ScopeName -StartRange $StartRange -EndRange $EndRange -SubnetMask $SubnetMask -State Active
        Write-Host "DHCP Scope $ScopeName created with IP range $StartRange - $EndRange."

        # Set Router (Gateway) Option for the Scope
        Set-DhcpServerv4OptionValue -ScopeId $SubnetID -Router $Gateway
        Write-Host "Router (Default Gateway) set to $Gateway."

        # Add Exclusion Range
        Write-Host "Adding Exclusion Range $ExclusionStart - $ExclusionEnd..."
        Add-DhcpServerv4ExclusionRange -ScopeId $SubnetID -StartRange $ExclusionStart -EndRange $ExclusionEnd
        Write-Host "Exclusion range $ExclusionStart - $ExclusionEnd added to scope."
    }
}

# Function to Set Static IP Address
function Set-StaticIPAddress {
    param(
        [string]$InterfaceAlias = "Ethernet 2",
        [string]$IPAddress = "192.168.24.10",
        [string]$SubnetMask = "24",
        [string]$DefaultGateway = "192.168.24.1"
    )

    # Check if the IP address is already configured
    $existingIP = Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.IPAddress -eq $IPAddress }
    if ($existingIP) {
        Write-Host "Static IP $IPAddress is already configured on interface $InterfaceAlias."
    } else {
        Write-Host "Configuring static IP $IPAddress on interface $InterfaceAlias..."
        New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IPAddress -PrefixLength $SubnetMask -DefaultGateway $DefaultGateway
        Write-Host "Static IP $IPAddress configured with gateway $DefaultGateway."
    }
}

# Main function to install and configure DHCP and static IP
function Initialize-DHCPandStaticIP {
    Write-Host "Starting DHCP and IP configuration setup..."

    # Step 1: Install DHCP Server Role if necessary
    Install-DHCPServer

    # Step 2: Configure DHCP Scope if not already configured
    Set-DHCPScope `
        -ScopeName "HostOnlyNet-Scope" `
        -StartRange "192.168.24.101" `
        -EndRange "192.168.24.200" `
        -SubnetMask "255.255.255.0" `
        -Gateway "192.168.24.1" `
        -SubnetID "192.168.24.0" `
        -ExclusionStart "192.168.24.151" `
        -ExclusionEnd "192.168.24.200"

    # Step 3: Configure Static IP Address for the server
    Set-StaticIPAddress `
        -InterfaceAlias "Ethernet 2" `
        -IPAddress "192.168.24.10" `
        -SubnetMask "24" `
        -DefaultGateway "192.168.24.1"

    Write-Host "DHCP and static IP setup completed."
}

# Run the main function to enable and configure DHCP and static IP
Initialize-DHCPandStaticIP

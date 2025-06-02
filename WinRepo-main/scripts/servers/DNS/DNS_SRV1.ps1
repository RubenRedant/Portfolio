# Define parameters
$PrimaryServer = "192.168.24.10"
$ZoneName = "WS2-2425-ruben.hogent"
$ReverseZoneName = "24.168.192.in-addr.arpa"

# Install DNS Server feature
Install-WindowsFeature -Name DNS -IncludeManagementTools

# Add primary forward lookup zone
if (-not (Get-DnsServerZone -Name $ZoneName -ErrorAction SilentlyContinue)) {
    Add-DnsServerPrimaryZone -Name $ZoneName -ZoneFile "$ZoneName.dns"
    Write-Host "Primary forward lookup zone $ZoneName created."
} else {
    Write-Host "Primary forward lookup zone $ZoneName already exists."
}

# Add primary reverse lookup zone
if (-not (Get-DnsServerZone -Name $ReverseZoneName -ErrorAction SilentlyContinue)) {
    Add-DnsServerPrimaryZone -Name $ReverseZoneName -ZoneFile "$ReverseZoneName.dns"
    Write-Host "Primary reverse lookup zone $ReverseZoneName created."
} else {
    Write-Host "Primary reverse lookup zone $ReverseZoneName already exists."
}

Write-Host "Primary DNS server configuration completed."
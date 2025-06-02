# Define parameters
$ZoneName = "WS2-2425-ruben.hogent"
$ReverseZoneName = "24.168.192.in-addr.arpa"

# Remove primary forward lookup zone
Remove-DnsServerZone -Name $ZoneName -Force

# Remove primary reverse lookup zone
Remove-DnsServerZone -Name $ReverseZoneName -Force

# Uninstall DNS Server feature
Uninstall-WindowsFeature -Name DNS

Write-Host "Primary DNS server configuration undone."
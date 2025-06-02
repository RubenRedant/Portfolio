# Define parameters
$PrimaryServer = "192.168.24.10"
$SecondaryServer = "192.168.24.20"
$ZoneName = "WS2-2425-ruben.hogent"
$ReverseZoneName = "24.168.192.in-addr.arpa"

# Configure zone transfers for the forward lookup zone
Set-DnsServerPrimaryZone -Name $ZoneName -SecureSecondaries TransferToSecureServers -SecondaryServers $SecondaryServer
Write-Host "Zone transfer for forward lookup zone $ZoneName configured."

# Configure zone transfers for the reverse lookup zone
Set-DnsServerPrimaryZone -Name $ReverseZoneName -SecureSecondaries TransferToSecureServers -SecondaryServers $SecondaryServer
Write-Host "Zone transfer for reverse lookup zone $ReverseZoneName configured."

# Add A and PTR records
Write-Host "Adding A and PTR records..."
Add-DnsServerResourceRecordA -ZoneName $ZoneName -Name "server1" -IPv4Address $PrimaryServer
Add-DnsServerResourceRecordA -ZoneName $ZoneName -Name "server2" -IPv4Address $SecondaryServer
Add-DnsServerResourceRecordPtr -ZoneName $ReverseZoneName -Name "10.24.168.192.in-addr.arpa" -PtrDomainName "server1.$ZoneName"
Add-DnsServerResourceRecordPtr -ZoneName $ReverseZoneName -Name "20.24.168.192.in-addr.arpa" -PtrDomainName "server2.$ZoneName"
Write-Host "A and PTR records added."

Write-Host "Zone transfer and DNS records configuration completed."
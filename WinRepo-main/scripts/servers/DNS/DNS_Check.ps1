# Get all DNS zones
$dnsZones = Get-DnsServerZone

# Display DNS zones
foreach ($zone in $dnsZones) {
    Write-Host "Zone Name: $($zone.ZoneName)"
    Write-Host "Zone Type: $($zone.ZoneType)"
    Write-Host "Is Reverse Lookup Zone: $($zone.IsReverseLookupZone)"
    Write-Host "----------------------------------------"
}

Write-Host "DNS zones displayed successfully."
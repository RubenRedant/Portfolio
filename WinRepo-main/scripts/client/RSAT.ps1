Get-WindowsCapability -Name RSAT* -Online | Add-WindowsCapability -Online
$rsatTools = @(
    "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0",
    "Rsat.Dns.Tools~~~~0.0.1.0",
    "Rsat.Dhcp.Tools~~~~0.0.1.0",
    "Rsat.Sql.Tools~~~~0.0.1.0"
)

foreach ($tool in $rsatTools) {
    Add-WindowsCapability -Online -Name $tool
}
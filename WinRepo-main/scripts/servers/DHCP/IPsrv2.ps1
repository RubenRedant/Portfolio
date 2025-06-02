# Instellen van statische IP voor Server 2
New-NetIPAddress -InterfaceAlias "Ethernet 2" -IPAddress 192.168.24.20 -PrefixLength 24 -DefaultGateway 192.168.24.1

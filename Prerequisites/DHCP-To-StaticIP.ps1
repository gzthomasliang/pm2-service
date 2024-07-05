# powershell 5,not 7
$gateway="192.168.0.20"

$wmi = Get-WmiObject win32_networkadapterconfiguration -filter "ipenabled = 'true'"
$IPAddress = $wmi | Select-Object -ExpandProperty IPAddress | Where-Object { $_ -match '(\d{1,3}\.){3}\d{1,3}' }
$wmi.EnableStatic($IPAddress, "255.255.255.0")
$wmi.SetGateways($gateway, 1)
$wmi.SetDNSServerSearchOrder($gateway)

# powershell 7
$NICName=(Get-NetAdapter)[0].InterfaceAlias
$IPAddress=(Get-NetIPAddress -InterfaceAlias Ethernet0 -AddressFamily IPv4).IPAddress
Remove-NetIPAddress -InterfaceAlias $NICName -AddressFamily IPv4 -Confirm:$false
New-NetIPAddress -InterfaceAlias $NICName -AddressFamily IPv4 -IPAddress $IPAddress -PrefixLength 24 -DefaultGateway $gateway -Verbose
Set-DnsClientServerAddress -InterfaceAlias $NICName -ServerAddresses $gateway -Verbose 
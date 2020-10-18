<#
.Synopsis
   Releases DHCP reservations and then renews them.
.DESCRIPTION
   Releases DHCP reservations for all active interfaces and renews them. Fully PowerShell equivilent to running `ipconfig /release; ipconfig /renew`.
.EXAMPLE
   Renew-DHCP
.INPUTS
   None
.OUTPUTS
   Returns the new IP address, Subnet Mask, Default Gateway, and DNS Server for each interface that was renewed.
.NOTES
   Fully PowerShell equivilent to running `ipconfig /release; ipconfig /renew`.
#>

function Renew-DHCP
{
    #Add each network interface to a list for manipulation, only selecting those that have IP and DHCP enabled
    $ifaceList = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where { $_.IpEnabled -eq $true -and $_.DhcpEnabled -eq $true} 
    
    #This is outside the foreach loop since we don't need it to be said each time 
    Write-Host "Flushing DHCP reservations..." -ForegroundColor Yellow
    
    foreach ($iface in $ifaceList) {
	  $iface.ReleaseDHCPLease() | out-Null
    
    #Sometimes DHCP can be a bit slow...give it a little time to process
    Sleep 2
    
    #Renew the DHCP reservation for the current interface
    Write-Host "Renewing DHCP reservations..." -ForegroundColor Yellow
    $iface.RenewDHCPLease() | out-Null 

    #Assign each of the interface properties to print out to variables for manipulation
    $IfaceName = $iface.NetConnectionID
    #$Name = $iface.GetRelated("Win32_PnPEntity") | Select-Object -ExpandProperty Name
    $IPAddress  = $iface.IpAddress[0]
    $SubnetMask  = $iface.IPSubnet[0]
    $DefaultGateway = $iface.DefaultIPGateway[0]
    $DNSServers  = $iface.DNSServerSearchOrder
    $MACAddress  = $iface.MACAddress
    $DHCPServer  = $iface.DHCPServer
      
    #Add the specific properties to print out to an object
    $ifaceOutput  = [PSCustomObject]@{
      Name = $IfaceName
      IPAddress = $IPAddress
      SubnetMask = $SubnetMask
      Gateway = $DefaultGateway
      DNSServers = $DNSServers
      MACAddress = $MACAddress
      DHCPServer = $DHCPServer
	  }
    #Add each interface's new output to a list   
    $ifaceOutputs += $ifaceOutput
      
	}
    Write-Host "The new IP Addresses are seen below: " -ForegroundColor Green
    $ifaceOutputs | Out-Host
    
    #Get-NetIPConfiguration
}

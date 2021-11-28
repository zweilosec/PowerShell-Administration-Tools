<#
.Synopsis
  A simple script for listing open TCP or UDP ports.

.Description
  A PowerShell script for listing open TCP and/or UDP ports. 

  Options:
  -TCP : Show open TCP ports
  -UDP : Show open UDP ports
  -Listening : Show listening ports

  Default is to show all open TCP and UDP ports.

.Example
  Get-PortsWithProcess

  Lists all open TCP and UDP ports.

.Example
  Get-PortsWithProcess -Listening
  
  Lists all listening ports.

.Example
  Get-PortsWithProcess -TCP

  List all open TCP ports.

.Example
  Get-PortsWithProcess -TCP -Listening

  List all listening TCP ports.

.Example
  Get-PortsWithProcess -UDP

  List all open UDP ports.

.Notes
  Author: Beery, Christopher
  Created: 25 Nov 2021
  Last Modified: 27 Nov 2021

  Helpful sites:
  https://stackoverflow.com/questions/54648600/add-custom-value-in-powershell-output-table
  https://www.top-password.com/blog/find-which-process-is-listening-on-given-port-in-windows/
#>

#region Functions
function Get-PortsWithProcess
{
  #[switch] parameters are boolean, and default to $false if not included
  param([switch]$TCP,[switch]$UDP,[switch]$Listening)

  function Get-TCPPorts
  {
    $processes = Get-NetTCPConnection

    foreach ($process in $processes)
    {
      # The syntax @{n="Proto";e={"TCP"}} creates a new property with n=Name and e=Object.  n must be inside "" and e must be inside {}
      $process | Select -Property @{n="Proto";e={"TCP"}},LocalPort,LocalAddress,OwningProcess,@{n="ProcessName";e={(Get-Process -PID $process.OwningProcess).ProcessName}}
    }
  }
  function Get-TCPListener
  {
    $processes = Get-NetTCPConnection | ? {($_.State -eq "Listen") -and ($_.RemoteAddress -eq "0.0.0.0" -or "::")}

    foreach ($process in $processes)
    {
      $process | Select -Property @{n="Proto";e={"TCP"}},LocalPort,LocalAddress,OwningProcess,@{n="ProcessName";e={(Get-Process -PID $process.OwningProcess).ProcessName}}
    }
  }

  function Get-UDPPorts
  {
    $processes = Get-NetUDPEndpoint

    foreach ($process in $processes)
    {
      $process | Select -Property @{n="Proto";e={"UDP"}},LocalPort,LocalAddress,OwningProcess,@{n="ProcessName";e={(Get-Process -PID $process.OwningProcess).ProcessName}}
    }
  }
#endregion Functions  
  
#region Output  
#check which parameter flags were included and give the correct output
  if ($TCP) 
  { 
    Get-TCPListener | Format-Table
    Return
  }

  elseif ($TCP -and $Listening) 
  { 
    Get-TCPListener | Format-Table
    Return
  }

  elseif ($UDP) 
  { 
    Get-UDPPorts | Format-Table
    Return
  }

  elseif ( $TCP -eq $false -and $UDP -eq $false -and $Listening)
  {
    Get-TCPListener | Format-Table
    Get-UDPPorts | Format-Table
    Return
  }

  else
  {
    Get-TCPPorts | Format-Table
    Get-UDPPorts | Format-Table
    Return
  }
}
#endregion Output

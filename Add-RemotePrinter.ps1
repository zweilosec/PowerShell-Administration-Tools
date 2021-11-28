<#
.Synopsis
  A simple script for adding a printer to a remote computer.
.Description
  A PowerShell script for adding a printer to a remote computer by IP or Computername.
  Will prompt for credentials for each computer this is remoted into.
  Mandatory Arguments:
  -Computer : A list or single ComputerName or IP. Can be piped into this command.
  -Domain : Domain name of the user account being used
  -User : Username for account being used to remote into the computer
  -IP : IP of the printer to add
  -Name : Windows display name for the printer
  -Driver : Full name of the driver to install for the printer
  Optional Arguments:
  -PortName : Name of the printer port that will be added
  If a printer port name is not specified, will use the printer IP [default].
.Example
  Add-RemotePrinter -Computer 10.10.10.123 -Domain zweilos.local -User zweilosec -IP 10.10.10.244 -Name "Office Printer" -Driver "HP Universal Printing PCL 6"
  Remote into the computer at 10.10.10.123 as zweilos.local/zweilosec and install the printer named "Office Printer".
.Example
  Add-RemotePrinter -Computer (cat ./ComputerList.txt) -Domain zweilos.local -User zweilosec -IP 10.10.10.244 -Name "Office Printer" -Driver "HP Universal Printing PCL 6"
  Add the printer "Office Printer" to all the computers specified in ComputerList.txt (one computername/IP per line!)
.Example
  "ZWEILOSCOMP01", "ZWEILOSCOMP02" | Add-RemotePrinter -Domain zweilos.local -User zweilosec -IP 10.10.10.244 -Name "Office Printer" -Driver "HP Universal Printing PCL 6"
  Add the printer "Office Printer" to all the computers specified prior to pipe (can take any list of piped-in computernames)  
.Notes
  Author: Beery, Christopher
  Created: 6 Mar 2020
  Last Modified: 27 Nov 2021
  Useful links:
  https://info.sapien.com/index.php/scripting/scripting-how-tos/take-values-from-the-pipeline-in-powershell
#>
function Add-RemotePrinter
{
  Param(
    #ValueFromPipeline allows this parameter to take input piped into this command
    [Parameter(Mandatory,
    ValueFromPipeline,
    HelpMessage="Enter one or more computer names separated by commas.",
    ParameterSetName="Computer")]
    [string[]]
    $Computers,

    [Parameter(Mandatory,
    HelpMessage="Enter a username to log into the remote computer.",
    ParameterSetName="User")]
    [string]
    $UserName,

    [Parameter(Mandatory,
    HelpMessage="Enter a domain to log into the remote computer.",
    ParameterSetName="Domain")]
    [string]
    $DomainName,

    [Parameter(Mandatory,
    HelpMessage="Enter the IP of the printer to add.",
    ParameterSetName="IP")]
    [string]
    $PrinterIp,
    
    [Parameter(Mandatory,
    HelpMessage="Enter the full name of the printer driver.",
    ParameterSetName="Driver")]
    [string]
    $FullDriverName,

    [Parameter(Mandatory,
    HelpMessage="Enter the name you wish to be displayed for the printer.",
    ParameterSetName="Name")]
    [string]
    $WindowsDisplayName,   
      
    [Parameter(Optional,
    ParameterSetName="PortName")]
    [string]
    $PortName,   
  )
  
  if (-not ($PortName))
    {
    $PortName = $PrinterIP
    }
  
  Begin{}
  Process
  {
  Foreach ( $computer in $Computers) {
    $session = New-PSSession -ComputerName $computer -Credential $DomainName\$UserName #will prompt for credentials for each computer
    Invoke-Command -Session $session {Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIp}
    Invoke-Command -Session $session {Add-PrinterDriver -Name "$FullDriverName"}
    Invoke-Command -Session $session {Add-Printer -Name "$WindowsDisplayName" -PortName $PortName -DriverName "$FullDriverName"}
    Invoke-Command -Session $session {Write-Output "Printer Added Successfully."}
    Remove-PSSession -ComputerName $computer
    }
  }
  End{}
}

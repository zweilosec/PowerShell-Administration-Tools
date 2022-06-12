<#
.Synopsis
   Script for gathering software inventory information.
.DESCRIPTION
   Script for gathering ComputerName, DisplayName, DisplayVersion, Publisher for all software from a list of computers.  
.EXAMPLE
  Get-SoftwareInventory -ComputerName Example-Comp1 -Verbose
.EXAMPLE
  Get-SoftwareInventory .\Computers.txt
.EXAMPLE
  Get-ADComputer -Filter * -SearchBase "OU=TestOU,DC=TestDomain,DC=com" | Select -Property Name | Get-SoftwareInventory
.INPUTS
   -ComputerName <computer name>
   Input a list of computer names, either piped in as an object or a text file file with one computer name per line.
.OUTPUTS

ComputerName   DisplayName                                                            DisplayVersion        Publisher
------------   -----------                                                            --------------        ---------
{COMPUTERNAME} Windows Driver Package - Intel (Netwtw02) net  (04/16/2021 19.37.23.4) 04/16/2021 19.37.23.4 Intel
{COMPUTERNAME} Mozilla Firefox (x64 en-US)                                            121.0.1               Mozilla
{COMPUTERNAME} Mozilla Maintenance Service                                            99.0                  Mozilla
etc.

.NOTES
  Authors: Beery, Christopher (https://github.com/zweilosec)
  Created: 11 Jun 2022
  Last Modified: 11 Jun 2022
.FUNCTIONALITY
   Computer software enumeration tool
#>

function Get-SoftwareInventory
{
  #Enable -Verbose output, piping of input from other comdlets, and more
  [CmdletBinding()]
  #List of input parameters
  Param
  (   
    #List of ComputerNames to process
    [Parameter(ValueFromPipeline=$true,
    ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullOrEmpty()]
    [alias('Name')] #Allows for piping in of computers by name from Active Directory (Get-ADComputer)
    [string[]]
    $ComputerName
  )

  Begin
  {
    $SoftwareArray = @()
  }

  Process
  {
    #Variable to hold the location of Currently Installed Programs
    $SoftwareRegKey = ”SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall” 

    #Create an instance of the Registry Object and open the HKLM base key
    $Reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey(‘LocalMachine’,$ComputerName) 

    #Open the Uninstall subkey using the OpenSubKey Method
    $RegKey = $Reg.OpenSubKey($SoftwareRegKey) 

    #Create a string array containing all the subkey names
    [String[]]$SubKeys = $RegKey.GetSubKeyNames() 

    #Open each Subkey and use its GetValue method to return the required values
    foreach($key in $SubKeys)
    {
        $UninstallKey = $SoftwareRegKey + ”\\” + $key 
        $UninstallSubKey = $reg.OpenSubKey($UninstallKey) 
        $obj = [PSCustomObject]@{
                Computer_Name = $ComputerName
                DisplayName = $($UninstallSubKey.GetValue(“DisplayName”))
                DisplayVersion = $($UninstallSubKey.GetValue(“DisplayVersion”))
                InstallLocation = $($UninstallSubKey.GetValue(“InstallLocation”))
                Publisher = $($UninstallSubKey.GetValue(“Publisher”))
        }
        $SoftwareArray += $obj
    } 
  }
  End
  {
    $SoftwareArray | Where-Object { $_.DisplayName } | Select-Object ComputerName, DisplayName, DisplayVersion, Publisher | Format-Table -AutoSize
  }
}

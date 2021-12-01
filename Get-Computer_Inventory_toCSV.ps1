<#
.Synopsis
   Script for gathering computer inventory information.
.DESCRIPTION
   Script for gathering Computer_Name, Serial_Number, Current_User, Manufacturer, Model, MAC_Address, Compliance_Status, IP_Address
   from computers in an Active Directory domain.
.EXAMPLE
   PS C:\Users\john.doe\Desktop> .\Get-Computer_Inventory_toCSV.ps1 COMPUTER_NAME
.EXAMPLE
   PS C:\Users\john.doe\Desktop> .\Get-Computer_Inventory_toCSV.ps1 .\Computers.txt
.INPUTS
   Input a list of computer names, either as an object or /n separated file.
.OUTPUTS
   This script exports a text file in column format, and as a CSV with headers.
   Format for output files is below:
   
   "./ComputerInfo_yyyymmdd_HHMM.csv"
   
   Computer_Name,Serial_Number,Current_User,Manufacturer,Model,MAC_Address,Compliance_Status,IP_Address
   Example-Comp1,2TK45784PJ,DOMAIN\jane.doe,HP,HP ProBook 650 G2,DE:AD:BE:EF:B5:BF,Patch KB4534276 Compliant,10.10.10.01
   Example-comp2,2TK34684GQ,DOMAIN\john.doe,HP,HP ProBook 650 G2,DE:AD:BE:AF:00:70,Patch KB4534276 Compliant,10.10.10.02

   "./ComputerInfo_yyyymmdd_HHMM.txt"
   _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
   IP Address   : 10.10.10.3
   1 IP addresses found on this system
   [+] Example-Comp3 | 2TK45784GP | DOMAIN\jose.gonzalez | Hewlett-Packard | HP ProDesk 600 G1
   _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
   IP Address   : 10.10.10.4
   1 IP addresses found on this system
   [+] Example-Comp4 | 2TK45784GH | DOMAIN\bob.barker | HP | HP ProBook 650 G4
.NOTES
  Authors: Beery, Christopher (https://github.com/zweilosec) & Winchester, Cassius (https://github.com/cassiuswinchester)
  Created: 6 Mar 2020
  Last Modified: 30 Nov 2021
.FUNCTIONALITY
   Computer inventory enumeration tool
#>

Param([string]$Computers)

If (!$Computers) {
    Write-Output "Please specify a input file with a list of computer names to search for."
    Write-Output "Format: Get-ComputerInventory.ps1 <filename_with_path>"
    }

$CSVLogFile = "./ComputerInfo_$(Get-Date -Format yyyymmdd_HHMM).csv"
$TXTLogFile = "./ComputerInfo_$(Get-Date -Format yyyymmdd_HHMM).txt"

Get-Content $Computers |
ForEach-Object {
    $Computer = $_
    Write-Output "_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _"
    If (Test-Connection -ComputerName $Computer -Count 2 -Quiet) {

        $Serial = Invoke-Command -ComputerName $Computer -ScriptBlock {
            Get-WmiObject -Class Win32_BIOS | Select -ExpandProperty SerialNumber
            }

        $CurrentUser = Invoke-Command -ComputerName $Computer -ScriptBlock {
            Get-WmiObject -Class Win32_ComputerSystem | Select -ExpandProperty UserName
            }
        
        $IPconfigset = Invoke-Command -ComputerName $Computer -ScriptBlock {
            Get-WmiObject -Class Win32_NetworkAdapterConfiguration
            }

        $Model = Invoke-Command -ComputerName $Computer -ScriptBlock {
            Get-WmiObject -Class Win32_ComputerSystem | Select -ExpandProperty Model
            }

        $Manufacturer = Invoke-Command -ComputerName $Computer -ScriptBlock {
            Get-WmiObject -Class Win32_ComputerSystem | Select -ExpandProperty Manufacturer
            }

	    $MACAddress = Invoke-Command -ComputerName $Computer -ScriptBlock {
	        Get-WmiObject -ClassName Win32_NetworkAdapterConfiguration -Filter "IPEnabled='True'" | 
	        Select -ExpandProperty MACAddress
	        }
        $Compliance = if (Get-HotFix -Id "KB4534276" -ComputerName $Computer -ErrorAction SilentlyContinue) { "Patch KB4534276 Compliant"} else { "Patch KB4534276 Non-compliant"}
            
  $IP = '0'
# Iterate and get IP address
$count = 0
foreach ($IPConfig in $IPConfigset) {
   if ($IPConfig.IPAddress) {
      foreach ($addr in $IPConfig.IPAddress) {
   "IP Address   : {0}" -f  $addr;
    $IP = $addr
   $count++ 
   }
   }
}
if ($count -eq 0) {"No IP addresses found"}
else {"$Count IP addresses found on this system"}

New-Object psobject -Property @{
                                             Computer_Name = $Computer
                                             Serial_Number = $Serial
                                             Current_User  = $CurrentUser
                                             Manufacturer = $Manufacturer
                                             Model = $Model
					     MAC_Address = $MACAddress
					     Compliance_Status = $Compliance
					     IP_Address = $IP
                                            
           } | Select Computer_Name,Serial_Number,Current_User,Manufacturer,Model,MAC_Address,Compliance_Status,IP_Address |
               Export-Csv -Append $CSVLogFile -NoTypeInformation

      
        Write-Output "$Computer | $Serial | $CurrentUser | $Manufacturer | $Model | $MACAddress | $Compliance | $IP"
    } Else { Write-Output "[x] Failed to ping $Computer." }
} | Tee -Append $TXTLogFile


<#
.Synopsis
   Script for gathering computer inventory information.
.DESCRIPTION
   Script for gathering ComputerName, Serial Number, Current User, Manufacturer, Model, MAC Address, Compliance Status, and IP Address from a list of computers.  
   An optional Microsoft patch KB name can be specified to check for update compliance.
.EXAMPLE
  Get-ComputerInventoryToCSV.ps1 -ComputerName Example-Comp1 -ComplianceKB KB4534276 -Verbose
.EXAMPLE
  Get-ComputerInventoryToCSV.ps1 .\Computers.txt
.EXAMPLE
  Get-ADComputer -Filter * -SearchBase "OU=TestOU,DC=TestDomain,DC=com" | Select -Property Name | Get-ComputerInventoryToCSV.ps1
.INPUTS
   -ComputerName <computer name>
   Input a list of computer names, either piped in as an object or a text file file with one computer name per line.

   -ComplianceKB <KB number>
   Input a single Microsoft KB number related to the specific patch you want to check compliance for.
.OUTPUTS
   This script exports a text file in column format, and as a CSV with headers.
   Format for output files is below:
   
   "./ComputerInfo_yyyymmdd_HHMM.csv"
   
   Computer_Name,Serial_Number,Current_User,Manufacturer,Model,MAC_Address,Compliance_Status,IP_Address
   Example-Comp1,2TK45784PJ,DOMAIN\jane.doe,HP,HP ProBook 650 G2,DE:AD:BE:EF:B5:BF,Patch KB4534276 Compliant,10.10.10.01
   Example-comp2,2TK34684GQ,DOMAIN\john.doe,HP,HP ProBook 650 G2,DE:AD:BE:AF:00:70,Patch KB4534276 Compliant,10.10.10.02

   "./ComputerInfo_yyyymmdd_HHMM.txt"
   [ ] - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - [ ]
   Realtek Gaming 2.5GbE Family Controller   : 10.10.10.3
   1 IP addresses found on this system
   [+] Example-Comp3 | 2TK43856ZP | DOMAIN\jose.gonzalez | Hewlett-Packard | HP ProDesk 600 G1
   [ ] - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - [ ]
   Realtek Gaming 2.5GbE Family Controller   : 10.10.10.4
   1 IP addresses found on this system
   [+] Example-Comp4 | 2TK82744ZH | DOMAIN\bob.barker | HP | HP ProBook 650 G4
.NOTES
  Authors: Beery, Christopher (https://github.com/zweilosec) & Winchester, Cassius (https://github.com/cassiuswinchester)
  Created: 6 Mar 2020
  Last Modified: 21 Jan 2022
.FUNCTIONALITY
   Computer inventory enumeration tool
#>

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
    $ComputerName, 

    #Specific patch to check for compliance. Use Microsoft's KB number.
    #Default is "None Specified"
    [string]
    $ComplianceKB = "None Specified"
)

#Check to make sure the user specified a ComputerName to scan, then print usage if not
#This check could be obviated if a default value of "$env:COMPUTERNAME" is used for $ComputerName above
Begin {
    If (!$ComputerName) 
    {
        Write-Host -ForegroundColor Yellow "Please specify a computername or an input file with a list of computer names to search for."
        "Syntax: {0} -ComputerName <Computer Name>" -f $MyInvocation.MyCommand.Name # $MyInvocation.MyCommand.Name is used to get the script's filename as run, in case it is renamed
        Write-Host "Try Get-Help {0} for more detailed help." -f $MyInvocation.MyCommand.Name
        Write-Host -ForegroundColor Yellow "Requires WinRM service to be running!"
        Break
    }

    $CSVLogFile = "./ComputerInventory_$(Get-Date -Format yyyyMMdd_HHmm).csv"
    $TXTLogFile = "./ComputerInventory_$(Get-Date -Format yyyyMMdd_HHmm).txt"
    [int]$ComputerCount = 0
    #Set the color of the -Verbose output messages
    $host.PrivateData.VerboseForegroundColor = "Cyan"
}

Process {
    Write-Verbose "Getting Serial Number, Current User, Manufacturer, Model, MAC Address, Compliance Status, and IP_Address for each ComputerName"

    foreach ($Computer in $ComputerName) 
    {
        Write-Output "[ ] - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - [ ]" | Tee-Object -Append $TXTLogFile
        Write-Verbose "Testing if $Computer is online..."

        If (Test-Connection -ComputerName $Computer -Count 2 -Quiet) 
        {

            Write-Verbose "[+] $Computer is online."
            #Add 1 to number of computers scanned
            $ComputerCount ++

            Write-Verbose "Beginning scan of $Computer"

            #Get Serial Number
            $Serial = Get-CimInstance -ComputerName $Computer -Class Win32_BIOS | 
            Select-Object -ExpandProperty SerialNumber

            #Get Current or last logged in username
            $CurrentUser = Get-CimInstance -ComputerName $Computer -Class Win32_ComputerSystem | 
            Select-Object -ExpandProperty UserName

            #Get list of network adapters
            $IPConfigSet = Get-CimInstance -ComputerName $Computer -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled='True'"

            #Get Model of the PC
            $Model = Get-CimInstance -ComputerName $Computer -Class Win32_ComputerSystem | 
            Select-Object -ExpandProperty Model

            #Get Manufacturer of the PC
            $Manufacturer = Get-CimInstance -ComputerName $Computer -Class Win32_ComputerSystem | 
            Select-Object -ExpandProperty Manufacturer

            #Get MAC address of the PC
            #This may need to be looked at further if using additional adapters; returns all MAC addresses, even virtual, but I'm only printing the first one in the output below
            #This was created and tested in an Ethernet-only environment.  If you use this in an environment where you have multiple adapters you need to track you may 
            #need to modify the properties of the object below and change or remove the array selection
            $MACAddress = $IPConfigSet.MACAddress

            #Check if user specified a patch to check for
            if ($ComplianceKB -ne "None Specified")
            {
                #Check if the specified patch has been installed
                $Compliance = if (Get-HotFix -Id "$ComplianceKB" -ComputerName $Computer -ErrorAction SilentlyContinue) 
                { 
                    Write-Output "Patch $ComplianceKB Compliant" | Tee-Object -Append $TXTLogFile
                } 
                else 
                { 
                    Write-Output "Patch $ComplianceKB Non-compliant" | Tee-Object -Append $TXTLogFile
                }
            }
            else 
            {
                $Compliance = "None Specified"
            }

            Write-Output "`tAdapter Information for $($Computer):" | Tee-Object -Append $TXTLogFile
            Write-Output "`t------------------------------------" | Tee-Object -Append $TXTLogFile
            [String[]]$IP = @()
            # Iterate and get IP addresses for each network interface
            $count = 0
            foreach ($IPConfig in $IPConfigSet) 
            {
                if ($IPConfig.IPAddress) 
                {
                    $AdapterName = $IPConfig.Description
                    foreach ($address in $IPConfig.IPAddress) 
                    {
                        Write-Output "`t$AdapterName  :  $address" | Tee-Object -Append $TXTLogFile
                        $IP += $address
                        $count++ 
                    }
                }
            }
            
            #Write how many IP addresses were found
            if ($count -eq 0) 
            {
                Write-Output "`tNo IP addresses found.`n" | Tee-Object -Append $TXTLogFile
            }
            else 
            {
                Write-Output "`t$Count IP addresses found on this system.`n" | Tee-Object -Append $TXTLogFile
            }

            Write-Verbose "Scan of $Computer complete."

            #Create a new generic object, assigning the variables from above as object Properties
            #This is needed to output to CSV with headers
            [PSCustomObject]@{
                Computer_Name = $Computer
                Serial_Number = $Serial
                Current_User  = $CurrentUser
                Manufacturer = $Manufacturer
                Model = $Model
                MAC_Address = $MACAddress[0] #Select only the first interface (Usually built-in Ethernet)
                Compliance_Status = $Compliance
                IP_Address = $IP[0] #Select only the first interface (Usually built-in Ethernet)
            } | 
            #Select the properties of the (unnamed) PSCustomObject and write to the CSV file.                                 
            Select-Object Computer_Name,Serial_Number,Current_User,Manufacturer,Model,MAC_Address,Compliance_Status,IP_Address |
            Export-Csv -Append $CSVLogFile -NoTypeInformation
        
            #Write the output to the console and text log in the following format
            Write-Output "[+] $Computer | $Serial | $CurrentUser | $Manufacturer | $Model | $($MACAddress[0]) | $Compliance | $($IP[0])" | Tee-Object -Append $TXTLogFile
        }
        
        #If unable to ping the computer this will be written to console and text log instead
        Else 
        { 
            Write-Output "[x] Failed to ping $Computer." | Tee-Object -Append $TXTLogFile
        }

    }

}

End 
{
    Write-Verbose "Scan complete."
    Write-Verbose "$ComputerCount computers were scanned."
    Write-Verbose "$CSVLogFile and $TXTLogFile files created."
}

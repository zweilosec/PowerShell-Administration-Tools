---
description: >-
  A collection of Windows PowerShell tools for making system administration and
  troubleshooting easier.
---

# PowerShell Administration Tools

PowerShell scripts for automating common system administration tasks.  Suggestions, submissions, updates, and requests are always welcome!

| Script Name | Description |
| :--- | :--- |
| [Clear-ExcessCertificates](https://github.com/zweilosec/PowerShell-Administration-Tools/blob/master/Clear-ExcessCertificates.ps1) | Clears all PIV certificates from the local store except for the current user's |
| [Create-ADUserFromCsv](https://github.com/zweilosec/PowerShell-Administration-Tools/blob/master/Create-ADUserFromCsv.ps1) | Batch creates users in Active Directory from a .csv file. |
| [Get-Computer\_Inventory](https://github.com/zweilosec/PowerShell-Administration-Tools/blob/master/Get-ComputerInventoryToCSV.ps1) | Searches a network for the computers specified \(by computer name\) and reports a list of inventory-related information for those computers.  IP, MAC, Make, Model, Serial, and Last User. Requires WinRM to be running on the system. Does not require admin rights. |
| [Get-Monitor\_Inventory](https://github.com/zweilosec/PowerShell-Administration-Tools/blob/master/Get-Monitor_Inventory.ps1) | Searches a domain for the computers specified \(by computer name\) and reports a list of inventory-related information for the attached Monitors. Make, Model, Serial |
| [Get-User\_Profile](https://github.com/zweilosec/PowerShell-Administration-Tools/blob/master/Get-User_Profile.ps1) | Searches a domain for the user ID specified.  Returns a list of all of the computers that user has signed into. |
| [Add-RemotePrinter](https://github.com/zweilosec/PowerShell-Administration-Tools/blob/master/Add-RemotePrinter.ps1) | Adds a printer to the computer specified \(by computer name\).  Requires some information such as printer IP, Driver long name, and the name you want the printer to be displayed as. |

## Network Tools
| Script Name | Description |
| :--- | :--- |
| [Get-OpenPortsWithProcess](https://github.com/zweilosec/PowerShell-Administration-Tools/blob/master/Network/Get-OpenPortsWithProcess.ps1) | A simple script for listing open TCP or UDP ports. <br>Has three options: <br>* `-TCP` : show TCP ports<br>* `-UDP` : show UDP ports<br>* `-Listening` :  Show only listening ports |
| [Renew-DHCP](https://github.com/zweilosec/PowerShell-Administration-Tools/blob/master/Network/Renew-DHCP.ps1) | Releases DHCP reservations for all active interfaces and renews them. Fully PowerShell equivilent to running `ipconfig /release; ipconfig /renew`. |
|[Scan-TCPPorts](https://github.com/zweilosec/PowerShell-Administration-Tools/blob/master/Network/Scan-TCPPorts.ps1) | A simple TCP port scanner. Takes in a comma separated list of IPs, and of ports. An output file (csv or txt) can be specified as well. |

## Snippets
Drop these snippets into your scripts to add this functionality. May need to modify variables to fit your use cases.

| Script Name | Description |
| :--- | :--- |
| [Run-ADPreChecks](https://github.com/zweilosec/PowerShell-Administration-Tools/blob/master/Snippets/Run-ADPreChecks.ps1) |Code snippet to do some preliminary checks to ensure a script will function<br>Checks for: administrator privileges, PowerShell v5 or greater, and the ActiveDirectory PowerShell modules |
| [Select-FileWithDialog](https://github.com/zweilosec/PowerShell-Administration-Tools/blob/master/Snippets/Select-FileWithDialog.ps1) | Code snippet to display an Explorer window to select a file (.csv and .txt in this example) |

#### More content from Zweilosec:

## [OSCP prep and CTF notes](https://zweilosec.gitbook.io/hackers-rest/)

  
If you like this content and would like to see more, please consider [buying me a coffee](https://www.buymeacoffee.com/zweilosec)!

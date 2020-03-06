Param([string]$Computers)

Get-Content $Computers |
ForEach-Object {
    $Computer = $_
    $s= New-PSSession -ComputerName $Computer -Credential <domain>\<username> #will prompt for credentials for each computer
    Invoke-Command -Session $s {Add-PrinterPort -name <port_name> -PrinterHostAddress <printer_ip>}
    Invoke-Command -Session $s {Add-PrinterDriver -Name "<full_name_of_driver>"}
    Invoke-Command -Session $s {Add-Printer -name "<windows_display_name>" -portname <port_name> -DriverName "<full_name_of_driver>"}
    Invoke-Command -Session $s {Write-Output "Printer Added Successfully."}
    Remove-PSSession -ComputerName $Computer
    }

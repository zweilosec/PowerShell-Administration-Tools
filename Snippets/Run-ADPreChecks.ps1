<#
.Description
   Code snippet to do some preliminary checks to ensure a script will function
   Checks for administrator privileges, PowerShell v5 or greater, and the ActiveDirectory PowerShell modules
   https://stackoverflow.com/questions/2022326/terminating-a-script-in-powershell
   
   Copy and paste into your PowerShell script to add this functionality.
#>

#region pre-check functions

function Test-Administrator()
{
    $identity= [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator ))
    {
        return $true
    }
    else
    {
        return $false
    }
}

function PreCheck()
{
    Write-Host "Checking Powershell Script Prerequisites...." -ForegroundColor Green
    Write-Host
    
    if($PSVersionTable.PSVersion -lt "5.0.0.0")
    {
        $ver = $PSVersionTable.PSVersion
        Write-Host "Powershell version check: Fail" -ForegroundColor Yellow
        Write-Host
        Write-Host "WARNING: THE VERSION OF POWERSHELL RUNNING ON THIS SYSTEM ($ver) IS NOT COMPATIBLE WITH THIS SCRIPT." -ForegroundColor red
        Write-Host "Please see https://www.microsoft.com/en-us/download/details.aspx?id=50395 to download Microsoft Management Framework 5 which includes Powershell Version 5." -ForegroundColor Yellow
        Write-Host
        Throw "Exiting pre-checks with error code 1 (PowerShell version >5 not detected.)."
        #Read-Host -Prompt "Press Ctrl-C to continue. ([Enter] will close the window!)"
        #Exit
    }
    else {Write-Host "Powershell Version 5 or higher: Good" -ForegroundColor Green}

    if(Get-Module -ListAvailable -Name ActiveDirectory){Write-Host "Powershell Active Directory Module: Installed" -ForegroundColor Green}
    else
    {
        Write-Host "Powershell Active Directory Module: Not Installed" -ForegroundColor Yellow
        Write-Host
        Write-Host "WARNING: THE POWERSHELL ACTIVE DIRECTORY MODULE IS NOT INSTALLED ON THIS SYSTEM. THIS SCRIPT WILL NOT FUNCTION CORRECTLY WITHOUT THIS MODULE." -ForegroundColor Red
        Write-Host "Please see https://technet.microsoft.com/en-us/library/dd378937 for how to install the Active Directory Module for Powershell." -ForegroundColor Yellow
        Write-Host
        Throw "Exiting pre-checks with error code 2 (ActiveDirectory module not installed)."
        #Read-Host -Prompt "Press Ctrl-C to continue. ([Enter] will close the window!)"
        #Exit
    }

    if(Test-Administrator -eq $true){Write-Host "Checking for Administrator Privileges: Good" -ForegroundColor Green}
    else
    {
        Write-Host "Administrator privilege check: Fail" -ForegroundColor Yellow
        Write-Host
        Write-Host "WARNING: THIS SCRIPT IS NOT BEING RUN AS AN ADMINISTRATOR. THIS SCRIPT WILL NOT FUNCTION WITHOUT ADMINISTRATIVE PRIVILEGES." -ForegroundColor Red
        Write-Host "The script will now exit. Please rerun as an administrator." -ForegroundColor Yellow
        Write-Host
        Throw "Exiting pre-checks with error code 3 (Script run without Administrator rights)."
        #Read-Host -Prompt "Press Ctrl-C to continue. ([Enter] will close the window!)"
        #Exit
    }
}

PreCheck
Write-Host "Pre-checks complete." -ForegroundColor Green
Write-Host

#endregion pre-check functions

<#
.Synopsis
   Creates users in Active Directory from a .csv file
.Description
   Batch creates users in Active Directory from a .csv file.  
   A properly formatted .csv file contains the following fields:

   LastName,Firstame,MiddleInitial,Rank,SAMAccountName,EmailAddress,Unit,Section,Position,Password,Groups

   Groups listed must be separated by a semicolon (;) e.g. Burn Rights;PowerShell Users;System Administrator

   Fills in the following fields in Active Directory:

   AccountExpirationDate,Enabled,EmailAddress,Name,DisplayName,UserPrincipalName,SamAccountName,GivenName,Surname,Path

   Author: Beery, Christopher
   Created: 18 Nov 2021
   Last modified: 19 Nov 2021
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
        Write-Host "The script will now exit. Please re-run as an administrator." -ForegroundColor Yellow
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

Import-Module ActiveDirectory

#region User-defined variables

#OU path in Active Directory. Specify the target OU. Format: OU=Users,DC=domain,DC=local
Write-Host "Enter the target OU (Example: OU=Users,DC=domain,DC=local)" -ForegroundColor Yellow
$OU = Read-Host "OU"

#Folder to start file selector in. currently set to the user's Desktop. Modify if needed.
$ImportPath = 'C:' + $env:HOMEPATH + '\' + 'Desktop'

#Filters files to only show ".csv", ".txt", or all files.  Change this as needed.
#Format is, with each selection separated by a pipe (|): DescriptionToShow|Filetype;Filetype
$fileFilter = "CSV (*.csv,*.txt)| *.csv;*.txt|Text Files (*.txt)|*.txt|All files (*.*)|*.*"

#endregion User-defined variables

Write-Host
Write-Host "This script creates users in Active Directory from a properly formatted .csv file." -ForegroundColor Yellow
Write-Host "Proper formatting is as below:" -ForegroundColor DarkYellow
Write-Host
Write-Host "LastName,Firstame,MiddleInitial,Rank,SAMAccountName,EmailAddress,Unit,Section,Position,Password,Groups" -ForegroundColor Green
Write-Host
Write-Host "Groups listed must be separated by a semicolon (;) e.g. Burn Rights;PowerShell Users;System Administrator" -ForegroundColor DarkGreen
Write-Host
Write-Host "Select the properly formatted .csv file you would like to create users from:" -ForegroundColor Yellow

#region Display Explorer window to select a .csv file

function Select-FileWithDialog
{
    #Starts the folder selector in the specified folder
    param([string]$Description="Select Folder",[string]$RootFolder=$ImportPath)

 [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null     

    $objForm = New-Object System.Windows.Forms.OpenFileDialog
        $objForm.InitialDirectory = $RootFolder
        
        #Filters files to only show files based on the variable set above.
        $objForm.filter = $fileFilter
        
        $objForm.ShowDialog() | Out-Null
        $objForm.FileName
}

#This variable contains the user's file selection
$file = Select-FileWithDialog

#endregion Display Explorer window to select a .csv file

#Import the lines in the .csv file into an array.  Set the delimiter and encoding as needed.
$Users = Import-Csv -Delimiter ';' -Path $file -Encoding UTF8

#region Import users into Active Directory
foreach ($User in $Users)  
{  
    #These fields must exist in the CSV, with headers.
    $SAMAccountName = $User.SAMAccountName
    $Lastame = $User.LastName
    $FirstName = $User.FirstName
    $DisplayName = $user.LastName + ", " + $User.FirstName + " " + $User.Rank + " " + $user.Unit + "/" + $user.Section + " - " + $user.Position
    $email = $User.EmailAddress
    $password = $User.Password
    [array]$groups=$User.Groups -split ';'

    #Not sure what this script argument is for, or if it is needed. Commenting out to see what happens.
    #$script = $SAMAccountName + '.bat'

    #Variables that may be useful for some.  The "description" field would need to be added to the CSV and "New-ADUser" line below as needed
    <#
    $upn = $User.FirstName + "." + $User.LastName + "@" + $domain
    $Description = $User.$Description
    $SAMAccountName = $User.FirstName + "." + $User.LastName
    #>

    $Name = $GivenName + ' ' + $Surname.ToUpper()
    $upn = ($SAMAccountName + '@' + $env:USERDNSDOMAIN).ToLower()
        
    #Create user in Active Directory with the following properties
    Write-Host "Creating account: $SAMAccountName" -ForegroundColor Green
    New-ADUser -AccountExpirationDate $null -Enabled $true -EmailAddress $email -Name $Name -DisplayName $DisplayName -UserPrincipalName $upn -SamAccountName $SAMAccountName -GivenName $FirstName -Surname $LastName -Path $OU -ChangePasswordAtLogon $true -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) #-ScriptPath $script
    
    #Add the new user to the groups listed in the Groups field
    foreach ($group in $groups)
    {
    Write-Host "Adding $SAMAccountName to the $group group." -ForegroundColor DarkGreen
    Add-ADGroupMember -Identity $group -Member $SAMAccountName
    }
}
 
Write-Host "User import complete." -ForegroundColor Yellow

#endregion Import users into Active Directory

#region Show MessageBox to confirm action

[Windows.Forms.MessageBox]::Show("User import complete.","System Dialog", 0, [Windows.Forms.MessageBoxIcon]::Information)

#endregion Show MessageBox to confirm action

<#
.Description
   This script clears all PIV certificates from the local store except for the current user's
   The current iteration of this script relies on the user to enter their name.
   There are ways to automate this, however current environment precludes this. 
   The easiest way would be to pull the current username from $env:username
   
   Created: 15 Nov 2021
   Last Modified: 19 Nov 2021
#>

#used to check the user's confirmation
$confirm = 'no'

#Prompts the user to enter their Last Name to be used to check against their PIV certificates
While($confirm -notin @('y', 'Y', 'Yes', 'YES','yes'))
{
#Prompts the user to enter their surname
Write-Host "Please enter your Last Name (as written in your PIV certificate)" -ForegroundColor Yellow
$name  = (Read-Host "Last Name" ).ToUpper()
Write-Host "You typed $name, is this correct?" -ForegroundColor DarkYellow
$confirm = (Read-Host "[Y/N]")
}

#List all certificates in the store and remove any that do not match the name entered
Get-ChildItem cert:\CurrentUser\my | Where-Object {$_.Subject -NotLike "*$name*" } | Remove-Item

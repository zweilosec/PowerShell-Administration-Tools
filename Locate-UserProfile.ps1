<#
.Synopsis
   Locates computers where a user has signed in.
.DESCRIPTION
   Script for gathering the machines that a user has signed into from a list of computers.
   Displays the Computer Name, User Home Folder, and Last Logged-in Time for each computer. 
   Each user specified will have a separate CSV log file created.
   Requires the WinRM service to be running, however does not require admin rights.
.EXAMPLE
   Locate-UserProfile.ps1 -ComputerName Example-Comp1 -UserName Zweilosec -Verbose
.EXAMPLE
   Locate-UserProfile.ps1 -UserName Zweilosec .\Computers.txt 
.EXAMPLE
   Get-ADComputer -Filter * -SearchBase "OU=TestOU,DC=TestDomain,DC=com" | Select -Property Name | Locate-UserProfile.ps1 -UserName Zweilosec
.INPUTS
   -UserName <username>
   Enter the username(s) you want to search for.  These must be the actual account name not the display name.

   -ComputerName <computer name>
   Input a list of computer names, either piped in as an object or a text file file with one computer name per line.
.OUTPUTS
   This script exports a report in table format, and as a CSV file with headers.
   Example output is below:

    Searching for user profile Zweilosec...

    User profile Zweilosec was found on 4 computers.


    PSComputerName LocalPath          LastUseTime
    -------------- ---------          -----------
    Zweildesk-1    C:\Users\Zweilosec 1/22/2022 14:08:08
    Zweildesk-2    C:\Users\Zweilosec 1/22/2022 14:08:08
    Zweildesk-3    C:\Users\Zweilosec 1/22/2022 14:08:28
    Zweildesk-4    C:\Users\Zweilosec 1/22/2022 14:08:28

.NOTES
   Author: Beery, Christopher (https://github.com/zweilosec)
   Created: 6 Mar 2020
   Last Modified: 22 Jan 2022
   Useful Links:
   * http://woshub.com/convert-sid-to-username-and-vice-versa
   * https://www.nextofwindows.com/how-to-get-the-list-of-user-profiles-on-your-computer
#>

[CmdletBinding()]
Param
(
    # The User Names to conduct a hunt for
    [Parameter(Mandatory=$true, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)] 
    [ValidateNotNull()]
    [ValidateNotNullOrEmpty()]
    [Alias("User","SAMAccountName")]
    [String[]]
    $UserName,

    # The list of computers to search
    [Parameter(Mandatory=$true, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true)]
    [Alias("Name")] #Needed to allow computers to be piped in as an attribute from Get-ADComputer
    [String[]]
    $ComputerName
)

Process
{
    Foreach ( $USER in $UserName )
    {
        #The CSV file to be used as a log is defined here
        $TimeStamp = (Get-Date).ToString('yyyy-MM-dd_HHmm')
        $CsvFile = "./$($User)-ProfileSearch_$($TimeStamp).csv"

        Write-Host "`nSearching for user profile $USER..."

        #These are the commands that will be run on each computer
        Foreach ( $Computer in $ComputerName ) 
        {
            #Get the user's SID because the Win32_UserProfile (for localpath) has no Name property
            $SID = (Get-CimInstance -ClassName Win32_UserAccount -ComputerName $Computer | 
            Where-Object Name -EQ "$USER").SID
            
            #Get the user's $Home directory
            #This method was used since we cannot assume the user's home folder is in C:\Users\
            $LocalPath = (Get-CimInstance -ClassName Win32_UserProfile | 
            Where-Object SID -EQ "$SID").LocalPath

            #Get the last time the user logged in
            $LastUseTime = (Get-CimInstance -ClassName Win32_UserProfile -ComputerName $Computer | 
            Where-Object LocalPath -EQ $LocalPath).LastUseTime

            #The results will be stored in a custom object with these three properties
            $UserProfile = [PSCustomObject]@{
                ComputerName = $Computer
                UserHome = $LocalPath
                LastUseTime = $LastUseTime
            }

            #If the User's home directory exists, then the user has signed in
            $ProfileFound = $UserProfile | Where-Object UserHome
            
            #Writes the results to a CSV file
            $ProfileFound | Select-Object ComputerName, UserHome, LastUseTime |
            Export-Csv -Path $CsvFile -Append -NoTypeInformation
        }

        if ($ProfileFound) 
        {
            #Read results from the CSV file
            $output = Import-Csv -Path $CsvFile
            #Count number of lines
            $ComputerCount = $output.Count
            #Write results to the terminal
            Write-Host "`nUser profile $USER was found on $ComputerCount computers.`n" -ForegroundColor Green
            Write-Output $output
        }
        else 
        {
            Write-Host "`nUser profile $USER was not found.`n" -ForegroundColor Red
        }
    }
}

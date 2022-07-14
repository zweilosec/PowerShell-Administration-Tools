function New-Shortcut
{
   <#
   .Synopsis
      Creates a Windows shortcut file (.lnk).
   .DESCRIPTION
      PowerShell script for creating Windows shortcut files (.lnk).  
   .EXAMPLE
      Locate-UserProfile.ps1 -ComputerName Example-Comp1 -UserName Zweilosec -Verbose
   .EXAMPLE
      Locate-UserProfile.ps1 -UserName Zweilosec .\Computers.txt 
   .EXAMPLE
      Get-ADComputer -Filter * -SearchBase "OU=TestOU,DC=TestDomain,DC=com" | Select -Property Name | Locate-UserProfile.ps1 -UserName Zweilosec
   .INPUTS
      -TargetPath <file_to_execute>
      The target to create the link to. Enter the full path (Ex: C:Windows\system32\notepad.exe)
      -OutputLnk <link_file>
      Enter path and name of the link file to create. (Ex: C:Windows\system32\notepad.lnk)
      -Arguments
      Any arguments to the file to be executed.  If TargetPath=PowerShell.exe (Ex: "-NoProfile -NonInteractive -File C:\Scripts\script.ps1")
      -WorkingDirectory
      Set Working Directory the target is to be run from.
      -IconLocation
      Location of the icon to be used for the shortcut.  Typically .ico, .exe, or .dll files contain icons (Ex: 'C:\windows\System32\SHELL32.dll,70')
      -WindowStyle <int>
      Determines whether the window will be minimized, maximized, or use the default from the registry
      7 = Minimized window
      3 = Maximized window
      1 =   Default window
      -Description
      Description of the target the shorcut should display
      -Hotkey
      A hotkey that can be pressed to launch this shortcut
      -Hidden
      An optional parameter that sets the shortcut file to be hidden, reducing unnecessary clicks
      -AsAdmin
      Sets the shortcut to run the target application as an Administrator (may require elevation)
   .OUTPUTS
      This script creates a .lnk file in the specified location
   .NOTES
      Author: Beery, Christopher (https://github.com/zweilosec)
      Created: 14 Jul 2022
      Last Modified: 14 Jul 2022
      Useful Study Links:
      * http://powershellblogger.com/2016/01/create-shortcuts-lnk-or-url-files-with-powershell/
      * https://docs.microsoft.com/en-us/powershell/scripting/samples/creating-.net-and-com-objects--new-object-?view=powershell-7.2
      * IconLocation = https://hull1.com/scriptit/2020/08/15/customize-shortcut-icon.html
      * https://v3ded.github.io/redteam/abusing-lnk-features-for-initial-access-and-persistence
      * https://docs.microsoft.com/en-us/windows/win32/shell/appids
   #>
   param (
      [Parameter(Mandatory=$true)]
      [ValidateNotNull()]
      [ValidateNotNullOrEmpty()]
      [String]     
      $TargetPath,

      [Parameter(Mandatory=$true)]
      [ValidateNotNull()]
      [ValidateNotNullOrEmpty()]
      [String]
      $OutputLink,

      [Parameter(Mandatory=$false)]
      [String]
      $Arguments = "",

      [Parameter(Mandatory=$false)]
      [String]
      $WorkingDirectory = "",
   
      [Parameter(Mandatory=$false)]
      [String]
      $IconLocation = "C:\windows\System32\SHELL32.dll,70", #default to blank text file icon (70)
      
      [Parameter(Mandatory=$false)]
      [Int]
      $WindowStyle = 7,
                     #7 = Minimized window
                     #3 = Maximized window
                     #1 = Normal    window
   
      [Parameter(Mandatory=$false)]
      [String]
      $Description = "A new shortcut",
   
      [Parameter(Mandatory=$false)]
      [String]
      $HotKey = "", #The syntax is: "{KeyModifier}+{KeyName}" ( e.g. "Ctrl+Alt+Q", "Shift+F2", etc. )
   
      [Parameter(Mandatory=$false)]
      [Switch]
      $Hidden = $False,
   
      [Parameter(Mandatory=$false)]
      [Switch]
      $AsAdmin = $False
   )

   $WshShell = New-Object -comObject WScript.Shell
   $Shortcut = $WshShell.CreateShortcut($OutputLink)

   $Shortcut.TargetPath = $TargetPath
   $Shortcut.Arguments = $Arguments
   $Shortcut.WorkingDirectory = $WorkingDirectory
   $ShortCut.IconLocation = $IconLocation
   $shortcut.WindowStyle = $WindowStyle
   $ShortCut.Description = $Description
   $ShortCut.Hotkey = $Hotkey

   $Shortcut.Save()

   if ($Hidden)
   {
      (Get-Item $OutputLink).Attributes += 'Hidden' # Optional if you want to make the link hidden (to prevent user clicks)
   }
   
   ### Below is the code to set shortcut to "Run As Administrator" (optional)
   If ($AsAdmin)
   {
      $bytes = [System.IO.File]::ReadAllBytes($OutputLink)
      $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) to on
      [System.IO.File]::WriteAllBytes($OutputLink, $bytes)
   }
}

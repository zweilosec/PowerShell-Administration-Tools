#region functions

function New-IsoFile 
{  
  <#  
   .Synopsis  
    Creates a new .iso file  
   .Description  
    The New-IsoFile cmdlet creates a new .iso file containing content from chosen folders  
   .Example  
    New-IsoFile "c:\tools","c:Downloads\utils"  
    This command creates a .iso file in $env:temp folder (default location) that contains c:\tools and c:\downloads\utils folders. The folders themselves are included at the root of the .iso image.  
   .Example 
    New-IsoFile -FromClipboard -Verbose 
    Before running this command, select and copy (Ctrl-C) files/folders in Explorer first.  
   .Example  
    dir c:\WinPE | New-IsoFile -Path c:\temp\WinPE.iso -BootFile "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\efisys.bin" -Media DVDPLUSR -Title "WinPE" 
    This command creates a bootable .iso file containing the content from c:\WinPE folder, but the folder itself isn't included. Boot file etfsboot.com can be found in Windows ADK. Refer to IMAPI_MEDIA_PHYSICAL_TYPE enumeration for possible media types: http://msdn.microsoft.com/en-us/library/windows/desktop/aa366217(v=vs.85).aspx  
   .Notes 
    NAME:  New-IsoFile  
    AUTHOR: Chris Wu 
    LASTEDIT: 03/23/2016 14:46:50  
 #>
 
  [CmdletBinding(DefaultParameterSetName='Source')]Param( 
    [parameter(Position=1,Mandatory=$true,ValueFromPipeline=$true, ParameterSetName='Source')]$Source,  
    [parameter(Position=2)][string]$Path = "$Title.iso",  
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})][string]$BootFile = $null, 
    [ValidateSet('CDR','CDRW','DVDRAM','DVDPLUSR','DVDPLUSRW','DVDPLUSR_DUALLAYER','DVDDASHR','DVDDASHRW','DVDDASHR_DUALLAYER','DISK','DVDPLUSRW_DUALLAYER','BDR','BDRE')][string] $Media = 'DVDPLUSRW_DUALLAYER', 
    [string]$Title = (Get-Date).ToString("yyyyMMdd-HHmmss.ffff"),  
    [switch]$Force, 
    [parameter(ParameterSetName='Clipboard')][switch]$FromClipboard 
  ) 
  
  Begin {  
    ($cp = new-object System.CodeDom.Compiler.CompilerParameters).CompilerOptions = '/unsafe' 
    if (!('ISOFile' -as [type])) {  
      Add-Type -CompilerParameters $cp -TypeDefinition @'
public class ISOFile  
{ 
  public unsafe static void Create(string Path, object Stream, int BlockSize, int TotalBlocks)  
  {  
    int bytes = 0;  
    byte[] buf = new byte[BlockSize];  
    var ptr = (System.IntPtr)(&bytes);  
    var o = System.IO.File.OpenWrite(Path);  
    var i = Stream as System.Runtime.InteropServices.ComTypes.IStream;  
   
    if (o != null) { 
      while (TotalBlocks-- > 0) {  
        i.Read(buf, BlockSize, ptr); o.Write(buf, 0, bytes);  
      }  
      o.Flush(); o.Close();  
    } 
  } 
}  
'@  
    } 
   
    if ($BootFile) { 
      if('BDR','BDRE' -contains $Media) { Write-Warning "Bootable image doesn't seem to work with media type $Media" } 
      ($Stream = New-Object -ComObject ADODB.Stream -Property @{Type=1}).Open()  # adFileTypeBinary 
      $Stream.LoadFromFile((Get-Item -LiteralPath $BootFile).Fullname) 
      ($Boot = New-Object -ComObject IMAPI2FS.BootOptions).AssignBootImage($Stream) 
    } 
  
    $MediaType = @('UNKNOWN','CDROM','CDR','CDRW','DVDROM','DVDRAM','DVDPLUSR','DVDPLUSRW','DVDPLUSR_DUALLAYER','DVDDASHR','DVDDASHRW','DVDDASHR_DUALLAYER','DISK','DVDPLUSRW_DUALLAYER','HDDVDROM','HDDVDR','HDDVDRAM','BDROM','BDR','BDRE') 
  
    Write-Verbose -Message "Selected media type is $Media with value $($MediaType.IndexOf($Media))"
    ($Image = New-Object -com IMAPI2FS.MsftFileSystemImage -Property @{VolumeName=$Title}).ChooseImageDefaultsForMediaType($MediaType.IndexOf($Media)) 
   
    if (!($Target = New-Item -Path $Path -ItemType File -Force:$Force -ErrorAction SilentlyContinue)) { Write-Error -Message "Cannot create file $Path. Use -Force parameter to overwrite if the target file already exists."; break } 
  }  
  
  Process { 
    if($FromClipboard) { 
      if($PSVersionTable.PSVersion.Major -lt 5) { Write-Error -Message 'The -FromClipboard parameter is only supported on PowerShell v5 or higher'; break } 
      $Source = Get-Clipboard -Format FileDropList 
    } 
  
    foreach($item in (Get-ChildItem -Path $Source -Force)) { 
      if($item -isnot [System.IO.FileInfo] -and $item -isnot [System.IO.DirectoryInfo]) { 
        $item = Get-Item -LiteralPath $item
      } 
  
      if($item) { 
        Write-Verbose -Message "Adding item to the target image: $($item.FullName)"
        try { $Image.Root.AddTree($item.FullName, $true) } catch { Write-Error -Message ($_.Exception.Message.Trim() + ' Try a different media type.') } 
      } 
    } 
  } 
  
  End {  
    if ($Boot) { $Image.BootImageOptions=$Boot }  
    $Result = $Image.CreateResultImage()  
    [ISOFile]::Create($Target.FullName,$Result.ImageStream,$Result.BlockSize,$Result.TotalBlocks) 
    Write-Verbose -Message "Target image ($($Target.FullName)) has been created"
    $Target
  } 
} 

function New-Shortcut
{
   <#
   .Synopsis
      Creates a Windows shortcut file (.lnk).
   .DESCRIPTION
      PowerShell script for creating Windows shortcut files (.lnk).  
   .EXAMPLE
      New-Shortcut -TargetPath C:\Windows\notepad.exe -OutputLink $env:userprofile\Desktop\notepad.lnk
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
      Last Modified: 15 Jul 2022
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
      $IconLocation = "$TargetPath,0", #"C:\windows\System32\SHELL32.dll,70", default to targets icon, shell32(70) is text file icon
      
      [Parameter(Mandatory=$false)]
      [Int]
      $WindowStyle = 7,
                     #7 = Minimized window
                     #3 = Maximized window
                     #1 = Normal    window
   
      [Parameter(Mandatory=$false)]
      [String]
      $Description = "Shortcut to $TargetPath",
   
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

   <#
   if ($(Test-Path $OutputLink)) #If the .lnk already exists
   {
      Write-Output "The target link already exists."
      $DeleteLink = Read-Host "Delete the existing link? [y/n]: "
      if ($DeleteLink.ToLower() -eq 'y')
      {
         Remove-Item $OutputLink
      }
   }
   #>
   $Shortcut.Save()

   # Optional if you want to make the link hidden (to prevent user clicks)
   if ($Hidden)
   {
      If ((Get-ItemProperty $OutputLink) -and [System.IO.FileAttributes]::Hidden)
      {
         #Write-Output "The file is hidden already"
         break
      }
      (Get-Item $OutputLink).Attributes += 'Hidden' 
   }
   
   # Below is the code to set shortcut to "Run As Administrator" (optional)
   If ($AsAdmin)
   {
      $bytes = [System.IO.File]::ReadAllBytes($OutputLink)
      $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) to on
      [System.IO.File]::WriteAllBytes($OutputLink, $bytes)
   }
}

function Set-IsoFileAutostart {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [String]$InputIsoPath,
        [Parameter(Mandatory=$false)]
        [String]$AutostartFile
    )

    # Create the autostart.inf file in the correct format
    $autostartInf = "[autostart]"
    if ($AutostartFile) {
        $autostartInf += "`nopen=$AutostartFile"
    }

    # Save the autostart.inf file to the specified path
    $autostartInf | Out-File -FilePath "$InputIsoPath\autostart.inf"
}

#end-region functions

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "ISO Creator"
$form.Size = New-Object System.Drawing.Size(600, 400)

#Change the Font for the headers to bold

$LabelFont = [System.Drawing.Font]::new("Microsoft Sans Serif", 12, [System.Drawing.FontStyle]::Bold)

# Create a label for the ISO section
$ISOLabel = New-Object System.Windows.Forms.Label
$ISOLabel.Location = New-Object System.Drawing.Point(10, 20)
$ISOLabel.Size = New-Object System.Drawing.Size(100, 20)
$ISOLabel.Text = "Create ISO"
$ISOLabel.Font = $LabelFont
$form.Controls.Add($ISOLabel)

# Create a label for the input path
$inputLabel = New-Object System.Windows.Forms.Label
$inputLabel.Location = New-Object System.Drawing.Point(10, 50)
$inputLabel.Size = New-Object System.Drawing.Size(100, 20)
$inputLabel.Text = "Input Path:"
$form.Controls.Add($inputLabel)

# Create a text box for the input path
$inputTextBox = New-Object System.Windows.Forms.TextBox
$inputTextBox.Location = New-Object System.Drawing.Point(110, 50)
$inputTextBox.Size = New-Object System.Drawing.Size(470, 20)
$form.Controls.Add($inputTextBox)

# Create a label for the output path
$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Location = New-Object System.Drawing.Point(10, 80)
$outputLabel.Size = New-Object System.Drawing.Size(100, 20)
$outputLabel.Text = "Output Path:"
$form.Controls.Add($outputLabel)

# Create a text box for the output path
$outputTextBox = New-Object System.Windows.Forms.TextBox
$outputTextBox.Location = New-Object System.Drawing.Point(110, 80)
$outputTextBox.Size = New-Object System.Drawing.Size(470, 20)
$form.Controls.Add($outputTextBox)

# Create a label for the volume label
$volumeLabelLabel = New-Object System.Windows.Forms.Label
$volumeLabelLabel.Location = New-Object System.Drawing.Point(10, 110)
$volumeLabelLabel.Size = New-Object System.Drawing.Size(100, 20)
$volumeLabelLabel.Text = "Volume Label:"
$form.Controls.Add($volumeLabelLabel)

# Create a text box for the volume label
$volumeLabelTextBox = New-Object System.Windows.Forms.TextBox
$volumeLabelTextBox.Location = New-Object System.Drawing.Point(110, 110)
$volumeLabelTextBox.Size = New-Object System.Drawing.Size(470, 20)
$form.Controls.Add($volumeLabelTextBox)


# Create a label for the link section
$lnkLabel = New-Object System.Windows.Forms.Label
$lnkLabel.Location = New-Object System.Drawing.Point(10, 170)
$lnkLabel.Size = New-Object System.Drawing.Size(100,20)
$lnkLabel.Text = "Create Link"
$lnkLabel.Font = $LabelFont
$form.Controls.Add($lnkLabel)

# Create a label for the .lnk file path
$lnkPathLabel = New-Object System.Windows.Forms.Label
$lnkPathLabel.Location = New-Object System.Drawing.Point(10, 200)
$lnkPathLabel.Size = New-Object System.Drawing.Size(100, 20)
$lnkPathLabel.Text = ".lnk Path:"
$form.Controls.Add($lnkPathLabel)

# Create a text box for the .lnk file path
$lnkPathTextBox = New-Object System.Windows.Forms.TextBox
$lnkPathTextBox.Location = New-Object System.Drawing.Point(110, 200)
$lnkPathTextBox.Size = New-Object System.Drawing.Size(470, 20)
$form.Controls.Add($lnkPathTextBox)

# Create a label for the .lnk file description
$lnkDescriptionLabel = New-Object System.Windows.Forms.Label
$lnkDescriptionLabel.Location = New-Object System.Drawing.Point(10, 230)
$lnkDescriptionLabel.Size = New-Object System.Drawing.Size(100, 20)
$lnkDescriptionLabel.Text = ".lnk Description:"
$form.Controls.Add($lnkDescriptionLabel)

# Create a text box for the .lnk file description
$lnkDescriptionTextBox = New-Object System.Windows.Forms.TextBox
$lnkDescriptionTextBox.Location = New-Object System.Drawing.Point(110, 230)
$lnkDescriptionTextBox.Size = New-Object System.Drawing.Size(470, 20)
$form.Controls.Add($lnkDescriptionTextBox)

# Create a label for the .lnk file target
$lnkTargetLabel = New-Object System.Windows.Forms.Label
$lnkTargetLabel.Location = New-Object System.Drawing.Point(10, 260)
$lnkTargetLabel.Size = New-Object System.Drawing.Size(100, 20)
$lnkTargetLabel.Text = ".lnk Target:"
$form.Controls.Add($lnkTargetLabel)

# Create a text box for the .lnk file target
$lnkTargetTextBox = New-Object System.Windows.Forms.TextBox
$lnkTargetTextBox.Location = New-Object System.Drawing.Point(110, 260)
$lnkTargetTextBox.Size = New-Object System.Drawing.Size(470, 20)
$form.Controls.Add($lnkTargetTextBox)

# Create a button to create the ISO file
$createIsoButton = New-Object System.Windows.Forms.Button
$createIsoButton.Location = New-Object System.Drawing.Point(10, 140)
$createIsoButton.Size = New-Object System.Drawing.Size(100, 25)
$createIsoButton.Text = "Create ISO"
$createIsoButton.Add_Click({
    # Get the input and output paths and volume label from the form
    $Source = $inputTextBox.Text
    $Path = $outputTextBox.Text
    $Title = $volumeLabelTextBox.Text

    # Create the ISO file
    New-IsoFile -Source $Source -Path $Path -Title $Title -Force
    $returnStatus.Text = ""

    # file write success
    if ($(Test-Path $Path)){
    Write-Host -ForegroundColor Green "ISO creation success"
    $returnStatus.BackColor = "Transparent"
    $returnStatus.ForeColor = "lime"
    $returnStatus.Text = "ISO creation success"
    }
    Else{
    # file write non success
    Write-Host -ForegroundColor Red "ISO creation failed"
    $returnStatus.ForeColor= "Red"
    $returnStatus.Text = "ISO creation failed"
    }
})
$form.Controls.Add($createIsoButton)

# Create a button to create the .lnk file
$createLnkButton = New-Object System.Windows.Forms.Button
$createLnkButton.Location = New-Object System.Drawing.Point(10, 290)
$createLnkButton.Size = New-Object System.Drawing.Size(100, 25)
$createLnkButton.Text = "Create .lnk"
$createLnkButton.Add_Click({
    # Get the path, description, and target from the form
    $OutputLink = $lnkPathTextBox.Text
    $description = $lnkDescriptionTextBox.Text
    $targetPath = $lnkTargetTextBox.Text

    # Create the .lnk file
    New-Shortcut -OutputLink $OutputLink -Description $description -TargetPath $targetPath
    $returnStatus.Text = ""

    # file write success
    if ($(Test-Path $OutputLink)){
    Write-Host -ForegroundColor Green "Link creation success"
    $returnStatus.BackColor = "Transparent"
    $returnStatus.ForeColor = "lime"
    $returnStatus.Text = "Link creation success"
    }
    Else{
    # file write non success
    Write-Host -ForegroundColor Red "Link creation failed"
    $returnStatus.ForeColor= "Red"
    $returnStatus.Text = "Link creation failed"
    }
})
$form.Controls.Add($createLnkButton)

# Create a button to add the .lnk file to the ISO file and set it as the autostart file
$setAutostartButton = New-Object System.Windows.Forms.Button
$setAutostartButton.Location = New-Object System.Drawing.Point(230, 290)
$setAutostartButton.Size = New-Object System.Drawing.Size(150, 25)
$setAutostartButton.Text = "Set .lnk as Autostart"
$setAutostartButton.Add_Click({
    # Get the input ISO path and autostart file from the form
    $inputIsoPath = $inputTextBox.Text
    $autostartFile = Split-Path -Path $lnkPathTextBox.Text -Leaf

    # Set the .lnk file as the autostart file for the ISO file
    Set-IsoFileAutostart -InputIsoPath $inputIsoPath -AutostartFile $autostartFile
    
    $returnStatus.Text = ""

    # file write success
    if ($(Test-Path "$inputIsoPath/autostart.inf")){
    Write-Host -ForegroundColor Green "inf creation success"
    $returnStatus.BackColor = "Transparent"
    $returnStatus.ForeColor = "lime"
    $returnStatus.Text = "inf creation success"
    }
    Else{
    # file write non success
    Write-Host -ForegroundColor Red "inf creation failed"
    $returnStatus.ForeColor= "Red"
    $returnStatus.Text = "inf creation failed"
    }
})
$form.Controls.Add($setAutostartButton)

#missing code here

#The missing code needed is a button to close the form. 
# Create a button to close the form
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Location = New-Object System.Drawing.Point(420, 330)
$closeButton.Size = New-Object System.Drawing.Size(150, 25)
$closeButton.Text = "Close"
$closeButton.Add_Click({
    $form.Close()
})
$form.Controls.Add($closeButton)

# return status
$returnStatus = New-Object System.Windows.Forms.label
$returnStatus.Location = New-Object System.Drawing.Point(10,330)
$returnStatus.Size = New-Object System.Drawing.Size(130,30)
$returnStatus.Text = "Standby..."
$form.Controls.Add($returnStatus)
 
$form.ShowDialog()

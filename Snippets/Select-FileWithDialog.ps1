#Code snippet to display an Explorer window to select a file (.csv in this example)
#Copy and paste into your PowerShell script to add this functionality. Modify variables as needed

#region User-defined variables

#Folder to start file selector in. currently set to the user's Desktop. Modify if needed.
$ImportPath = 'C:' + $env:HOMEPATH + '\' + 'Desktop'

#Filters files to only show ".csv", ".txt", or all files.  Change this as needed.
#Format is (with each selection option separated by a pipe (|)): DescriptionToShow|Filetype;Filetype
$fileFilter = "CSV (*.csv,*.txt)|*.csv;*.txt|Text Files (*.txt)|*.txt|All files (*.*)|*.*"

#endregion User-defined variables

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

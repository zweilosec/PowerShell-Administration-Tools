function EnterUSER_ID {

    do {

        Clear-Host

        $USER_ID = Read-Host "`nEnter USER_ID, including PCC code. Example: 1234567890A"
        
    } until ($USER_ID)

    Clear-Host

    Write-Host "`n$USER_ID" -ForegroundColor Green

    $Title = "Is above USER_ID correct?"
    $Prompt = $null
    $Choices = [System.Management.Automation.Host.ChoiceDescription[]] @("&Yes", "&No")
    $Default = 1
    $Choice = $host.UI.PromptForChoice($Title, $Prompt, $Choices, $Default)

    switch($Choice) {
        
        0 {SearchUSER_ID}
        1 {EnterUSER_ID}
    }
}



function SearchUSER_ID {

    Clear-Host

    Write-Host "`nPress Enter to select text file containing computer names.`n"

    Pause

    Add-Type -AssemblyName System.Windows.Forms 
    [System.Windows.Forms.Application]::EnableVisualStyles()                                       
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ InitialDirectory = [Environment]::GetFolderPath('Desktop') }
    $null = $FileBrowser.ShowDialog()
    $TextFile = $FileBrowser.FileName

    if ($TextFile) {

        $ComputerList = Get-Content -Path $TextFile
        $TimeStamp = (Get-Date).ToString('yyyy-MM-dd_-_HH-mm-ss')
        $CsvFile = "$env:USERPROFILE\Desktop\Search-Profile_$($TimeStamp).csv"

        Clear-Host

        Write-Host "`nSearching for user profile $USER_ID..."

        $InvokeCommandScriptBlock = {

            $LocalPath = (Get-CimInstance -ClassName Win32_UserProfile | 
            Where-Object LocalPath -EQ "C:\Users\$Using:USER_ID").LocalPath

            $LastUseTime = (Get-CimInstance -ClassName Win32_UserProfile | 
            Where-Object LocalPath -EQ "C:\Users\$Using:USER_ID").LastUseTime

            [PSCustomObject]@{

                LocalPath = $LocalPath
                LastUseTime = $LastUseTime
            }
        }

        $InvokeCommandParams = @{
            ComputerName = $ComputerList
            ScriptBlock = $InvokeCommandScriptBlock
            ErrorAction = 'SilentlyContinue'
        }

        $Results = Invoke-Command @InvokeCommandParams

        $ProfileFound = $Results | Where-Object LocalPath

        if ($ProfileFound) {

            $Count = $ProfileFound.Count

            Clear-Host

            Write-Host "`nUser profile $USER_ID was found on $Count computers. Press Enter to view results.`n" -ForegroundColor Green

            Pause

            $ProfileFound | Select-Object PSComputerName, LocalPath, LastUseTime |
            Export-Csv -Path $CsvFile -NoTypeInformation

            Invoke-Item -Path $CsvFile
        }
        else {

            Clear-Host

            Write-Host "`nUser profile $USER_ID was not found.`n" -ForegroundColor Red

            Pause
        }
    }
    else {Exit}
}

EnterUSER_ID

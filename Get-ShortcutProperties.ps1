function Get-ShortcutProperties 
{
    <#
    .SYNOPSIS
        Get information about a Shortcut (.lnk file)
    .DESCRIPTION
        Get information about a Shortcut (.lnk file)
    .PARAMETER Path
        Path to the .lnk file to be analyzed
    .EXAMPLE
        Get-Shortcut -Path 'C:\C:\Users\test\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\note.lnk'
    .OUTPUTS        
        TargetPath   : C:\Windows\notepad.exe
        Target       : notepad.exe
        Arguments    : Startup.txt
        LinkName     : note.lnk
        LinkPath     : C:\Users\test\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup
        WindowStyle  : Minimized (7)
        IconLocation : C:\windows\notepad.exe,0
        Description  : Create a new textfile on startup
        Attributes   : -a-h-
        Hotkey       :
    .NOTES
        Author: Beery, Christopher (https://github.com/zweilosec)
        Created: 15 Jul 2022
        Last Modified: 15 Jul 2022
    #>
    
        [CmdletBinding()]
        param
        (
            [string] 
            $Path
        )
    
        begin 
        {
            Write-Verbose -Message "Starting [$($MyInvocation.Mycommand)]"
            $obj = New-Object -ComObject WScript.Shell
        }
    
        process 
        {
            if (Test-Path -Path $Path) {
                $ResolveFile = Resolve-Path -Path $Path
                if ($ResolveFile.count -gt 1) 
                {
                    Write-Error -Message "ERROR: [$Path] resolves to more than 1 file."
                } 
                else 
                {
                    Write-Verbose -Message "Getting details for $Path."

                    $ResolveFile = Get-Item -Path $ResolveFile -Force
                    if ($ResolveFile.Extension -eq '.lnk') 
                    {
                        $link = $obj.CreateShortcut($ResolveFile.FullName)
  
                        $info = [PSCustomObject]@{
                            
                            TargetPath = $link.TargetPath
                            Target = $(try {Split-Path -Path $link.TargetPath -Leaf } catch { '' })
                            Arguments = $link.Arguments                            
                            LinkName = $(try { Split-Path -Path $link.FullName -Leaf } catch { '' })
                            LinkPath = $(try { Split-Path -Path $link.FullName } catch { '' })
                            WindowStyle = $link.WindowStyle
                            IconLocation = $link.IconLocation
                            Description = $link.Description
                            Attributes = $((Get-ItemProperty $Path).Mode)                            
                            Hotkey = $link.Hotkey
                        }

                        #Convert WindowStyle integer to descriptive name
                        Switch ($link.WindowStyle)
                        {
                            7 {$info.WindowStyle = "Minimized (7)"}
                            3 {$info.WindowStyle = "Maximized (3)"}
                            1 {$info.WindowStyle = "Default (1)"}
                        }

                        Write-Output $info
                    } 
                    else 
                    {
                        Write-Error -Message 'ERROR: Extension is not .lnk'
                    }
                }
            } 
            else 
            {
                Write-Error -Message "ERROR: File [$Path] does not exist"
            }
        }
    
        end 
        {
            Write-Verbose -Message "[$($MyInvocation.Mycommand)] evaluation complete"
        }
    }

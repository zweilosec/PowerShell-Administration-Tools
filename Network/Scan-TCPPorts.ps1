<#
Simple TCP Port scanner.

Takes in a comma separated list of IPs, and of ports. An output file can be specified as well.
Usage: Scan-TCPPorts <hosts> <ports> -outfile <file_name>

Outputs results to a csv file with IP,Protocol,Port,Result headers.

Author: Beery, Christopher
Created: 19 Nov 2021
Last Modified: 20 Nov 2021
#>

Function Scan-TCPPorts 
{
  #The function takes in two mandatory arguments $hosts and $ports, and one optional $out_file
  param([array]$hosts,[array]$ports,[string]$out_file = ".\scanresults.csv")
  
  #If no ports are specified
  if (!$ports) 
  {
    Write-Host "Usage  : Scan-TCPPorts <hosts> <ports> -outfile <file_name>" -ForegroundColor Yellow
    Write-Host "Example: Scan-TCPPorts 192.168.1.2,192.168.1.3 80,445" -ForegroundColor Green
    Write-Host
    return
  }

  #Not working now that csv is formatted properly
  #Write-Host "Checking the output file for previous results. Skipping previously scanned host/port combinations"
  Write-Host
  Write-Host "Beginning scan at $(Get-Date)" -ForegroundColor Magenta
  Write-Host
  
  foreach($port in $ports) 
  {
   foreach($ip in $hosts) 
   {
    #Check for existance of results in output file.  Not working now that csv is formatted properly.
    <#
    $x = (Get-Content $out_file -EA SilentlyContinue | Select-String '"$ip","TCP","$port"')
    if ($x) {
      Get-Content $out_file | Select-String '"$ip","TCP","$port"'
      continue
    }
    #>
    
    #A custom object had to be created in order to get Export-CSV to work properly
    $msg = New-Object PsObject
    $msg | Add-Member -MemberType NoteProperty -Name "IP" -Value $ip
    $msg | Add-Member -MemberType NoteProperty -Name "Protocol" -Value "TCP"
    $msg | Add-Member -MemberType NoteProperty -Name "Port" -Value $port

    $tcpClient = new-Object system.Net.Sockets.TcpClient
    $connection = $tcpClient.ConnectAsync($ip,$port)
    
    for($i=0; $i -lt 10; $i++) 
    {
      if ($connection.isCompleted) { break; }
      sleep -milliseconds 100
    }
    
    $result = "Filtered"
    
    if ($connection.isFaulted -and $connection.Exception -match "actively refused") 
    {
      $result = "Closed"
      Write-Host $ip "$port (Closed)" -ForegroundColor Red -Separator " ==> "
    } 
    elseif ($connection.Status -eq "RanToCompletion") 
    {
      $result = "Open"
      Write-Host $ip "$port (Open)" -ForegroundColor Green -Separator " ==> "
    }
    else
    {
    Write-Host $ip "$port (Filtered)" -ForegroundColor Yellow -Separator " ==> "
    }

    $tcpClient.Close();
    $msg | Add-Member -MemberType NoteProperty -Name "Result" -Value $result

    #Append $out_file with four columns: IP,Protocol,Port,Result
    $msg | Select -Property IP,Protocol,Port,Result | Export-Csv -Append -Path $out_file -NoTypeInformation -Force

   }
  }
  Write-Host
  Write-Host "Scan finished at $(Get-Date)" -ForegroundColor Magenta
}

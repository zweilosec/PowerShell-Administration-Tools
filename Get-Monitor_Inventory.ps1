<#
      .SYNOPSIS
      Srcipt for gathering inventory information about the monitors attached to networked computers. 
      .DESCRIPTION
      This script takes in a list of computer names, and for each computer retrieves a list of monitors.
      If this value is not specified it pulls the monitors of the computer that the script is being run on.
      It gathers SerialNumber, Manufacturer, and Model for each monitor saves it to a CSV file.
      .PARAMETER ComputerName
      Use this to specify the computer(s) which you'd like to retrieve information about monitors from.
      .EXAMPLE
      PS C:/> Get-Monitor.ps1 -ComputerName TestName
      Manufacturer Model    	SerialNumber AttachedComputer
      ------------ -----    	------------ ----------------
      HP           HP Zbook 17 G5 8675309    TestName 
      HP           HP Zbook 17 G5 8675309    TestName 
      HP           HP Zbook 17 G5 8675309    TestName
      .EXAMPLE
      PS C:/> $Computers = @("TestName1","TestName2","TestName3")
      PS C:/> Get-Monitor.ps1 -ComputerName $Computers
      Manufacturer Model      	SerialNumber AttachedComputer
      ------------ -----      	------------ ----------------
      HP           HP Zbook 17 G5   8675310   TestName1
      HP           HP Zbook 17 G5   8675310   TestName1 
      HP           HP Zbook 17 G5   8675311   TestName2 
      HP           HP Zbook 17 G5   8675311   TestName2
      HP           HP Zbook 17 G5   8675312   TestName3
      .INPUTS
      Input a list of computer names, either individually, as an object, or '/n' separated file.
      .OUTPUTS
      Outputs a CSV with headers. Naming convention for output files is "./MonitorInfo_yyyymmdd_HHMM.csv".
      .FUNCTIONALITY
      Computer monitor inventory enumeration tool
  #>


  [CmdletBinding()]
  PARAM (
    [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [String[]]$ComputerName = $env:ComputerName
  )
  
  #List of Manufacture Codes that could be pulled from WMI and their respective full names. Used for readable output.
  $ManufacturerHash = @{ 
    "AAC" =	"AcerView";
    "ACR" = "Acer";
    "AOC" = "AOC";
    "AIC" = "AG Neovo";
    "APP" = "Apple Computer";
    "AST" = "AST Research";
    "AUO" = "Asus";
    "BNQ" = "BenQ";
    "CMO" = "Acer";
    "CPL" = "Compal";
    "CPQ" = "Compaq";
    "CPT" = "Chunghwa Pciture Tubes, Ltd.";
    "CTX" = "CTX";
    "DEC" = "DEC";
    "DEL" = "Dell";
    "DPC" = "Delta";
    "DWE" = "Daewoo";
    "EIZ" = "EIZO";
    "ELS" = "ELSA";
    "ENC" = "EIZO";
    "EPI" = "Envision";
    "FCM" = "Funai";
    "FUJ" = "Fujitsu";
    "FUS" = "Fujitsu-Siemens";
    "GSM" = "LG Electronics";
    "GWY" = "Gateway 2000";
    "HEI" = "Hyundai";
    "HIT" = "Hyundai";
    "HSL" = "Hansol";
    "HTC" = "Hitachi/Nissei";
    "HWP" = "HP";
    "IBM" = "IBM";
    "ICL" = "Fujitsu ICL";
    "IVM" = "Iiyama";
    "KDS" = "Korea Data Systems";
    "LEN" = "Lenovo";
    "LGD" = "Asus";
    "LPL" = "Fujitsu";
    "MAX" = "Belinea"; 
    "MEI" = "Panasonic";
    "MEL" = "Mitsubishi Electronics";
    "MS_" = "Panasonic";
    "NAN" = "Nanao";
    "NEC" = "NEC";
    "NOK" = "Nokia Data";
    "NVD" = "Fujitsu";
    "OPT" = "Optoma";
    "PHL" = "Philips";
    "REL" = "Relisys";
    "SAN" = "Samsung";
    "SAM" = "Samsung";
    "SBI" = "Smarttech";
    "SGI" = "SGI";
    "SNY" = "Sony";
    "SRC" = "Shamrock";
    "SUN" = "Sun Microsystems";
    "SEC" = "Hewlett-Packard";
    "TAT" = "Tatung";
    "TOS" = "Toshiba";
    "TSB" = "Toshiba";
    "VSC" = "ViewSonic";
    "ZCM" = "Zenith";
    "UNK" = "Unknown";
    "_YV" = "Fujitsu";
      }
  
   $CSVLogFile = "./MonitorInfo_$(Get-Date -Format yyyymmdd_HHMM).csv"   
  
  #Take each computer specified and run the following code:
  ForEach ($Computer in $ComputerName) {
  
    #Grab the Monitor objects from WMI
    $Monitors = Get-WmiObject -Namespace "root\WMI" -Class "WMIMonitorID" -ComputerName $Computer -ErrorAction SilentlyContinue
    
    #Create an empty array to hold the data
    $Monitor_Array = @()
    
    
    #Take each monitor object found and runs the following code:
    ForEach ($Monitor in $Monitors) {
      
      #Grab respective data and converts it from ASCII encoding and removes any trailing ASCII null values
      If ([System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName) -ne $null) {
        $Mon_Model = ([System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName)).Replace("$([char]0x0000)","")
      } else {
        $Mon_Model = $null
      }
      $Mon_Serial_Number = ([System.Text.Encoding]::ASCII.GetString($Monitor.SerialNumberID)).Replace("$([char]0x0000)","")
      $Mon_Attached_Computer = ($Monitor.PSComputerName).Replace("$([char]0x0000)","")
      $Mon_Manufacturer = ([System.Text.Encoding]::ASCII.GetString($Monitor.ManufacturerName)).Replace("$([char]0x0000)","")
      
      <#
      Filter out "non monitors" such as laptop displays. Place any of your own filters here. 
      Below examples are all-in-one computers with built in displays that we don't need the info from.
      Remove '#' from the code below to use this filter.
      #>
#      If ($Mon_Model -like "*800 AIO*" -or $Mon_Model -like "*8300 AiO*") {Break}
      
      #Set a friendly name based on the hash table above. If no entry found leaves it set to the original 3 character code.
      $Mon_Manufacturer_Friendly = $ManufacturerHash.$Mon_Manufacturer
      If ($Mon_Manufacturer_Friendly -eq $null) {
        $Mon_Manufacturer_Friendly = $Mon_Manufacturer
      }
      
      #Create a custom monitor object and fill it with the needed four properties with the respective data pulled from WMI.
      $Monitor_Obj = [PSCustomObject]@{
        Manufacturer     = $Mon_Manufacturer_Friendly
        Model            = $Mon_Model
        SerialNumber     = $Mon_Serial_Number
        AttachedComputer = $Mon_Attached_Computer
      }
      
      #Append the object to the array
      $Monitor_Array += $Monitor_Obj

    } #End ForEach $Monitor
  
    #Output to CSV
    $Monitor_Array | Select AttachedComputer,SerialNumber,Manufacturer,Model |
               Export-Csv -Append $CSVLogFile -NoTypeInformation
    $Monitor_Array
    
} #End ForEach $Computer

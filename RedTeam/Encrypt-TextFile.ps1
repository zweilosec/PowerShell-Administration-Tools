<#
   .Synopsis
      This script provides encryption and decryption of text files using a key.
   .DESCRIPTION
      PowerShell script for encrypting text files.  There are two functions contained in this script:
      Encrypt-File - Can only handle text files of approximately ~65kb due to a limitation with SecureString
      
      Encrypt-LongFile - Can handle files of any length, but the output is much, much longer.  
        Requires a map of the length of each encrypted chunk in order to decrypt the data, which is saved to CSV.
   .EXAMPLE
      Encrypt-LongFile -Path C:\temp\passwords.txt -UTF8
   .INPUTS
      -Path <file_to_encrypt>
      The target file to encrypt
      -UTF8
      An optional parameter that is needed only for UTF8-encoded files
   .OUTPUTS
      This script returns text in an encrypted form. 
      The Encrypt-LongFile function below also outputs the contents of the encryption to a file and a map of the chunk lengths.  
        The line '$encrypted | Out-File "Encrypted-File"' can be safely commented out if the file output is not needed.
   .NOTES
      Author: Beery, Christopher (https://github.com/zweilosec)
      Created: 24 Dec 2022
      Last Modified: 27 Dec 2022
      Useful Study Links:
      * https://medium.com/@sumindaniro/encrypt-decrypt-data-with-powershell-4a1316a0834b
      * https://medium.com/@nikhilsda/encryption-and-decryption-in-powershell-e7a678c5cd7d
      * https://shellgeek.com/split-string-into-fix-length-in-powershell/
   #>

function Encrypt-File
{
<#
  Description: This script provides encryption of small text files using a key. 
  The -UTF8 flag can be used if the input file is UTF-8 encoded.
#>
    param(
        [Parameter(Mandatory=$true)]
        [String]$Path,
        [String]$key = "usemetodecryptit",
        [Switch]$UTF8
        )
        
    $key = (New-Object System.Text.ASCIIEncoding).GetBytes($key)
    $securestring = new-object System.Security.SecureString

    #Use the -UTF8 flag if your input file is UTF-8 encoded!
    #There is no simple way to check this in PowerShell unfortunately. Use Notepad if possible.

    if ($UTF8)
    {
        $dataString = Get-Content -Encoding UTF8 -Path $Path -Raw
    }
    else
    {
        $dataString = Get-Content -Encoding Unicode -Path $Path -Raw
    }

    foreach ($char in $dataString.toCharArray()) {
          $secureString.AppendChar($char)
    }

    $encrypted = ConvertFrom-SecureString -SecureString $secureString -Key $key

    return $encrypted
}

function Encrypt-LongFile
{
<#
  Description: This script provides encryption of large text files using a key. 
  The -UTF8 flag can be used if the input file is UTF-8 encoded.
#>
    param(
        [Parameter(Mandatory=$true)]
        [String]$Path, 
        [String]$key = "usemetodecryptit",
        [Switch]$UTF8
        )
    
    # Key to be used to encrypt data.  Must be either 128 bits (16 chars), 192 bits (24 chars), or 256 bits (32 chars) long.    
    $key = (New-Object System.Text.ASCIIEncoding).GetBytes($key)
    
    # Use the -UTF8 flag if your input file is UTF-8 encoded!
    # There is no simple way to check this in PowerShell unfortunately. Use Notepad if possible.
    # The -Raw flag is necessary to preserve line endings in text files
    if ($UTF8)
    {
        $dataString = Get-Content -Encoding UTF8 -Path $Path -Raw
    }
    else
    {
        $dataString = Get-Content -Encoding Unicode -Path $Path -Raw
    }

    #Split the data string into chunks no longer than 30 characters
    # larger sizes seem to break it, feel free to play with it
    $chunks = $dataString -split "(.{30})" | ?{$_}

    # Initialize the encrypted variable
    $encrypted = ""
    $len_map = New-Object System.Collections.Generic.List[System.Object]

    # Loop through each chunk
    foreach ($chunk in $chunks) 
    {
      # Convert the chunk to a SecureString object
      $secureString = new-object System.Security.SecureString
      foreach ($char in $chunk.toCharArray()) 
      {
        $secureString.AppendChar($char)
      }

      # Encrypt the SecureString object
      $encryptedChunk = ConvertFrom-SecureString -SecureString $secureString -Key $key

      # Need to save these lengths as a map because each encrypted chunk has a different length
      $len_map.Add($encryptedChunk.Length)

      # Append the encrypted chunk to the encrypted variable
      # Each chunk is output with a prepended header of some sort
      # The output could be smaller if this were removed, then re-added during decryption (TODO:)
      $encrypted += $encryptedChunk
    }

    #Convert the array of chunk lengths to a format that can be written to a csv file
    ConvertFrom-Csv $len_map -Header Number | Export-Csv -Path "HashMap.csv" -NoTypeInformation
    
    #Write the encrypted data to a file
    $encrypted | Out-File "Encrypted-File"

    #return the encrypted data to be used externally
    return $encrypted
}

<#
   .Synopsis
      This script provides decryption of text files using a key.
   .DESCRIPTION
      PowerShell script for decrypting text files encrypted with my other script.
      There are two functions contained in this script:
      Decrypt-File - For use with my Encrypt-File function
      
      Decrypt-LongFile - For use with my Encrypt-LongFile function  
        Requires a map of the length of each encrypted chunk in order to decrypt the data, which was saved to CSV.
   .EXAMPLE
      Decrypt-LongFile -enc_text C:\temp\Encrypted-File
   .INPUTS
      -enc_text <text_to_decrypt>
      The target text/file to decrypt
      -recovered
      An optional parameter that specifies the name of the ouput file
   .OUTPUTS
      This script decrypts text and outputs the plaintext to a file. 
   .NOTES
      Author: Beery, Christopher (https://github.com/zweilosec)
      Created: 24 Dec 2022
      Last Modified: 27 Dec 2022
      Useful Study Links:
      * https://medium.com/@sumindaniro/encrypt-decrypt-data-with-powershell-4a1316a0834b
      * https://medium.com/@nikhilsda/encryption-and-decryption-in-powershell-e7a678c5cd7d
      * https://shellgeek.com/split-string-into-fix-length-in-powershell/
   #>
   
function Decrypt_file
{
    param(
        [Parameter(Mandatory=$true)]
        [String]
        $enc_text,
        [String]$key = "usemetodecryptit",
        [String]
        $recovered = "recovered.txt"
        )
        
    # Key to be used to decrypt data.  Must be either 128 bits (16 chars), 192 bits (24 chars), or 256 bits (32 chars) long.
    $key = (New-Object System.Text.ASCIIEncoding).GetBytes($key)
        
    # Decrypt the data
    echo $enc_text | 
    ConvertTo-SecureString -key $key | 
    ForEach-Object {[Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($_))} > $recovered
}

function Decrypt_Longfile
{
    param(
        [Parameter(Mandatory=$true)]
        [String]$enc_text,
        [String]$key = "usemetodecryptit",
        [String]$recovered = "recovered.txt"
        )

    # Key to be used to decrypt data.  Must be either 128 bits (16 chars), 192 bits (24 chars), or 256 bits (32 chars) long.
    $key = (New-Object System.Text.ASCIIEncoding).GetBytes($key)

    $hashmap = (Import-Csv "HashMap.csv")

    # Initialize the output variable
    $decrypted = ""

    # Loop through the chunk lengths array
    for ($i = 0; $i -lt $hashmap.Count; $i++) 
    {
      # Get the length of the current chunk
      $length = $hashmap.Item($i)
      $hash_len = $length.Number

      # Extract the current chunk from the encrypted data
      $chunk = $enc_text.Substring(0,$hash_len).Trim()

      # Remove the current chunk from the beginning of the encrypted data
      $enc_text = $enc_text.Substring($hash_len)

      # Decrypt the chunk
      $secureString = $chunk | ConvertTo-SecureString -key $key
      $decryptedChunk = ForEach-Object {[Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString))}

      # Append the decrypted chunk to the decrypted variable
      $decrypted += $decryptedChunk
    }

    # Write the decrypted data to a file
    echo $decrypted > $recovered
}

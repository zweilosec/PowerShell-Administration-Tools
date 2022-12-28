<#
   .Synopsis
      This script provides decryption of arbitrary files encrypted by my AESEncrypt-File function.
   .DESCRIPTION
      PowerShell script for decrypting files of any type.  Fixes the limitations of my Encrypt-TextFile functions.
      Note: The key and IV are cut from the where they were appended to the encoded data. May not be OPSEC safe!
   .EXAMPLE
      AESDecrypt-File -encrypted "<Base64-String>" -OutFile "C:\Temp\Recovered_passwords.zip"
   .INPUTS
      -encrypted <string_to_decrypt>
      The encrypted string to decrypt.
      
      -OutFile <path/to/recovered/file>
      The output file.  Defaults to $env:HOMEPATH\recovered
   .OUTPUTS
      This script returns a decrypted file.  
   .NOTES
      Author: Beery, Christopher (https://github.com/zweilosec)
      Created: 28 Dec 2022
      Last Modified: 28 Dec 2022
      Useful Study Links:
      * https://codeforcontent.com/blog/using-aes-in-powershell/
      * https://codeandkeep.com/PowerShell-Aes-Encryption/
      * https://stackoverflow.com/questions/31855705/write-bytes-to-a-file-natively-in-powershell
   #>
   
   function Decrypt-AESFile
{
  param(
        [Parameter(Mandatory=$true)]
        [String]$encrypted, 
        [String]$OutFile = "$env:HOMEPATH\recovered"
        )
  try
  {
    # Extract the encrypted chunk, key, and IV from the encrypted data
    $encrypted, $key, $iv = $encrypted -Split '/CUT/'
    $encryptedBytes = [Convert]::FromBase64String($encrypted)
    $keyBytes = [Convert]::FromBase64String($key)
    $ivBytes = [Convert]::FromBase64String($iv)
    
    # Create a new AesCryptoServiceProvider object
    $aes = New-Object System.Security.Cryptography.AesCryptoServiceProvider
    $aes.Key = $keyBytes
    $aes.IV = $ivBytes

    # Decrypt the data using the key and IV
    $decrypted = $aes.CreateDecryptor().TransformFinalBlock($encryptedBytes, 0, $encryptedBytes.Length)

    # Write the decrypted data to a file
    [System.IO.File]::WriteAllBytes($OutFile, $decrypted)
  }
  catch
  {
    # Log the exception message to a file
    Write-Error $_.Exception.Message | Out-File -FilePath "decrypt_error.log"
  }
}

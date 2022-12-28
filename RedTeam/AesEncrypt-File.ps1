<#
   .Synopsis
      This script provides AES encryption of arbitrary files.
   .DESCRIPTION
      PowerShell script for encrypting files of any type.  Fixes the limitations of my Encrypt-TextFile functions.
   .EXAMPLE
      AESEncrypt-File -Path C:\temp\passwords.txt
   .INPUTS
      -Path <file_to_encrypt>
      The target file to encrypt
   .OUTPUTS
      This script returns text in an encrypted form, Base64-encoded for easy transport.  
      Note: The key and IV are currently generated in-script and appended to the encoded data. May not be OPSEC safe!
   .NOTES
      Author: Beery, Christopher (https://github.com/zweilosec)
      Created: 28 Dec 2022
      Last Modified: 28 Dec 2022
      Useful Study Links:
      * https://codeforcontent.com/blog/using-aes-in-powershell/
      * https://codeandkeep.com/PowerShell-Aes-Encryption/
      * https://stackoverflow.com/questions/31855705/write-bytes-to-a-file-natively-in-powershell
   #>
function AESEncrypt-File
{
  param(
        [Parameter(Mandatory=$true)]
        [String]$Path
        )
  
  # Generate a new key and initialization vector (IV)
  $aes = New-Object System.Security.Cryptography.AesCryptoServiceProvider
  $aes.GenerateKey()
  $aes.GenerateIV()

  # Read the file into a byte array
  $data = [System.IO.File]::ReadAllBytes($Path)

  # Encrypt the data using the key and IV
  $encrypted = $aes.CreateEncryptor().TransformFinalBlock($data, 0, $data.Length)

  # Write to Base64 for easier transport
  # Currently, '/CUT/' is the hard-coded delimiter
  $encryptedString = [Convert]::ToBase64String($encrypted)
  $encryptedString += "/CUT/" + [Convert]::ToBase64String($aes.Key)
  $encryptedString += "/CUT/" + [Convert]::ToBase64String($aes.IV)

  # Clean up the AES Generators
  $aes.Dispose()
    
  # Return the encrypted data
  return $encryptedString
}

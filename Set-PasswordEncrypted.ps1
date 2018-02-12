
Function Set-PasswordEncrypted() {
 <#
 .SYNOPSIS
 This function encrypts password and saves it to the Windows registry.
 .DESCRIPTION
  This function saves encrypted password for next usage only current account. It saves password in HKCU registry hive. Encrypted password could be used by Get-PasswordFromKeePass function.
 .PARAMETER Name
 Password name. Needed for getting this password from registry.
 .PARAMETER PlainPassword
 Password as plain text.
 .EXAMPLE
 Set-PasswordEncrypted -Name 'saqwel' -PlainPassword 'P@ssw0rd'
 #>

 param(
  [Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()]
  [string]$Name,
  [Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()]
  [string]$PlainPassword
 )

 $SecurePassword = $PlainPassword | 
  ConvertTo-SecureString -AsPlainText -Force | 
  ConvertFrom-SecureString
 $RegPath = "HKCU:\Software\Passwords"
 if(!(Test-Path -Path $RegPath)) {
  New-Item -Path $RegPath -Confirm:$false -Force -ErrorAction Stop | Out-Null
 }
 New-ItemProperty -Path $RegPath -Name $Name -Value $SecurePassword -Force -ErrorAction Stop | Out-Null
}

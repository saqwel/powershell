Function Get-PasswordFromKeePass() {
	<#
	.SYNOPSIS
	This function returns username and password from KeePass database
	.DESCRIPTION
	This function allows to get any password from KeePass database,
	if you know entry name and parent group name, where user name and password are stored.
	Clarification.
	You can create groups (or folders) in KeePass which is fills with data. These groups are called ParentGroup. 
	For getting password you need to know entry name and parent group name where this entry stored. 
	For example, we divide all the data by operating systems names.
	To use this function you need to save encrypted KeePass password in registry hive HKCU:\Software\Passwords with cmdlet Set-PasswordEncrypted.
	.PARAMETER UserName
	Entry name where username and password are stored. Entry name could be equal to username.
	.PARAMETER ParentGroupName
	Group in KeePass database, where entry stored.
	.EXAMPLE
	Get-PasswordFromKeePass -UserName 'MegaAdmin' -ParentGroupName 'Windows'
	.EXAMPLE
	Get-PasswordFromKeePass -UserName 'MegaRoot' -ParentGroupName 'Linux'
	#>

	param(
		[Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()]
		[string]$UserName,
		[Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()]
		[string]$ParentGroupName
	)

	# KeePass password is encrypted and stored in a registry hive
	$RegPath = "HKCU:\Software\Passwords"
	# Parameter where encrypted password saved - KeePassPassword
	$Encrypted = (Get-ItemProperty -Path $RegPath).KeePassPassword
	# Need to convert password before decrypting
	$SecureString  = $Encrypted | ConvertTo-SecureString
	# Get password which is ready to open KeePass database
	$KeePass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString))

	# Load the classes from KeePass.exe:
	[Reflection.Assembly]::LoadFile('C:\Keepass\KeePass.exe') | Out-Null
	# To connect to KeePass get parameters
	$KcpUserAccount = New-Object -TypeName KeePassLib.Keys.KcpUserAccount
	$KcpPassword    = New-Object -TypeName KeePassLib.Keys.KcpPassword($KeePass)
	$CompositeKey   = New-Object -TypeName KeePassLib.Keys.CompositeKey 
	$CompositeKey.AddUserKey( $KcpPassword )

	# To open a KeePass database, the path to the .KDBX file is required
	$IOConnectionInfo = New-Object KeePassLib.Serialization.IOConnectionInfo
	$IOConnectionInfo.Path = 'C:\Keepass\gpikkit.kdbx'

	#  Open the KeePass database with key, path and logger objects
	$PwDatabase = New-Object -TypeName KeePassLib.PwDatabase
	$PwDatabase.Open($IOConnectionInfo, $CompositeKey, $Null)

	# Get password based on parameters of function
	$PwCollection = $PwDatabase.RootGroup.GetEntries($True) | 
		Where{ $_.ParentGroup.Name -eq $ParentGroupName -and $_.Strings.ReadSafe("Title") -eq $UserName }
	$PwDatabase.Close()

	# Return only one password
	If($PwCollection.Uuid.Count -eq 1) {
		$Object = @{
			Password = $PwCollection.Strings.ReadSafe("Password")
			UserName = $PwCollection.Strings.ReadSafe("UserName")
		}
	} else {
		$Object = $False
	}

	return $Object
}

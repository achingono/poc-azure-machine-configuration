$name = $Env:MODULE_NAME;

# Install required modules
Install-Module -Name PSDscResources -RequiredVersion "2.12.0.0" -Force -SkipPublisherCheck -AllowClobber;
Install-Module -Name WebAdministrationDsc -RequiredVersion "4.1.0" -Force -SkipPublisherCheck -AllowClobber;
Install-Module -Name GuestConfiguration -RequiredVersion "4.5.0" -Force -SkipPublisherCheck -AllowClobber;

# Save DSC Configuration content to file
$content = $Env:MODULE_CONTENT;

# Specify the file path where the DSC Configuration content will be saved
$filePath = "./${name}.ps1"

# Save the DSC Configuration content to the file
Set-Content -Path $filePath -Value $content

# Import the DSC Module
Import-Module $filePath;

# Compile the DSC Module
$params = @{
    siteName = $Env:SITE_NAME;
    applicationPool = $Env:APPLICATION_POOL;
    packageUrl = $Env:PACKAGE_URL;
    packageName = $Env:PACKAGE_NAME;
    decryptionKey = $Env:DECRYPTION_KEY;
    validationKey = $Env:VALIDATION_KEY;
    OutputPath = ".\output";
    Verbose = $true;
    Force = $true;
    ErrorAction = "Stop";
}
& $name @params;

# Create the configuration package
New-GuestConfigurationPackage -Name $name `
                    -Configuration ".\output\localhost.mof" `
                    -Type "AuditAndSet" `
                    -Force $true;

# Upload the DSC configuration to the storage account
$storageAccount = Get-AzStorageAccount -ResourceGroupName $Env:AZURE_RESOURCE_GROUP -Name $Env:AZURE_STORAGE_ACCOUNT;
Set-AzStorageBlobContent -File "${name}.zip" -Container $Env:AZURE_STORAGE_CONTAINER -Blob "${name}.zip" -Context $storageAccount.Context -Force;

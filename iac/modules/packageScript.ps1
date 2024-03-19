$name = $Env:MODULE_NAME;
# Save DSC Configuration content to file
$content = $Env:MODULE_CONTENT;

# Specify the file path where the DSC Configuration content will be saved
$filePath = "./${name}.ps1"

# Save the DSC Configuration content to the file
Set-Content -Path $filePath -Value $content

# Execute the Powershell script
& $filePath;

# Execute the Powershell function
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

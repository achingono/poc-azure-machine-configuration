[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "The deployment environment name")]
    [string] $name,
    [Parameter(Mandatory = $true, HelpMessage = "The deployment environment location")]
    [string] $location,
    [Parameter(Mandatory = $true, HelpMessage = "The deployment environment code")]
    [string] $code,
    [Parameter(Mandatory = $true, HelpMessage = "The deployment environment username")]
    [string] $username,
    [Parameter(Mandatory = $true, HelpMessage = "The deployment environment password")]
    [string] $password,
    [Parameter(Mandatory = $false, HelpMessage = "The deployment version")]
    [string] $version = "0.1"
)

$artifactsPath = "$PSScriptRoot\artifacts";
$webDeployPackage = "$artifactsPath\WebDeploy.zip";
$webDeployBlob = "WebDeploy.zip";
$configurationPackage = "$artifactsPath\ServerConfiguration.zip";
$configurationBlob = "ServerConfiguration.zip";
$deploymentContainerName = "deployments";
$configurationsContainerName = "configurations";

# Import the Az module
Import-Module Az.Resources;
Import-Module Az.Storage;

$resourceGroupName = "rg-$name-$code-$location";
# check if resource group exists
$resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue;
if ($null -eq $resourceGroup) {
    # Create resources group
    New-AzResourceGroup -Name $resourceGroupName -Location $location;
}

# check if storage account exists
$storageAccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -Name "stg$name$code" -ErrorAction SilentlyContinue;
if ($null -eq $storageAccount) {
    # Create storage account
    $storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name "stg$name$code" -Location $location -SkuName "Standard_LRS" -Kind "StorageV2";
}

# create storage container if it does not exist
$deploymentsContainer = Get-AzStorageContainer -Name $deploymentContainerName -Context $storageAccount.Context -ErrorAction SilentlyContinue;
if ($null -eq $deploymentsContainer) {
    # Create storage container
    New-AzStorageContainer -Name $deploymentContainerName -Context $storageAccount.Context;
}

# create storage container if it does not exist
$configurationsContainer = Get-AzStorageContainer -Name $configurationsContainerName -Context $storageAccount.Context -ErrorAction SilentlyContinue;
if ($null -eq $configurationsContainer) {
    # Create storage container
    New-AzStorageContainer -Name $configurationsContainerName -Context $storageAccount.Context;
}

# append version if provided
if ($null -ne $version -and $version -ne "") {
    $webDeployBlob = "WebDeploy-v${version}.zip";
    $configurationBlob = "ServerConfiguration-v${version}.zip";
}

# Check if blob exists
$webDeployBlobExists = Get-AzStorageBlob -Container $deploymentContainerName -Blob $webDeployBlob -Context $storageAccount.Context -ErrorAction SilentlyContinue;
if ($null -eq $webDeployBlobExists) {
    # Upload WebDeploy package
    Set-AzStorageBlobContent -File $webDeployPackage -Container $deploymentContainerName -Blob $webDeployBlob -Context $storageAccount.Context -Force;
}

# Check if blob exists
$configurationBlobExists = Get-AzStorageBlob -Container $configurationsContainerName -Blob $configurationBlob -Context $storageAccount.Context -ErrorAction SilentlyContinue;
if ($null -eq $configurationBlobExists) {
    # Upload ServerConfiguration package
    Set-AzStorageBlobContent -File $configurationPackage -Container $configurationsContainerName -Blob $configurationBlob -Context $storageAccount.Context -Force;
}

# Deploy the Bicep template
New-AzDeployment -Name $name -Location $location -TemplateFile "./iac/main.bicep" `
    -TemplateParameterObject @{
        "name" = $name; 
        "location" = $location; 
        "uniqueSuffix" = $code; 
        "adminUsername" = $username; 
        "adminPassword" = $password;
        "version" = $version;
        "decryptionKey" = '18F665CA29B4911B0C1755979C15F40466237BC9A101836A5AC6D1CE85D6B022';
        "validationKey" = '1E3D5BABF386E7A89DAE461DF2FA228734680C61';
    };

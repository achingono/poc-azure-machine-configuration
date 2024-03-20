param name string
param location string
param version string = ''
param decryptionKey string
param validationKey string
param baseTime string = utcNow()

var configurationName = 'ServerConfiguration'
var packageName = 'WebDeploy${empty(version) ? '' : '-v${version}'}.zip'

var sasProperties = {
  canonicalizedResource: '/blob/${storageAccount.name}'
  signedResourceTypes: 'sco'
  signedPermission: 'rl'
  signedExpiry: dateTimeAdd(baseTime, 'PT1H')
  signedProtocol: 'https'
  signedServices: 'b'
}
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: 'stg${replace(name, '-', '')}'
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' existing = {
  name: 'default'
  parent: storageAccount
}

resource deployContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' existing = {
  name: 'deployments'
  parent: blobService
}

resource configContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' existing = {
  name: 'configurations'
  parent: blobService
}

resource uploadScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'ds-upload-configuration'
  location: location
  kind:'AzurePowerShell'
  properties: {
    azPowerShellVersion: '11.3'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AZURE_RESOURCE_GROUP'
        value: resourceGroup().name
      }
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccount.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: storageAccount.listKeys().keys[0].value
      }
      {
        name: 'AZURE_STORAGE_CONTAINER'
        value: configContainer.name
      }
      {
        name: 'AZURE_STORAGE_BLOB'
        value: '${configurationName}${empty(version) ? '' : '-v${version}'}.zip'
      }
      {
        name: 'MODULE_CONTENT'
        value: loadTextContent('../../dsc/${configurationName}.ps1')
      }
      {
        name: 'MODULE_NAME'
        value: configurationName
      }
      {
        name: 'SITE_NAME'
        value: name
      }
      {
        name: 'APPLICATION_POOL'
        value: replace(name, '-', '')
      }
      {
        name: 'PACKAGE_URL'
        value: '${storageAccount.properties.primaryEndpoints.blob}${deployContainer.name}/${packageName}?${storageAccount.listAccountSas('2021-04-01', sasProperties).accountSasToken}'
      }
      {
        name: 'PACKAGE_NAME'
        value: packageName
      }
      {
        name: 'DECRYPTION_KEY'
        secureValue: decryptionKey
      }
      {
        name: 'VALIDATION_KEY'
        secureValue: validationKey
      }
    ]
    scriptContent: loadTextContent('./packageScript.ps1')
  }
}

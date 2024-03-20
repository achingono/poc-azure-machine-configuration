param name string
param location string
param version string
param decryptionKey string
param validationKey string
param baseTime string = utcNow()

var configurationName = 'ServerConfiguration'
var bundleName = '${configurationName}${empty(version) ? '' : '-v${version}'}.zip'
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

resource configContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' existing = {
  name: 'configurations'
  parent: blobService
}

resource deployContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' existing = {
  name: 'deployments'
  parent: blobService
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' existing = {
  name: 'vm-${name}'
}

resource assignment 'Microsoft.GuestConfiguration/guestConfigurationAssignments@2022-01-25' = {
  name: 'gca-${name}'
  location: location
  scope: virtualMachine
  properties: {
    guestConfiguration: {
      name: configurationName
      version: version
      assignmentType: 'ApplyAndAutoCorrect'
      contentUri: '${storageAccount.properties.primaryEndpoints.blob}${configContainer.name}/${bundleName}?${storageAccount.listAccountSas('2021-04-01', sasProperties).accountSasToken}'
      contentHash: '2BE17208753CAB389BB24C198F95C3BAB00069D3175E330CB2ECAB6D64EB22EC'
      configurationParameter: [
        {
          name: 'siteName'
          value: name
        }
        {
          name: 'applicationPool'
          value: replace(name, '-', '')
        }
        {
          name: 'packageUrl'
          value: '${storageAccount.properties.primaryEndpoints.blob}${deployContainer.name}/${packageName}?${storageAccount.listAccountSas('2021-04-01', sasProperties).accountSasToken}'
        }
        {
          name: 'packageName'
          value: packageName
        }
        {
          name: 'decryptionKey'
          value: decryptionKey
        }
        {
          name: 'validationKey'
          value: validationKey
        }
      ]
    }
  }
}

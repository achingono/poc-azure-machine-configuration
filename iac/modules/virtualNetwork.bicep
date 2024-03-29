param name string
param location string

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-11-01' existing = {
  name: 'nsg-${name}'
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: 'vnet-${name}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
    enableDdosProtection: false
  }
}

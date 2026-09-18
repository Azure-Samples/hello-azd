metadata description = 'Creates an Azure storage account.'
param name string
param location string = resourceGroup().location
param tags object = {}

param containers array = []
param tables array = []

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: name
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
    supportsHttpsTrafficOnly: true
  }

  resource blobServices 'blobServices' = if (!empty(containers)) {
    name: 'default'
    properties: {}

    resource container 'containers' = [for container in containers: {
      name: container.name
      properties: {
        publicAccess: 'None'
      }
    }]
  }

  resource tableServices 'tableServices' = if (!empty(tables)) {
    name: 'default'
    properties: {}

    resource table 'tables' = [for table in tables: {
      name: table.name
    }]
  }
}

output blobEndpoint string = storage.properties.primaryEndpoints.blob
output tableEndpoint string = storage.properties.primaryEndpoints.table

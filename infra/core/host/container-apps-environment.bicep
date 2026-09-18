metadata description = 'Creates an Azure Container Apps environment.'
param name string
param location string = resourceGroup().location
param tags object = {}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {}
}

output name string = containerAppsEnvironment.name

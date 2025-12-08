metadata description = 'Create web application resources.'

param appName string
param location string = resourceGroup().location
param tags object = {}

param identityName string
param containerAppsEnvironmentName string
param containerRegistryName string
param serviceName string = 'aca'
param exists bool

@description('Blob endpoint for Azure Storage account.')
param storageAccountBlobEndpoint string

@description('Table endpoint for Azure Storage account.')
param storageAccountTableEndpoint string

type managedIdentity = {
  resourceId: string
  clientId: string
}

@description('Unique identifier for user-assigned managed identity.')
param userAssignedManagedIdentity managedIdentity

module containerAppsApp '../core/host/container-app.bicep' = {
  name: 'container-apps-app'
  params: {
    name: appName
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    secrets: {
        'azure-managed-identity-client-id':  userAssignedManagedIdentity.clientId
        'azure-storage-blob-endpoint': storageAccountBlobEndpoint
        'azure-storage-table-endpoint': storageAccountTableEndpoint
      }
    env: [
      {
        name: 'AZURE_MANAGED_IDENTITY_CLIENT_ID'
        secretRef: 'azure-managed-identity-client-id'
      }
      {
        name: 'STORAGE_URL'
        secretRef: 'azure-storage-blob-endpoint'
      }
      {
        name: 'TABLES_URL'
        secretRef: 'azure-storage-table-endpoint'
      }
    ]
    targetPort: 8080
    identityName: identityName
    //imageName: 'mcr.microsoft.com/dotnet/samples:aspnetapp'
  }
}

output endpoint string = containerAppsApp.outputs.uri
output envName string = containerAppsApp.outputs.name

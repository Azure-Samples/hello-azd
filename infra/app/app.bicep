metadata description = 'Create web application resources.'

param appName string
param location string = resourceGroup().location
param tags object = {}

param identityName string
param containerAppsEnvironmentName string
param containerRegistryName string
param serviceName string = 'aca'
param exists bool

@description('Endpoint for Azure Cosmos DB for NoSQL account.')
param databaseAccountEndpoint string

@description('Blob endpoint for Azure Storage account.')
param storageAccountBlobEndpoint string

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
        'azure-cosmos-db-nosql-endpoint': databaseAccountEndpoint
        'azure-managed-identity-client-id':  userAssignedManagedIdentity.clientId
        'azure-storage-blob-endpoint': storageAccountBlobEndpoint
      }
    env: [
      {
        name: 'AZURE_COSMOS_DB_NOSQL_ENDPOINT' // Name of the environment variable referenced in the application
        secretRef: 'azure-cosmos-db-nosql-endpoint' // Reference to secret
      }
      {
        name: 'AZURE_MANAGED_IDENTITY_CLIENT_ID'
        secretRef: 'azure-managed-identity-client-id'
      }
      {
        name: 'STORAGE_URL'
        secretRef: 'azure-storage-blob-endpoint'
      }
    ]
    targetPort: 8080
    identityName: identityName
    //imageName: 'mcr.microsoft.com/dotnet/samples:aspnetapp'
  }
}

output endpoint string = containerAppsApp.outputs.uri
output envName string = containerAppsApp.outputs.name

targetScope = 'subscription'

// The main bicep module to provision Azure resources.
// For a more complete walkthrough to understand how this file works with azd,
// see https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string = ''

param storageAccountName string = ''
param containerAppsEnvName string = ''
param containerAppsAppName string = ''
param containerRegistryName string = ''

param serviceName string = 'aca'

// Optional parameters to override the default azd resource naming conventions.
// Add the following to main.parameters.json to provide values:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param resourceGroupName string = ''

var abbrs = loadJsonContent('./abbreviations.json')

// tags that should be applied to all resources.
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': environmentName
}

// Generate a unique token to be used in naming resources.
// Remove linter suppression after using.
#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Add resources to be provisioned below.
// A full example that leverages azd bicep modules can be seen in the todo-python-mongo template:
// https://github.com/Azure-Samples/todo-python-mongo/tree/main/infra

// Create a user assigned identity
module identity './app/user-assigned-identity.bicep' = {
  name: 'identity'
  scope: rg
  params: {
    name: 'hello-azd-identity'
  }
}

// Create a storage account
module storage './core/storage/storage-account.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    name: !empty(storageAccountName) ? storageAccountName : '${abbrs.storageStorageAccounts}${resourceToken}'
    location: location
    tags: tags
    allowSharedKeyAccess: false
    containers: [
      {
        name: 'attachments'
      }
    ]
    tables: [
      {
        name: 'tickets'
      }
    ]
  }
}

// Assign storage blob data contributor to the user for local runs
module userAssignStorage './core/security/role.bicep' = {
  name: 'assignStorage'
  scope: rg
  params: {
    principalId: principalId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // built-in role definition id for storage blob data contributor
    principalType: 'User'
  }
}

// Assign storage blob data contributor to the identity
module identityAssignStorage './core/security/role.bicep' = {
  name: 'identityAssignStorage'
  scope: rg
  params: {
    principalId: identity.outputs.principalId
    roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    principalType: 'ServicePrincipal'
  }
}

// Assign storage table data contributor to the user for local runs
module userAssignTable './core/security/role.bicep' = {
  name: 'assignTable'
  scope: rg
  params: {
    principalId: principalId
    roleDefinitionId: '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3' // built-in role definition id for storage table data contributor
    principalType: 'User'
  }
}

// Assign storage table data contributor to the identity
module identityAssignTable './core/security/role.bicep' = {
  name: 'identityAssignTable'
  scope: rg
  params: {
    principalId: identity.outputs.principalId
    roleDefinitionId: '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'
    principalType: 'ServicePrincipal'
  }
}

// Container apps env and registry
module containerAppsEnv './core/host/container-apps.bicep' = {
  name: 'container-apps'
  scope: rg
  params: {
    name: 'app'
    containerAppsEnvironmentName: !empty(containerAppsEnvName) ? containerAppsEnvName : '${abbrs.appManagedEnvironments}${resourceToken}'
    containerRegistryName: !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
  }
}

// Container app
module web 'app/app.bicep' = {
  name: serviceName
  scope: rg
  params: {
    appName: !empty(containerAppsAppName) ? containerAppsAppName : '${abbrs.appContainerApps}${resourceToken}'
    storageAccountBlobEndpoint: storage.outputs.blobEndpoint
    storageAccountTableEndpoint: storage.outputs.tableEndpoint
    containerAppsEnvironmentName: containerAppsEnv.outputs.environmentName
    containerRegistryName: containerAppsEnv.outputs.registryName
    userAssignedManagedIdentity: {
      resourceId: identity.outputs.resourceId
      clientId: identity.outputs.clientId
    }
    location: location
    tags: tags
    serviceName: serviceName
    exists: false
    identityName: identity.outputs.name
  }
}

// Add outputs from the deployment here, if needed.
//
// This allows the outputs to be referenced by other bicep deployments in the deployment pipeline,
// or by the local machine as a way to reference created resources in Azure for local development.
// Secrets should not be added here.
//
// Outputs are automatically saved in the local azd environment .env file.
// To see these outputs, run `azd env get-values`,  or `azd env get-values --output json` for json output.
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
// Container outputs
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerAppsEnv.outputs.registryLoginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerAppsEnv.outputs.registryName

// // Application outputs
// output AZURE_CONTAINER_APP_ENDPOINT string = web.outputs.endpoint
// output AZURE_CONTAINER_ENVIRONMENT_NAME string = web.outputs.envName

// Identity outputs
output AZURE_USER_ASSIGNED_IDENTITY_NAME string = identity.outputs.name

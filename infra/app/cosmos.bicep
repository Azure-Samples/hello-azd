metadata description = 'Sample template to deploy an Azure Cosmos DB for NoSQL account and give yourself role-based access to it.'

@description('The principal ID of the user or service principal to assign the role to.')
param userPrincipalId string


@description('The principal ID of the managed identity to assign the role to.')
param managedIdentityId string

@description('The name of the Azure Cosmos DB account.')
param azureCosmosDBAccountName string = 'csms-${toLower(uniqueString(subscription().id, resourceGroup().id, resourceGroup().location))}'

resource account 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: azureCosmosDBAccountName
  location: resourceGroup().location
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: resourceGroup().location
      }
    ]
    disableLocalAuth: true
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-04-15' = {
  name: 'Tickets'
  parent: account
  properties: {
    resource: {
      id: 'Tickets'
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  name: 'Support'
  parent: database
  properties: {
    options: {
      throughput: 400
    }
    resource: {
      id: 'Support'
      partitionKey: {
        paths: [
          '/department'
        ]
        kind: 'Hash'
      }
    }
  }
}

resource definition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2023-04-15' = {
  name: guid('nosql-role-definition', account.id)
  parent: account
  properties: {
    assignableScopes: [
      account.id
    ]
    permissions: [
      {
        dataActions: [
          'Microsoft.DocumentDB/databaseAccounts/readMetadata' // Read account metadata
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*' // Create items
          'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*' // Manage items
        ]
        notDataActions: []
      }
    ]
    roleName: 'Write to Azure Cosmos DB for NoSQL data plane'
    type: 'CustomRole'
  }
}

resource assignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  name: guid(definition.id, userPrincipalId, account.id)
  parent: account
  properties: {
    principalId: userPrincipalId
    roleDefinitionId: definition.id
    scope: account.id
  }
}

resource identityAssignment 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2023-04-15' = {
  name: guid(definition.id, managedIdentityId, account.id)
  parent: account
  properties: {
    principalId: managedIdentityId
    roleDefinitionId: definition.id
    scope: account.id
  }
}

output endpoint string = account.properties.documentEndpoint

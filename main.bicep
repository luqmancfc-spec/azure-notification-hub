param location string = resourceGroup().location
param keyVaultName string = 'kv-prod-${uniqueString(resourceGroup().id, deployment().name)}'

// 1. Create a Managed Identity for the Deployment Script
resource scriptIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'script-wait-identity'
  location: location
}

// 2. Create the Key Vault
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: { family: 'A', name: 'standard' }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
  }
}

// 3. The Namespace
resource nhNamespace 'Microsoft.NotificationHubs/namespaces@2023-09-01' = {
  name: 'nh-ns-${uniqueString(resourceGroup().id)}'
  location: location
  sku: { name: 'Free' }
}

// 4. The Delay Script (Now with Identity)
resource delayScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'waitForNamespace'
  location: location
  kind: 'AzurePowerShell'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${scriptIdentity.id}': {}
    }
  }
  properties: {
    azPowerShellVersion: '10.0'
    scriptContent: 'Start-Sleep -Seconds 30'
    retentionInterval: 'P1D'
    cleanupPreference: 'OnSuccess'
  }
  dependsOn: [ nhNamespace ]
}

// 5. The Notification Hub
resource notificationHub 'Microsoft.NotificationHubs/namespaces/notificationHubs@2023-09-01' = {
  parent: nhNamespace
  name: 'nh-core-prod'
  location: location
  dependsOn: [ delayScript ]
}

resource sendAuthRule 'Microsoft.NotificationHubs/namespaces/notificationHubs/authorizationRules@2023-10-01-preview' = {
  parent: notificationHub
  name: 'BackendSendPolicy'
  properties: {
    rights: [ 'Send' ]
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'NotificationHubConnectionString'
  properties: {
    value: sendAuthRule.listKeys().primaryConnectionString 
  }
}

output vaultName string = kv.name
output hubName string = notificationHub.name

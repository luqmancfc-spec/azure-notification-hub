param location string = resourceGroup().location
param keyVaultName string = 'kv-prod-${uniqueString(resourceGroup().id, deployment().name)}'

// 1. Create the Key Vault to store the secret
resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true // Modern standard: Use RBAC instead of Access Policies
  }
}

// 1. The Namespace
resource nhNamespace 'Microsoft.NotificationHubs/namespaces@2023-09-01' = {
  name: 'nh-ns-${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Free'
  }
}

// 2. The Notification Hub
resource notificationHub 'Microsoft.NotificationHubs/namespaces/notificationHubs@2023-09-01' = {
  parent: nhNamespace
  name: 'nh-core-prod'
  location: location
  // Manual override to ensure the Namespace is 100% ready
  dependsOn: [
    nhNamespace
  ]
}

resource sendAuthRule 'Microsoft.NotificationHubs/namespaces/notificationHubs/authorizationRules@2023-10-01-preview' = {
  parent: notificationHub
  name: 'BackendSendPolicy'
  properties: {
    rights: [ 'Send' ]
  }
}

// 2. Fix: Store the secret in Key Vault instead of an output
resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'NotificationHubConnectionString'
  properties: {
    // This uses the correct symbolic reference to fix the linter warning
    value: sendAuthRule.listKeys().primaryConnectionString 
  }
}

// 3. Safe Output: Return the Resource Names, NOT the secrets
output vaultName string = kv.name
output hubName string = notificationHub.name

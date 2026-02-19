@description('The name of the Storage Account')
param storageAccountName string

@description('Deployment location')
param location string

@description('The access tier for the storage account (Hot or Cool).')
@allowed([
  'Hot'
  'Cool'
])
param accessTier string = 'Hot'

resource sa 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: accessTier
  }
}

@description('The resource ID of the storage account.')
output storageAccountId string = sa.id
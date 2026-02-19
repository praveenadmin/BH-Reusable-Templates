targetScope = 'resourceGroup'

@description('Location of the resource group')
param location string = resourceGroup().location

@description('storage Name')
param accountName string

@description('tags of the storage')
param tags object

@description('Name of the VNet where the private endpoint will be attached')
param privateEndpoint_vnetName string

@description('Name of the subnet to which the private endpoint will be attached')
param privateEndpoint_subnetName string

@description('Name of the resource group where the private endpoint VNet resides')
param privateEndpoint_vnetRg string

var privateEndpoint_name = '${accountName}-PE'
var privateEndpoint_groupId = 'file'
var privateEndpoint_NICname = '${privateEndpoint_name}-NIC'
var privateEndpoint_subnetId = resourceId(privateEndpoint_vnetRg, 'Microsoft.Network/virtualNetworks/subnets', privateEndpoint_vnetName, privateEndpoint_subnetName)


resource accountName 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: accountName
  location: location
  kind: 'StorageV2'
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowSharedKeyAccess: false
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}




  resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = { 
    name: privateEndpoint_name
    location: location 
    properties: {
      privateLinkServiceConnections: [ {
          name: privateEndpoint_name
          properties: {
            privateLinkServiceId: accountName.id
            groupIds: [
              privateEndpoint_groupId
            ]
          }
        } ]
      subnet: {
        id: privateEndpoint_subnetId
      }
      customNetworkInterfaceName: privateEndpoint_NICname
  }


}


resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  parent: accountName
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    deleteRetentionPolicy: {
      allowPermanentDelete: false
      enabled: false
    }
  }
}

resource blobService_containers_hosts 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-05-01' = {
  parent: blobService_resource
  name: 'azurewebjobshosts'
  properties: {
    immutableStorageWithVersioning: {
      enabled: false
    }
    defaultEncryptionScope: '$account-encryption-key'
    denyEncryptionScopeOverride: false
    publicAccess: 'None'
  }
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2022-05-01' = {
  parent: accountName
  name: 'default'
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource queueServices 'Microsoft.Storage/storageAccounts/queueServices@2022-05-01' = {
  parent: accountName
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource tableServices 'Microsoft.Storage/storageAccounts/tableServices@2022-05-01' = {
  parent: accountName
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}


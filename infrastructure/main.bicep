// ── Parametrar ──────────────────────────────────────
param location string = 'northeurope'
param environment string = 'dev'

// ── Variabler ───────────────────────────────────────
var prefix = 'artgallery-${environment}'
var vnetName = 'vnet-${prefix}'
var publicSubnetName = 'snet-public'
var appSubnetName = 'snet-app'
var bastionSubnetName = 'AzureBastionSubnet'
var dataSubnetName = 'snet-data'

// ── Virtual Network ─────────────────────────────────
resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: publicSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: nsgPublic.id
          }
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: nsgBastion.id
          }
        }
      }
      {
        name: appSubnetName
        properties: {
          addressPrefix: '10.0.3.0/24'
          networkSecurityGroup: {
            id: nsgApp.id
          }
        }
      }
      {
        name: dataSubnetName
        properties: {
          addressPrefix: '10.0.4.0/24'
          networkSecurityGroup: {
            id: nsgData.id
          }
        }
      }
    ]
  }
}

// ── NSG — Publikt subnät ─────────────────────────────
resource nsgPublic 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-public-${prefix}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTPS'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Allow-HTTP'
        properties: {
          priority: 110
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
    ]
  }
}

// ── NSG — Bastionsubnät ──────────────────────────────
resource nsgBastion 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-bastion-${prefix}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTPS-Inbound'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'Allow-GatewayManager'
        properties: {
          priority: 110
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
    ]
  }
}

// ── NSG — Appsubnät ──────────────────────────────────
resource nsgApp 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-app-${prefix}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-From-Public-Subnet'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '10.0.1.0/24'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '5000'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4000
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// ── NSG — Datasubnät ─────────────────────────────────
resource nsgData 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-data-${prefix}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4000
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// ── Cosmos DB ────────────────────────────────────────
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: 'cosmos-${prefix}'
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    enableFreeTier: true
  }
}

resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  parent: cosmosAccount
  name: 'ArtGallery'
  properties: {
    resource: {
      id: 'ArtGallery'
    }
  }
}

resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  parent: cosmosDatabase
  name: 'Paintings'
  properties: {
    resource: {
      id: 'Paintings'
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
    }
  }
}

// ── Blob Storage ─────────────────────────────────────
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'st${replace(prefix, '-', '')}001'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'paintings'
  properties: {
    publicAccess: 'None'
  }
}

// ── Publik IP för Bastion ────────────────────────────
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: 'pip-bastion-${prefix}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// ── Bastion Host ─────────────────────────────────────
resource bastion 'Microsoft.Network/bastionHosts@2024-01-01' = {
  name: 'bastion-${prefix}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          publicIPAddress: {
            id: bastionPublicIp.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, bastionSubnetName)
          }
        }
      }
    ]
  }
}

// ── Outputs ──────────────────────────────────────────
output vnetId string = vnet.id
output cosmosEndpoint string = cosmosAccount.properties.documentEndpoint
output storageAccountName string = storageAccount.name
output bastionName string = bastion.name

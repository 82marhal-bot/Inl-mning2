// ── Parametrar ──────────────────────────────────────
param location string = 'northeurope'
param environment string = 'dev'
param sshPublicKey string
param adminUsername string = 'azureuser'

// ── Variabler ───────────────────────────────────────
var prefix = 'artgallery-${environment}'
var vnetName = 'vnet-${prefix}'

var publicSubnetName = 'snet-public'
var bastionSubnetName = 'snet-bastion'
var appSubnetName = 'snet-app'
var dataSubnetName = 'snet-data'

var appInitScript = base64('''#!/bin/bash
# Installera .NET 10 Runtime
sudo apt-get update && sudo apt-get install -y dotnet-runtime-10.0

# Skapa mappen för applikationen
sudo mkdir -p /var/www/artgallery
sudo chown -R ${adminUsername}:${adminUsername} /var/www/artgallery

# Skapa en systemd-servicefil
cat <<EOF | sudo tee /etc/systemd/system/artgallery.service
[Unit]
Description=ArtGallery .NET 10 Web App
After=network.target

[Service]
WorkingDirectory=/var/www/artgallery
ExecStart=/usr/bin/dotnet /var/www/artgallery/ArtGallery.dll
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=dotnet-artgallery
User=${adminUsername}
Environment=ASPNETCORE_ENVIRONMENT=Production
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
EOF

# Ladda om systemd och aktivera tjänsten
sudo systemctl daemon-reload
sudo systemctl enable artgallery
''')

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
          networkSecurityGroup: { id: nsgPublic.id }
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: { id: nsgBastion.id }
        }
      }
      {
        name: appSubnetName
        properties: {
          addressPrefix: '10.0.3.0/24'
          networkSecurityGroup: { id: nsgApp.id }
        }
      }
      {
        name: dataSubnetName
        properties: {
          addressPrefix: '10.0.4.0/24'
          networkSecurityGroup: { id: nsgData.id }
        }
      }
    ]
  }
}

// ── NSG ─────────────────────────
resource nsgPublic 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-public-${prefix}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationPortRange: '80'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-HTTPS'
        properties: {
          priority: 110
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nsgBastion 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-bastion-${prefix}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-SSH'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationPortRange: '22'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nsgApp 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-app-${prefix}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-From-Public'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '10.0.1.0/24'
          sourcePortRange: '*'
          destinationPortRange: '5000'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'Allow-SSH-From-Bastion'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '10.0.2.0/24' // Bastion-subnätet är källan
          sourcePortRange: '*'
          destinationAddressPrefix: '*'      // Denna VM är målet
          destinationPortRange: '22'
        }
      }
      {
        name: 'Deny-All'
        properties: {
          priority: 4000
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nsgData 'Microsoft.Network/networkSecurityGroups@2024-01-01' = {
  name: 'nsg-data-${prefix}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Deny-All'
        properties: {
          priority: 4000
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// ── Virtuella Maskiner ──────────────

// BASTION
resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: 'pip-bastion-${prefix}'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource bastionNic 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: 'nic-bastion-${prefix}'
  location: location
  dependsOn: [ vnet ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, bastionSubnetName) }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: bastionPublicIp.id }
        }
      }
    ]
  }
}

resource bastionVm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'vm-bastion-${prefix}'
  location: location
  properties: {
    hardwareProfile: { vmSize: 'Standard_B2ats_v2' }
    osProfile: {
      computerName: 'bastion'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: { publicKeys: [{ path: '/home/${adminUsername}/.ssh/authorized_keys', keyData: sshPublicKey }] }
      }
    }
    storageProfile: {
      imageReference: { publisher: 'Canonical', offer: '0001-com-ubuntu-server-jammy', sku: '22_04-lts', version: 'latest' }
      osDisk: { createOption: 'FromImage' }
    }
    networkProfile: { networkInterfaces: [{ id: bastionNic.id }] }
  }
}

// PROXY (Nginx)
resource proxyPublicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: 'pip-proxy-${prefix}'
  location: location
  sku: { name: 'Standard' }
  properties: { publicIPAllocationMethod: 'Static' }
}

resource proxyNic 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: 'nic-proxy-${prefix}'
  location: location
  dependsOn: [ vnet ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, publicSubnetName) }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: { id: proxyPublicIp.id }
        }
      }
    ]
  }
}

resource proxyVm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'vm-proxy-${prefix}'
  location: location
  properties: {
    hardwareProfile: { vmSize: 'Standard_B2ats_v2' }
    osProfile: {
      computerName: 'nginx-proxy'
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: { publicKeys: [{ path: '/home/${adminUsername}/.ssh/authorized_keys', keyData: sshPublicKey }] }
      }
    }
    storageProfile: {
      imageReference: { publisher: 'Canonical', offer: '0001-com-ubuntu-server-jammy', sku: '22_04-lts', version: 'latest' }
      osDisk: { createOption: 'FromImage' }
    }
    networkProfile: { networkInterfaces: [{ id: proxyNic.id }] }
  }
}

// APP SERVER
resource appNic 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: 'nic-app-${prefix}'
  location: location
  dependsOn: [ vnet ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: { id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, appSubnetName) }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource appVm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: 'vm-app-${prefix}'
  location: location
  properties: {
    hardwareProfile: { vmSize: 'Standard_B2ats_v2' }
    osProfile: {
      computerName: 'appserver'
      adminUsername: adminUsername
      customData: appInitScript
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: { publicKeys: [{ path: '/home/${adminUsername}/.ssh/authorized_keys', keyData: sshPublicKey }] }
      }
    }
    storageProfile: {
      imageReference: { publisher: 'Canonical', offer: '0001-com-ubuntu-server-jammy', sku: '22_04-lts', version: 'latest' }
      osDisk: { createOption: 'FromImage' }
    }
    networkProfile: { networkInterfaces: [{ id: appNic.id }] }
  }
}

// ── Dataresurser ────────────────────────────────────

// COSMOS DB
resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: 'cosmos-${prefix}'
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: { defaultConsistencyLevel: 'Session' }
    locations: [{ locationName: location, failoverPriority: 0 }]
    enableFreeTier: true
  }
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  parent: cosmosAccount
  name: 'ArtGallery'
  properties: { resource: { id: 'ArtGallery' } }
}

resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  parent: cosmosDb
  name: 'Paintings'
  properties: {
    resource: {
      id: 'Paintings'
      partitionKey: { paths: ['/id'], kind: 'Hash' }
    }
  }
}

// STORAGE
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'st${replace(prefix, '-', '')}001'
  location: location
  sku: { name: 'Standard_LRS' }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

resource blob 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storage
  name: 'default'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blob
  name: 'paintings'
  properties: { publicAccess: 'None' }
}

// ── Outputs ─────────────────────────────────────────
output bastionPublicIp string = bastionPublicIp.properties.ipAddress
output proxyPublicIp string = proxyPublicIp.properties.ipAddress
output appInternalIp string = appNic.properties.ipConfigurations[0].properties.privateIPAddress

output cosmosEndpoint string = cosmosAccount.properties.documentEndpoint

// Fixade varningarna genom att använda resurs-referenser istället för strängar
@secure()
output cosmosKey string = cosmosAccount.listKeys().primaryMasterKey

@secure()
output storageConnectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=${az.environment().suffixes.storage}'


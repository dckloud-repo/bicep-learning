param artifactsLocation string = 'https://tobedeletedalreadytaken.blob.core.windows.net/dsc/'

param AVDnumberOfInstances int = 2
param currentInstances int = 0
//param newBuild bool 

@description('Location for all standard resources to be deployed into.')
param location string = 'australiaEast'
@description('Name of resource group containing AVD HostPool')
param resourceGroupName string = resourceGroup().name

param vmPrefix string = 'dckloud'

@allowed([
  'Standard_LRS'
  'Premium_LRS'
])
param vmDiskType string = 'Standard_LRS'
param vmSize string = 'Standard_B2ms'
param administratorAccountUserName string = 'admin.dancha@dckloud.com'
param administratorAccountPassword string = 'Domain@AVD2021'
param existingVNETResourceGroup string =  'shared-rg'
param existingVNETName string = 'SharedService-VNET'
param existingSubnetName string = 'AzureWVD-SN'

@description('RegistrationToken for the AVD environment')
param avdregtoken string

var subnetID = resourceId(existingVNETResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', existingVNETName, existingSubnetName)
var avSetSKU = 'Aligned'
var existingDomainUserName = first(split(administratorAccountUserName, '@'))
var numberOfInstances = (currentInstances + AVDnumberOfInstances)
var copyIndexOffset = ((currentInstances > 0) ? currentInstances : 0)
var networkAdapterPostfix = '-nic'

resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = [for i in range(0, AVDnumberOfInstances): {
  name: '${vmPrefix}-${i + currentInstances}${networkAdapterPostfix}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetID
          }
        }
      }
    ]
  }
}]

resource availabilitySet 'Microsoft.Compute/availabilitySets@2020-12-01' = {
  name: '${vmPrefix}-AV'
  location: location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 10
  }
  sku: {
    name: avSetSKU
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, AVDnumberOfInstances): {
  name: '${vmPrefix}-${i + currentInstances}'
  location: location
  properties: {
    licenseType: 'Windows_Client'
    hardwareProfile: {
      vmSize: vmSize
    }
    availabilitySet: {
      id: resourceId('Microsoft.Compute/availabilitySets', '${vmPrefix}-AV')
    }
    osProfile: {
      computerName: '${vmPrefix}-${i + currentInstances}'
      adminUsername: existingDomainUserName
      adminPassword: administratorAccountPassword
      windowsConfiguration: {
        enableAutomaticUpdates: false
        patchSettings: {
          patchMode: 'Manual'
        }
      }
    }
    storageProfile: {
      osDisk: {
        name: '${vmPrefix}-${i + currentInstances}-OS'
        managedDisk: {
          storageAccountType: vmDiskType
        }
        osType: 'Windows'
        createOption: 'FromImage'
      }
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-10'
        sku: '20h2-pro-g2'
        version: 'latest'
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${vmPrefix}-${i + currentInstances}${networkAdapterPostfix}')
        }
      ]
    }
  }
  dependsOn: [
    availabilitySet
    nic[i]
  ]
}]

resource joindomain 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = [for i in range(0, AVDnumberOfInstances): {
  name: '${vmPrefix}-${i + currentInstances}/joindomain'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      mdmid: ''
    }
  }
  dependsOn: [
    vm[i]
  ]
}]

resource dscextension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = [for i in range(0, AVDnumberOfInstances): {
  name: '${vmPrefix}-${i + currentInstances}/dscextension'
  location: location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.73'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: '${artifactsLocation}Configuration.zip'
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        'azureUserProfileShare': false
        'wvdRegistrationToken': avdregtoken
        'installCcmClient': 'false'
      }
    }
  }
  dependsOn: [
    vm[i]
    joindomain[i]
  ]
}]

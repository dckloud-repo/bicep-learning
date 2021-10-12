param artifactsLocation string = 'https://tobedeletedalreadytaken.blob.core.windows.net/dsc/'

@secure()
param AzTenantID string = '78be17d2-30b3-4f7d-91c9-236348af26d9'
param AVDnumberOfInstances int = 2
param currentInstances int = 0
//param newBuild bool 

@description('Location for all standard resources to be deployed into.')
param location string = 'australiaEast'
param hostPoolName string = 'dckloud-avd'
param domainToJoin string = 'dckloud.com'
@description('Name of resource group containing AVD HostPool')
param resourceGroupName string = resourceGroup().name

@description('OU Path were new AVD Session Hosts will be placed in Active Directory')
param ouPath string = 'OU=AVD,DC=dckloud,DC=com'
param appGroupName string = 'desktop-appgroup'
param desktopName string = 'desktop-appgroup'

@description('Application ID for Service Principal. Used for DSC scripts.')
param appID string = '5e8ec5fa-8369-45bc-b85a-e97de4a1141f'

@description('Application Secret for Service Principal.')
param appSecret string = 'hqy7Q~x-tXjwyRYfIjJdZpNcyMnMQIj6aJSAe'

@description('CSV list of default users to assign to AVD Application Group.')
param defaultUsers string
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

@description('Subscription containing the Shared Image Gallery')
param sharedImageGallerySubscription string = subscription().subscriptionId

@description('Resource Group containing the Shared Image Gallery.')
param sharedImageGalleryResourceGroup string = 'tobeDeleted'

@description('Name of the existing Shared Image Gallery to be used for image.')
param sharedImageGalleryName string = 'sharedavdgallery'

@description('Name of the Shared Image Gallery Definition being used for deployment. I.e: AVDGolden')
param sharedImageGalleryDefinitionname string = 'avdImage'

@description('Version name for image to be deployed as. I.e: 1.0.0')
param sharedImageGalleryVersionName string =  '0.0.1'

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
        //id: resourceId(sharedImageGalleryResourceGroup, 'Microsoft.Compute/galleries/images/versions', sharedImageGalleryName, sharedImageGalleryDefinitionname, sharedImageGalleryVersionName)
        id: '/subscriptions/${sharedImageGallerySubscription}/resourceGroups/${sharedImageGalleryResourceGroup}/providers/Microsoft.Compute/galleries/${sharedImageGalleryName}/images/${sharedImageGalleryDefinitionname}/versions/${sharedImageGalleryVersionName}'
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
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      name: domainToJoin
      ouPath: ouPath
      user: administratorAccountUserName
      restart: 'true'
      options: '3'
      NumberOfRetries: '4'
      RetryIntervalInMilliseconds: '30000'
    }
    protectedSettings: {
      password: administratorAccountPassword
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
        HostPoolName: hostPoolName
        ResourceGroup: resourceGroupName
        ApplicationGroupName: appGroupName
        DesktopName: desktopName
        AzTenantID: AzTenantID
        AppID: appID
        AppSecret: appSecret
        DefaultUsers: defaultUsers
        vmPrefix: vmPrefix
      }
    }
  }
  dependsOn: [
    vm[i]
    joindomain[i]
  ]
}]

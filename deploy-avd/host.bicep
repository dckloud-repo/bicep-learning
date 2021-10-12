/*param subscriptionId string = subscription().subscriptionId

param kvResourceGroup string

//Prefix for the AVD Virtual Machines
@description('AVD Virtual Machine Prefixes')
param vmPrefix string

//VM incremental number start integer
//this requires as there may be existing hosts in the pool
param startFrom int

//Number of hosts to deploy in the AVD
param hostCount int
*/
//Name of the keyVault
param keyVaultID string = '/subscriptions/6da6ad04-e536-4124-a437-c62b91ca3cff/resourceGroups/tobeDeleted/providers/Microsoft.KeyVault/vaults/testto'

//param networkAdapterPostfix string = 'nic'


//ID of the Subnet to VM to Deploy
//param subnetID string

@allowed([
  'Standard_B2ms'
  'Standard_D2s_v3'
])
param vmSize string

//adminPassword for the VM
@secure()
param adminPassword string

param domainName string = 'dckloud.com'

//VM Disk Type
param vmDiskType string

param sharedImageGallerySubscription string = subscription().subscriptionId

param sharedImageGalleryResourceGroup string = 'tobeDeleted'

param sharedImageGalleryName string = 'sharedavdgallery'

param sharedImageGalleryDefinitionname string = 'avdImage'

param sharedImageGalleryVersionName string = '0.0.1'

param diskType string = 'Premium_LRS'


resource deployVM 'Microsoft.DesktopVirtualization/hostPools/sessionHostConfigurations@2021-05-13-preview' = {
  name: 'dckloud-avd/hostpoolVm'
  properties: {
    diskType: diskType
    domainInfo: {
      credentials: {
        domainAdmin: {
          passwordKeyVaultResourceId: keyVaultID
          passwordSecretName: 'admin.dancha'
          userName: 'admin.dancha'
        }
        localAdmin: {
          passwordKeyVaultResourceId: keyVaultID
          passwordSecretName: 'admin.dancha'
          userName: 'admin.dancha'
        }
      }
      joinType: 'ActiveDirectory'
      //mdmProviderGuid: 'string'
      name: domainName
    }
    imageInfo: {
      //customId: 'string'
      marketPlaceInfo: {
        exactVersion: 'string'
        offer: 'string'
        publisher: 'string'
        sku: 'string'
      }
      //storageBlobUri: 'string'
      type: 'Gallery'
    }
    //vmCustomConfigurationUri: 'string'
    vMSizeId: vmSize
  }
}

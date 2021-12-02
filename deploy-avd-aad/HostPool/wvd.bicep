@description('AVD Host Location')
param avdHostLocation string = 'eastUS'

@description('Host Pool Friendly Name')
param hostPoolFriendlyName string

@description('Host Pool Type')
param hostPoolType string = 'Pooled'

@description('Location for all standard resources to be deployed into.')
param loadBalancerType string = 'BreadthFirst'

@description('Location for all standard resources to be deployed into.')
param preferredAppGroupType string = 'desktop'

@description('Location for all standard resources to be deployed into.')
param worksSpacefriendlyName string =  'Thrive Admin'

resource hostPool 'Microsoft.DesktopVirtualization/hostpools@2019-12-10-preview' = {
  name: 'dckloud-avd'
  location: avdHostLocation
  properties: {
    friendlyName: hostPoolFriendlyName
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    preferredAppGroupType: preferredAppGroupType
    registrationInfo: {
      expirationTime: '20'
      token: null
      registrationTokenOperation: 'Update'
    }
  }
}

resource workSpace 'Microsoft.DesktopVirtualization/workspaces@2019-12-10-preview' = {
  name: 'dckloud'
  location: 'eastus'
  properties: {
    friendlyName: worksSpacefriendlyName
  }
}

resource applicationGroup 'Microsoft.DesktopVirtualization/applicationgroups@2019-12-10-preview' = {
  name: 'desktop-appgroup'
  location: 'eastus'
  properties: {
    friendlyName: 'desktop-appgroup'
    applicationGroupType: 'Desktop'
    hostPoolArmPath: '${resourceGroup().id}/providers/Microsoft.DesktopVirtualization/hostPools/dckloud-avd'
  }
}




resource hostPool 'Microsoft.DesktopVirtualization/hostpools@2019-12-10-preview' = {
  name: 'dckloud-avd'
  location: 'eastus'
  properties: {
    friendlyName: 'dckloud-avd'
    hostPoolType: 'Pooled'
    loadBalancerType: 'BreadthFirst'
    preferredAppGroupType: 'Desktop'
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
    friendlyName: 'friendlyName'
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




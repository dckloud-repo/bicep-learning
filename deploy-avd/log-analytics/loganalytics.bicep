resource avdLogAnalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: 'dckloud-logAnalytics'
  location: resourceGroup().location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

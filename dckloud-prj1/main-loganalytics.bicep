targetScope = 'subscription'
//Parameters
param  location string =  'Australia East'

param locationshortName string = 'ae'

param projectName string = 'lab'

//Variables
var logAnalyticsName = '${locationshortName}${projectName}log'


resource myresourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'lab-bicep'
  location: location
}

module logAnalytics 'module/loganalytics/log.bicep' = {
  scope: resourceGroup(myresourceGroup.name)
  name: 'deployLogAnalytics'
  params: {
    name: logAnalyticsName
  }
}

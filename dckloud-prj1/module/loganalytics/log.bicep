//Parameters 
param retentioninDays int = 90

param name string

param capacityReservation int = 0

//Variables

//Resources
resource loganalytics 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: name
  location: resourceGroup().location
  properties:{
    sku:{
      name :'PerGB2018'
      capacityReservationLevel: (capacityReservation == 0) ? json('null') : capacityReservation
       }
       retentionInDays:retentioninDays
       features:{
        searchVersion:1
        enableLogAccessUsingOnlyResourcePermissions: true
       }
  }
}

output name string = loganalytics.name
output id string = loganalytics.id

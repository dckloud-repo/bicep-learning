//Defining Parameters to build a virtual machine

@description('Name of the Virtual Machine')
param VMName string = 'audc01'

@description('ID of the Virtual Network which is going to be part of this')
param VNetId string = '/subscriptions/6da6ad04-e536-4124-a437-c62b91ca3cff/resourceGroups/Shared-RG/providers/Microsoft.Network/virtualNetworks/SharedService-VNET'

@description('location of the resources')
param Location string = resourceGroup().location

@description('Name of the subnet the VM going to be part of')
param SubNetName string = 'SharedService-SN'

@description('Name of the OS Disk')
param OSDiskName string = 'audc01_osdisk'

@description('Network Interface Name')
param NICName string = 'audc01_nic01'

@description('Name of the PublicIP address')
param PublicIPAddressName string = 'audc01_pubip'

resource VM_PublicIP 'Microsoft.Network/publicIPAddresses@2021-02-01' ={
  name:PublicIPAddressName
  location: Location
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource NIC_VM 'Microsoft.Network/networkInterfaces@2020-08-01' = {
  name: NICName
  location: Location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: VM_PublicIP.id
          }
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${VNetId}/subnets/${SubNetName}'
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    dnsSettings: {
      dnsServers: []
    }
    enableAcceleratedNetworking: false
    enableIPForwarding: false
  }
}

resource VirtualMachine 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: VMName
  location: Location
  properties:{
    hardwareProfile: {
      vmSize:'Standard_B2ms'
      }
      storageProfile: {
        osDisk: {
          name: OSDiskName
          createOption: 'FromImage'
          osType: 'Windows'
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
        }
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2019-Datacenter'
          version: 'latest'
        }
      }
      osProfile: {
        computerName: VMName
        adminUsername: 'admin.dancha'
        adminPassword: 'Domain@AVD2021'
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: NIC_VM.id
          }
        ]
      }
  }
}

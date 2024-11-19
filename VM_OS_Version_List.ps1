
Set-Azcontext -Subscription "<Subscription ID>"
# Get the list of VMs
$vms = Get-AzVM -Status

# Initialize an array to hold the VM details
$vmDetails = @()

foreach ($vm in $vms) {
    # Get the VM's OS details
    $computername = $vm.Name
    $osfullversion = $vm.OsVersion
    $osname = $vm.OsName

    

    # Get the subscription name
    $subscriptionId = '<Subscription ID>'
    $subscriptionName = '<Subscription ID>'

    # Add VM details to the array
    $vmDetails += [pscustomobject]@{
        ComputerName      = $computername
        SubscriptionName  = $subscriptionName
        OsVersion = $osfullversion
        OsName = $osname
  }
}

# Export the VM details to a CSV file
$vmDetails | Export-Csv -Path "<path\filename.csv>" -NoTypeInformation

Write-Output "VM details have been exported to path\filename.csv"




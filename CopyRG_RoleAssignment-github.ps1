<# subscriptionID = '<sub ID>'
$tenantDomain = '<yourtenant>.onmicrosoft.com'
$environment = 'AzureUSGovernment'
 
 
$paramConnectAzAccount = @{
            subscriptionId = $subscriptionID
            Tenant       = $tenantDomain
            Environment  = $environment
            ErrorAction    = 'Stop'
        }
 
        $env:HTTPS_PROXY=""
        $env:NO_PROXY="*"
 
Connect-AzAccount @paramConnectAzAccount -UseDeviceAuthentication
#>
$subscriptionID = '<sub ID>'
$rgname1 = "<source RG>"
$rgname2 = "<destination RG>"
# Variables for the source and destination subscriptions
$sourcerg = Get-AzResourceGroup -Name $rgname1
$destinationrg = Get-AzResourceGroup -Name $rgname2

Set-AzContext -SubscriptionId $subscriptionId

# Get a list of all role assignments in the source resource group
$roleAssignments = Get-AzRoleAssignment -ResourceGroupName $sourcerg


foreach ($roleAssignment in $roleAssignments) {
    # Check if the resource group exists
    $resourceGroup = Get-AzResourceGroup -Name $destinationrg.ResourceGroupName
    if ($resourceGroup -eq $null) {
        Write-Error "Resource group '$destinationrg' not found."
    if ($roleAssignment.DisplayName -imatch 'SG-*'){
            write-host $roleAssignment.DisplayName -ForegroundColor Yellow
        continue
    }
    
    }
    write-host "role assignment" $roleAssignment.ObjectId && $roleAssignment.DisplayName
    #Attempt to create the role assignment
    try {
        New-AzRoleAssignment -ObjectId $roleAssignment.ObjectId -RoleDefinitionName $roleAssignment.RoleDefinitionName -ResourceGroupName $destinationrg.ResourceGroupName
    } catch {
        Write-Error "Failed to create role assignment for ObjectId '$roleAssignment.ObjectId' with RoleDefinitionName '$roleAssignment.RoleDefinitionName'. Error: $_"
    }
}
#>

# Confirm the number of role assignments in the destination resource group
Write-Output "Role assignments copied from" $sourcerg.ResourceGroupName "to" $destinationrg.ResourceGroupName
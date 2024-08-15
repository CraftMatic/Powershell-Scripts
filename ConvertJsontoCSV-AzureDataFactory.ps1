$Storageaccountkey = "<SA KEY>"
$azureAplicationId ="<Service principal app ID>"
$azureTenantId= "<tenant ID>"
$environment = "AzureUSGovernment"
$azurePassword = ConvertTo-SecureString "<service pricipal secret key>" -AsPlainText -Force
$psCred = New-Object -TypeName System.Management.Automation.PSCredential($azureAplicationId , $azurePassword)
Connect-AzAccount -environment $environment -Credential $psCred -TenantId $azureTenantId -ServicePrincipal

#future auth
#$SecureStringPwd = $sp.PasswordCredentials.SecretText | ConvertTo-SecureString -AsPlainText -Force
#$pscredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sp.AppId, $SecureStringPwd
#Connect-AzAccount -ServicePrincipal- $environment -Credential $pscredential -Tenant $azureTenantId

Set-AzContext -Subscription "<Sub ID>"
$resourceGroupName = "<Resource Group Name>"
$storageAccountName = "<SA Name>"

Set-AzCurrentStorageAccount -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $Storageaccountkey -environment $environment
# Download the .json file to the runbook temp folder
Get-AzStorageBlobContent -Container "<Container Name>" -Blob "Output.json" -Context $context -Destination "$env:temp\" | Out-Null

$jsonContent = Get-Content -Raw -Path "$env:temp\Output.json" | ConvertFrom-Json

# select the primary results table
$primaryResultTable = $jsonContent.tables | Where-Object { $_.name -eq "PrimaryResult" }

# extract the json objects for columns and rows
$columns = $primaryResultTable.columns
$rows = $primaryResultTable.rows

# Create an array to save the data in tabular format
$csvData = @()

# Convert rows to custom object so we can iterate through it
foreach ($row in $rows) {
    $rowData = [PSCustomObject]@{
        Computer = $row[0]
        SoftwareName = $row[1]
        TimeGenerated = $row[2]
    }
    $csvData += $rowData

}

# Export data and write it to csv format. CSV
$csvData | Export-Csv -Path "$env:temp\output $(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').csv" -NoTypeInformation


# upload a file to the default account (inferred) access tier
$Blob1HT = @{
  File             = "$env:temp\output_IL4 $(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').csv"
  Container        = "<container name>"
  Blob             = "output $(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').csv"
  Context          = $context
  StandardBlobTier = 'Hot'}

Set-AzStorageBlobContent @Blob1HT


#Write-Host $csvData.Count "Rows written"

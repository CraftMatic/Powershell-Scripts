#This is an alternate script to allow for ingesting and transformation of .data type json format instead of the tables data format found in "ConvertJsontoCsv-AzureDataFactory.ps1

$Storageaccountkey = "<SA KEY>"
$azureAplicationId = "<APP ID>"
$azureTenantId = "<Tenant ID>"
$environment = "<Azure Environment>"
$azurePassword = ConvertTo-SecureString "<App secret>" -AsPlainText -Force
$psCred = New-Object -TypeName System.Management.Automation.PSCredential($azureAplicationId, $azurePassword)
Connect-AzAccount -environment $environment -Credential $psCred -TenantId $azureTenantId -ServicePrincipal

Set-AzContext -Subscription "<SUB ID>"
$resourceGroupName = "<Resource Group>"
$storageAccountName = "<SA NAME>"

Set-AzCurrentStorageAccount -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $Storageaccountkey -environment $environment

$jsonContainer = "<containter where JSON file is found>"
$jsonBlob = ("<name of json file>")
$csvContainer = ("<Destination container for csv>")


# Download the .json file to the runbook temp folder
Get-AzStorageBlobContent -Container $jsonContainer -Blob $jsonBlob -Context $context -Destination "$env:temp\" | Out-Null

$jsonContent = Get-Content -Raw -Path $env:temp\$jsonblob | ConvertFrom-Json

$table = $jsonContent.data

# Extract the json objects for columns and rows
$columns = $table[0].PSObject.Properties.Name

# Create an array to save the data in tabular format
$csvData = @()

# Convert rows to custom object so we can iterate through it
foreach ($row in $table) {
    $rowData = [PSCustomObject]@{}
    foreach ($column in $columns) {
        $rowData | Add-Member -MemberType NoteProperty -Name $column -Value $row.$column
    }
    $csvData += $rowData
}

# Export data and write it to csv format
$outputCsvPath = "$env:temp\output_$($i+1)_$(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').csv"
$csvData | Export-Csv -Path $outputCsvPath -NoTypeInformation

    # Upload the CSV file to the specified container
 $BlobHT = @{
        File             = $outputCsvPath
        Container        = $csvContainer
        Blob             = "additional_output_$($i+1)_$(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').csv"
        Context          = $context
        StandardBlobTier = 'Hot'
}

    Set-AzStorageBlobContent @BlobHT


$Storageaccountkey = "<SA a=Account>"
$azureAplicationId = "<APP ID>"
$azureTenantId = "<Tenant ID>"
$environment = "<Azure Environment>"
$azurePassword = ConvertTo-SecureString "<APP Secret>" -AsPlainText -Force
$psCred = New-Object -TypeName System.Management.Automation.PSCredential($azureAplicationId, $azurePassword)
Connect-AzAccount -environment $environment -Credential $psCred -TenantId $azureTenantId -ServicePrincipal

Set-AzContext -Subscription "<SUB ID>"
$resourceGroupName = "<Resource Group>"
$storageAccountName = "<Storage Account>"

Set-AzCurrentStorageAccount -ResourceGroupName $resourceGroupName -StorageAccountName $storageAccountName
$context = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $Storageaccountkey -environment $environment

$jsonContainer = "tradoc-adf"
$jsonBlobs = @("<jsonblob1.json>","<jsonblob2.json>")
$csvContainers = @("<container1>", "<container2>")

for ($i = 0; $i -lt $jsonBlobs.Length; $i++) {
    $jsonBlob = $jsonBlobs[$i]
    $csvContainer = $csvContainers[$i]

    # Download the .json file to the runbook temp folder
    Get-AzStorageBlobContent -Container $jsonContainer -Blob $jsonBlob -Context $context -Destination "$env:temp\" | Out-Null

    $jsonContent = Get-Content -Raw -Path "$env:temp\$jsonBlob" | ConvertFrom-Json

    # Select the primary results table
    $primaryResultTable = $jsonContent.tables | Where-Object { $_.name -eq "PrimaryResult" }

    # Extract the json objects for columns and rows
    $columns = $primaryResultTable.columns
    $rows = $primaryResultTable.rows

    # Create an array to save the data in tabular format
    $csvData = @()

    # Convert rows to custom object so we can iterate through it
    foreach ($row in $rows) {
        $rowData = [PSCustomObject]@{}
        for ($j = 0; $j -lt $columns.Length; $j++) {
            $rowData | Add-Member -MemberType NoteProperty -Name $columns[$j].name -Value $row[$j]
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
        Blob             = "output_$($i+1)_$(Get-Date -Format 'yyyy-MM-dd HH-mm-ss').csv"
        Context          = $context
        StandardBlobTier = 'Hot'
    }

    Set-AzStorageBlobContent @BlobHT
}

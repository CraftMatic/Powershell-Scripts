$sourcePAT = "<Enter source PAT>"
$sourceEncodedPAT = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$sourcePAT")) }
$sourceOrg = "<Enter source Org URL>"
$sourceProject = "<Project Name>"

$destOrg = "<Destination URL>"
$destProject = "<Destination Project>"
$destPAT = "<Enter Destination PAT>"
$destEncodedPat = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$destPAT")) }

#gets full list of work items to iterate through to check if they have related items
$wiql = @{
    query = "SELECT [System.Id]
            FROM WorkItems
            WHERE [System.TeamProject] = '$sourceProject'"
}

$workItems = Invoke-RestMethod `
    -Uri "$sourceOrg/$sourceProject/_apis/wit/wiql?api-version=5.1" `
    -Method Post `
    -Headers $sourceEncodedPAT `
    -Body ($wiql | ConvertTo-Json -Depth 10) `
    -ContentType "application/json"

#for debug only
$totalnumber = 0

$arrayworkItemsIds = $workItems.workItems | ForEach-Object {$_.id}

write-output "How many work items before execution: $($arrayworkItemsIds.Count)"

foreach($workItem in $arrayWorkItemsIds){

    $destWiql = @{
            query = "SELECT [System.Id]
                    FROM WorkItems
                    WHERE [System.TeamProject] = 'HQ-G2-<Enter source Project>'
                    AND [Custom.LegacyID] =  '$workItem'"
                    }
    $destIoWiql = ConvertTo-Json -InputObject $destWiql -Depth 10

    $destWorkItemId = Invoke-RestMethod -Uri "$destOrg/$destProject/_apis/wit/wiql?api-version=7.1" -Method Post -Headers $destEncodedPAT -Body $destIoWiql -ContentType "application/json"

    $cleanedDestWorkItem = $destWorkItemId.workItems[0].id

    $destUrl = "$destOrg/$destProject/_apis/wit/workitems/"+  $cleanedDestWorkItem  + "?api-version=7.1"
    Write-Output "Dest url is : " $destUrl
    write-output "current legacy ID: " $workItem

    $sourceUrl = "$sourceOrg/$sourceProject/_apis/wit/workitems/"+  $workItem  + "?`$expand=relations&api-version=5.1"

    $sourceResponse = Invoke-RestMethod -Uri $sourceUrl -Headers $sourceEncodedPAT -Method Get
    # Step 2: extract relevant data

    #Needs to be an array as if it returns only one item it does not count it if it is not in an array
    $relationCount = @($sourceResponse.relations | Where-Object { $_.rel -contains "System.LinkTypes.Hierarchy"}).Count

    #can remove later
    Write-Output "This is the amount of related items: " $relationCount
    #loop through each relationship in the list of relationships
    for (($index = 0); $index -lt $relationCount; $index++){
        #pulls ID from url
        $linkedItemId =  $sourceResponse.relations[$index].url.Split('/')[-1]
        write-output "This is the Legacy ID of the related Item:" $linkedItemId

        #pull related
        #$relationType = $sourceResponse.relations[$index].attributes.name

        $wiql = @{
            query = "SELECT [System.Id]
                    FROM WorkItems
                    WHERE [System.TeamProject] = '$destProject'
                    AND [Custom.LegacyID] =  '$linkedItemId'"
                    }
        $iowiql = ConvertTo-Json -InputObject $wiql -Depth 10

        $relatedItem = Invoke-RestMethod -Uri "$destOrg/$destProject/_apis/wit/wiql?api-version=7.1" -Method Post -Headers $destEncodedPAT -Body $iowiql -ContentType "application/json"


        #This will always remain zero because it is a 1 to 1 with the legacy ID that the loop is passing to the WIQL
        $cleanedRelatedItem = $relatedItem.workItems[0].id
        Write-Output "Destination ID of the related work item: " $cleanedRelatedItem

            $body = @(
                @{
                    op   = "add"
                    path = "/relations/-"
                    value = @{
                        rel = "System.LinkTypes.Related"
                        url = "<Enter your Dest Org URL>/HQ-G2-<Enter source Project>/_apis/wit/workItems/$cleanedRelatedItem"
                    }
                }
            ) 
        $bodyJson = ConvertTo-Json -InputObject $body -Depth 10
        #Debug content its pushing
        #Write-Output "Here is the body Json: " $bodyJson
        
        Invoke-RestMethod -Uri $destUrl -Method Patch -Body $bodyJson -ContentType "application/json-patch+json" -Headers $destEncodedPat
    }
}    


#$sourceUrlId =  $sourceResponse.relations[0].url.Split('/')[-1] | Out-File C:\Users\1506247540121005.CTR\Downloads\relations.txt
#$sourceAttributes =  $sourceResponse.relations[0].attributes.name | Out-File C:\Users\1506247540121005.CTR\Downloads\attributes.txt
#write-output $body[0].Values[0]


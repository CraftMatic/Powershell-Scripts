$sourcePAT = "<Enter Source PAT>"
$sourceEncodedPAT = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$sourcePAT")) }
$sourceOrg = "<Enter your Source Org URL>"
$sourceProject = "<Enter source Project>"

$destOrg = "<Enter your Dest Org URL>"
$destProject = "<Enter Dest Project>"
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
#part of run limitation for debugging
#$countoffoundparents = 0
foreach($workItem in $arrayWorkItemsIds){

    $destWiql = @{
            query = "SELECT [System.Id]
                    FROM WorkItems
                    WHERE [System.TeamProject] = '<Enter Dest Project>'
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
    $relationCount = @($sourceResponse.relations | Where-Object { $_.rel -eq "System.LinkTypes.Hierarchy-Reverse"}).Count

    #can remove later
    Write-Output "This is the amount of related items: " $relationCount

    #where we removed for loop-------------------->
    if ($relationCount -eq 1){
        #pulls ID from url
        $matchingRelations = $sourceResponse.relations | Where-Object {$_.rel -eq "System.LinkTypes.Hierarchy-Reverse"}
        Write-Output "This is before the split" $matchingRelations
        $linkedItemId = $matchingRelations[0].url.Split('/')[-1]

       
        write-output "This is the Legacy ID of the parent Item:" $linkedItemId

        $wiql = @{
            query = "SELECT [System.Id]
                    FROM WorkItems
                    WHERE [System.TeamProject] = '$destProject'
                    AND [Custom.LegacyID] =  '$linkedItemId'"
                    }
        $iowiql = ConvertTo-Json -InputObject $wiql -Depth 10

        $relatedItem = Invoke-RestMethod -Uri "$destOrg/$destProject/_apis/wit/wiql?api-version=7.1" -Method Post -Headers $destEncodedPAT -Body $iowiql -ContentType "application/json"

        #destroy me
        $jsonrelateditem = $relatedItem | ConvertTo-Json -Depth 100
        #$jsonrelateditem | Out-File -FilePath ("C:\Users\1506247540121005.CTR\Downloads\relateditemprint" + (Get-Date).Millisecond + ".json")

        #This will always remain zero because it is a 1 to 1 with the legacy ID that the loop is passing to the WIQL
        $cleanedRelatedItem = $relatedItem.workItems[0].id
        Write-Output "Destination ID of the parent work item: " $cleanedRelatedItem

            $body = @(
                @{
                    op   = "add"
                    path = "/relations/-"
                    value = @{
                        rel = "System.LinkTypes.Hierarchy-Reverse"
                        url = "<Enter your Dest Org URL>/<Enter Dest Project>/_apis/wit/workItems/$cleanedRelatedItem"
                    }
                }
            ) 
        $bodyJson = ConvertTo-Json -InputObject $body -Depth 10
        $bodyjsonprint = $bodyJson
        $bodyjsonprint | Out-File -FilePath "C:\Users\1506247540121005.CTR\Downloads\bodyjsonprint.json" -Append
        #Debug content its pushing
        #Write-Output "Here is the body Json: " $bodyJson
        
        Invoke-RestMethod -Uri $destUrl -Method Patch -Body $bodyJson -ContentType "application/json-patch+json" -Headers $destEncodedPat 
        
        #debug to control amount of parents that pass
        #$countoffoundparents++
        #if ($countoffoundparents -eq 10){
        #break  }
    }
}


#$sourceUrlId =  $sourceResponse.relations[0].url.Split('/')[-1] | Out-File C:\Users\1506247540121005.CTR\Downloads\relations.txt
#$sourceAttributes =  $sourceResponse.relations[0].attributes.name | Out-File C:\Users\1506247540121005.CTR\Downloads\attributes.txt
#write-output $body[0].Values[0]


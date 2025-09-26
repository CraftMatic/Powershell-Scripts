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

$arrayworkItemsIds = $workItems.workItems | ForEach-Object {$_.id}

#from when we ran only one work item for debugging
#$oneworkitem = $arrayworkItemsIds[0]
foreach ($oneworkitem in $arrayworkItemsIds){
    try{
        $destWiql = @{
                    query = "SELECT [System.Id]
                            FROM WorkItems
                            WHERE [System.TeamProject] = '<Enter Dest Project>'
                            AND [Custom.LegacyID] =  '$oneworkitem'"
                            }
        $destIoWiql = ConvertTo-Json -InputObject $destWiql -Depth 10

        $destresponse = Invoke-RestMethod -uri "$destOrg/$destProject/_apis/wit/wiql?api-version=7.1" -Method Post -Headers $destEncodedPAT -Body $destIoWiql -ContentType "application/json" 
        $destoneWorkItem =  $destresponse.workItems[0].id

        Write-Output "this is the Destination work item id:" $destoneworkitem

        $sourceUrl = "$sourceOrg/$sourceProject/_apis/wit/workitems/"+  $oneworkitem  + "?api-version=5.1&`$expand=relations"

        $sourceResponse = Invoke-RestMethod -Uri $sourceUrl -Headers $sourceEncodedPAT -Method Get
        $stateinfo = $sourceResponse.fields.'System.State'


        Write-Output "State current work item: " $stateinfo

                    $body = @(
                        @{
                op    = "add"
                path  = "/fields/System.State"
                value = $stateinfo
                        }

                            ) 
        $bodyJson = ConvertTo-Json -InputObject $body -Depth 10

        $destUrl = "$destOrg/$destProject/_apis/wit/workitems/"+  $destoneworkitem  + "?api-version=7.1"
        Write-Output "This is the dest url" $destUrl

        $response = Invoke-RestMethod -Uri $destUrl -Headers $destEncodedPat -Method Patch -ContentType "application/json-patch+json" -Body $bodyJson
    }
    catch {
        Write-Error "$($_.Exception.Message)"
        }
}
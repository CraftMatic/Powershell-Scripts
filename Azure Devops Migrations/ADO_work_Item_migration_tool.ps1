Add-Type -AssemblyName System.web
# Define source and destination details
$sourceOrg = "<Enter your Source Org URL>"
$sourceProject = "<Enter source Project>"
$sourcePAT = "<Enter Source PAT>"

$destOrg = "<Enter your Dest Org URL>"
$destProject = "<Enter Dest Project>"
$destPAT = "<Enter Destination PAT>"

$sourceEncodedPAT = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$sourcePAT")) }
$destEncodedPat = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$destPAT")) }

# Work item ID to migrate
#$workItemId = Read-Host "Enter the Work Item ID to migrate"

# Helper: Create authorization header
<#function Get-AuthHeader($pat) {
    $token = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
    return @{ Authorization = "Basic $token" }
}#>

$wiql = @{
    query = "SELECT [System.Id]
            FROM WorkItems
            WHERE [System.TeamProject] = '<Enter source Project>'"
}

$workItems = Invoke-RestMethod `
    -Uri "$sourceOrg/$sourceProject/_apis/wit/wiql?api-version=5.1" `
    -Method Post `
    -Headers $sourceEncodedPAT `
    -Body ($wiql | ConvertTo-Json -Depth 10) `
    -ContentType "application/json"

$totalnumber = 0

$arrayworkItemsIds = $workItems.workItems | ForEach-Object {$_.id}

write-output "How many work items before execution: $($arrayworkItemsIds.Count)"

foreach($workItem in $arrayWorkItemsIds){

# Step 1: Get work item from source
$sourceUrl = "$sourceOrg/$sourceProject/_apis/wit/workitems/"+  $workItem  + "?api-version=5.1&`$expand=relations"

$sourceHeaders = $sourceEncodedPAT
$sourceResponse = Invoke-RestMethod -Uri $sourceUrl -Headers $sourceHeaders -Method Get


#Do not delete so important for adding relationships - grabs id at the end of url
#$sourceUrlId =  $sourceResponse.relations[0].url.Split('/')[-1]
#$sourceAttributes =  $sourceResponse.relations[0].attributes.name

# Extract fields
$title = $sourceResponse.fields.'System.Title'
$title = $title -replace '[“”]', '"'      # Replace smart quotes
if ($null -eq $title){$title = ""}

$workItemType = $sourceResponse.fields.'System.WorkItemType'
if ($null -eq $workItemType){$workItemType = ""}

$content = $sourceResponse.fields.'System.Description'
$content = $content -replace '[\u200B-\u200D\uFEFF\u2028\u2029]', ''  # Remove zero-width chars
$content = $content -replace '[“”]', '"'                 # Replace smart quotes
$description = $content -replace '\r|\n|\t', ' '  # Remove line breaks and tabs
$description = $description.Trim()
$regex = [regex]::Replace($description, "<[^>]+>", "")
$decoded = [System.Web.HttpUtility]::HtmlDecode($regex)
$eDesc1 = $decoded -replace '\s{2,}', ' ' -replace '\r?\n', "`n"
$eDesc1 = $eDesc1.Trim()
$eDesc2 = [System.Text.Encoding]::ASCII.GetBytes($eDesc1)
$eDesc = [System.Text.Encoding]::ASCII.GetString($eDesc2)
if ($null -eq $eDesc){$eDesc = ""}
if ($eDesc -contains "img src="){$eDesc = ""}

$legacyId = $sourceResponse.id
if ($null -eq $legacyId){$legacyId = 0}

$storyPoints = $sourceResponse.fields.'Microsoft.VSTS.Scheduling.StoryPoints'
if ($null -eq $storyPoints){$storyPoints = 0.0}

$tags = $sourceResponse.fields.'System.Tags'
if ($null -eq $tags){$tags = ""}

#$aCrit = $sourceResponse.fields.'Microsoft.VSTS.Common.AcceptanceCriteria'
#if ($null -eq $aCrit) { $aCrit = "" }

$priority = $sourceResponse.fields.'Microsoft.VSTS.Common.Priority'
if ($null -eq $priority){$priority = 0}

$stackRank = $sourceResponse.fields.'Microsoft.VSTS.Common.StackRank'
if ($null -eq $stackRank){$stackRank = 0.0}

$valueArea = $sourceResponse.fields.'Microsoft.VSTS.Common.ValueArea'
if ($null -eq $valueArea){$valueArea = ""}

#Has to be set to new for import into ADO
$state = "New"

#For debugging only
Write-Host "Migrating '$title' ($workItemType)"

# Step 2: Create work item in destination
$destUrl = "$destOrg/$destProject/_apis/wit/workitems/`$"+  $workItemType  + "?api-version=7.1"
$destHeaders = $destEncodedPat
$body = @(
    @{
        op    = "add"
        path  = "/fields/System.Title"
        value = $title
    },
    @{
        op    = "add"
        path  = "/fields/System.Description"
        value = $eDesc
    },
    @{
        op    = "add"
        path  = "/fields/Custom.LegacyId"
        value = $legacyId
    },
    @{
        op    = "add"
        path  = "/fields/System.Tags"
        value = $tags
    },
    @{
        op    = "add"
        path  = "/fields/Microsoft.VSTS.Common.Priority"
        value = $priority
    },
    @{
        op    = "add"
        path  = "/fields/Microsoft.VSTS.Common.StackRank"
        value = $stackRank
    },
    @{
        op    = "add"
        path  = "/fields/Microsoft.VSTS.Common.ValueArea"
        value = $valueArea
    },
    @{
        op    = "add"
        path  = "/fields/System.WorkItemType"
        value = $workItemType
    },
    @{
        op    = "add"
        path  = "/fields/System.State"
        value = $state
    }

) | ConvertTo-Json -Depth 2

write-output "----------------------------------------------------------------"
Write-Output "Title: $title"
Write-Output "Type: $workItemType"
Write-Output "Description: $eDesc"
Write-Output "Legacy ID: $legacyId"
Write-Output "Story Points: $storyPoints"
Write-Output "Tags: $tags"
#Write-Output "Acceptance Criteria: $aCrit"
Write-Output "Priority: $priority"
Write-Output "Stack Rank: $stackRank"
Write-Output "Value Area: $valueArea"
Write-Output "State: $state"
write-output "----------------------------------------------------------------"

$response = Invoke-RestMethod -Uri $destUrl -Headers $destHeaders -Method Patch -ContentType "application/json-patch+json" -Body $body

Write-Host "Work item created in destination project: ID $($workItem)"

$totalnumber++

Write-Output "This is the total so far: $($totalnumber) " 
}

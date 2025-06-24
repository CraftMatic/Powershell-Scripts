$sourcePat = Read-Host "Enter your PAT"
$sourceAuthHeader = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$sourcePat")) }
$organization = Read-host "Enter your organization: "
$project = Read-host "Enter your project from which the repo was deleted: "
$repository = Read-host "Enter the repository ID that was deleted: "

#PATCH https://dev.azure.com/{organization}/{project}/_apis/git/recycleBin/repositories/{repositoryId}?api-version=7.1

# Set headers
$headers = @{
    Authorization = "Basic $sourceAuthHeader"
    "Content-Type" = "application/json"
}

# Set the request body
$body = @{ deleted = $false } | ConvertTo-Json

# Construct the URL
$url = "https://dev.azure.com/$organization/$project/_apis/git/recycleBin/repositories/$repositoryId?api-version=7.1"
#$url.RawContent - if you want to see the raw response.

# Send the PATCH request
$response = Invoke-RestMethod -Uri $url -Method Patch -Headers $headers -Body $body

# Output the response
$response

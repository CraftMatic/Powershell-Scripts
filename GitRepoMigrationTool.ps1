# Variables - Update these
$sourceOrg = Read-Host "Enter your source devops org URL"
$sourceProject = Read-Host "Input Name of existing project"
$sourcePat = Read-Host "Enter your Source PAT: "

$destOrg = Read-Host "Enter the name of your destination devops org (example: https://devops.azure.com/project1)"
$destProject = Read-Host "Enter the name of your new project"
$destPat = Read-Host "Enter destination PAT: "

# Base64 encode for API auth headers
$sourceAuthHeader = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$sourcePat")) }
$destAuthHeader = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$destPat")) }
NOTE: the API version will differ depending on the version of your devops server.
$allRepos = Invoke-RestMethod -Uri "$sourceOrg/$sourceProject/_apis/git/repositories?api-version=5.1" -Headers $sourceAuthHeader


# Filter by project name
$repos = $allRepos.value | Where-Object { $_.project.name -eq $sourceProject }

Write-Host "Found $($repos.Count) repositories in project '$sourceProject'."


foreach ($repo in $repos) {
    $repoName = $repo.name
    $sourceGitUrl = $repo.remoteUrl

    Write-Host "`n==> Cloning $repoName from source project..."
    git clone --mirror $sourceGitUrl

    # Switch into cloned repo
    Set-Location "C:\${repoName}.git"

    # Check if destination repo exists. NOTE: the API version will differ depending on the version of your devops server.
    $destRepoCheckUri = "$destOrg/$destProject/_apis/git/repositories/$repoName?api-version=7.1"
    $response = Invoke-WebRequest -Uri $destRepoCheckUri -Headers $destAuthHeader -Method Get -UseBasicParsing -ErrorAction SilentlyContinue

    if ($response.StatusCode -ne 200) {
        Write-Host "Creating $repoName in destination project..."
        $body = @{ name = $repoName } | ConvertTo-Json
        #NOTE: the API version will differ depending on the version of your devops server.
        $createUri = "$destOrg/$destProject/_apis/git/repositories?api-version=7.1"
        Invoke-RestMethod -Uri $createUri -Method Post -Headers $destAuthHeader -Body $body -ContentType "application/json"
    } else {
        Write-Host "$repoName already exists in destination project."
    }

    # Push mirror to destination
    $destGitUrl = "$destOrg/$destProject/_git/$repoName"
    git remote set-url origin $destGitUrl
    git push --mirror

    Set-Location ..
    Remove-Item -Recurse -Force "$repoName.git"
}

# Assuming repoOwner, repoName, and GITHUB_TOKEN are set as environment variables or action inputs
$repoOwner = `${{ github.repository_owner }}`
$repoName = `${{ github.event.repository.name }}`
$GITHUB_TOKEN = $env:GITHUB_TOKEN
$maxChangesForLabel = $env:MAX_CHANGES_FOR_LABEL
$labelMessage = $env:LABEL_MESSAGE

# Base64 encode the GitHub Token
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$GITHUB_TOKEN"))

function Add-LabelToPullRequest {
    param (
        [int]$prNumber,
        [string]$label
    )
    $labelUri = "https://api.github.com/repos/$repoOwner/$repoName/issues/$prNumber/labels"
    $body = @{
        labels = @($label)
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $labelUri -Method POST -Headers @{
        Authorization = "Basic $base64AuthInfo"
        Accept        = "application/vnd.github.v3+json"
    } -Body $body -ContentType "application/json"
}

function Add-CommentToPullRequest {
    param (
        [int]$prNumber,
        [string]$comment
    )
    $commentUri = "https://api.github.com/repos/$repoOwner/$repoName/issues/$prNumber/comments"
    $body = @{
        body = $comment
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $commentUri -Method POST -Headers @{
        Authorization = "Basic $base64AuthInfo"
        Accept        = "application/vnd.github.v3+json"
    } -Body $body -ContentType "application/json"
}

$uri = "https://api.github.com/repos/$repoOwner/$repoName/pulls?state=open"
$response = Invoke-RestMethod -Uri $uri -Method Get -Headers @{
    Authorization = "Basic $base64AuthInfo"
    Accept        = "application/vnd.github.v3+json"
}

foreach ($pr in $response) {
    $prNumber = $pr.number
    $additions = $pr.additions
    $deletions = $pr.deletions
    $totalChanges = $additions + $deletions

    if ($totalChanges -le $maxChangesForLabel) {
        Add-LabelToPullRequest -prNumber $prNumber -label "Potential Spam"
        Add-CommentToPullRequest -prNumber $prNumber -comment $labelMessage
    }
}

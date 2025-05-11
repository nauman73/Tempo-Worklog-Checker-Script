<#
.SYNOPSIS
    Tempo Worklog Checker Script

.DESCRIPTION
    Retrieves Tempo Timesheets worklogs for multiple users and filters issues matching a specific
    issue type. The script will include issues that directly match the type, as well as parent/child
    issues that match the specified type. Filtered issue IDs are saved to a file and processed for
    the report.

.PARAMETER tempoApiToken
    Tempo API token (default: "your_default_tempo_api_token_here")

.PARAMETER userEmails
    Array of email addresses of the users to include in results. The script will look up account IDs and names.

.PARAMETER jiraBaseUrl
    Base URL of your Jira Cloud instance (default: "https://yourcompany.atlassian.net")

.PARAMETER jiraEmail
    Jira user email for API access (default: "you@company.com")

.PARAMETER jiraApiToken
    Jira API token (default: "your_default_jira_api_token_here")

.PARAMETER tempoBaseUrl
    Base URL of Tempo API (default: "https://api.tempo.io")

.PARAMETER tempoApiBase
    Tempo API versioned base path (default: "$tempoBaseUrl/4")

.PARAMETER dateFrom
    Start date of the date range (default: "2025-04-01")

.PARAMETER dateTo
    End date of the date range (default: "2025-04-30")

.PARAMETER includeIssueTypes
    Array of issue types to include in the result (default: @("Story"))

.PARAMETER offset
    Starting offset for Tempo API pagination (default: 0)

.PARAMETER limit
    Number of records per Tempo API page (default: 50)

.PARAMETER maxPages
    Maximum number of API pages to retrieve (default: 100)

.PARAMETER outputFolder
    Path where output files will be stored (default: ".\Output")

.PARAMETER issueWorklogsDir
    Path where issue worklog files will be stored (default: ".\Output\issue_worklogs")

.PARAMETER logFolder
    Path where log files will be stored (default: ".\Logs")

.PARAMETER showConsoleLog
    Show log output in console (default: $false)

.PARAMETER saveDetailedFiles
    Save detailed output files for each user and issue (default: $false)

.PARAMETER includeMultiUserIssues
    Include issues where multiple users have logged time (default: $false). 
    When set to $false, issues with time logged by multiple users will be skipped.

.PARAMETER storyPointsField
    The custom field ID for Story Points in your Jira instance (default: "customfield_10031"). 
    Different Jira instances use different custom field IDs, so this parameter allows you to specify 
    the correct field ID for your environment.

.PARAMETER kpiField
    The custom field ID for KPI or other business value metric in your Jira instance (default: "customfield_10845").
    This parameter should be set to match your organization's specific custom field for tracking business value or KPIs.

.PARAMETER statusField
    The field name for issue status (default: "status"). This parameter rarely needs to be changed
    as "status" is the standard field name in most Jira instances.

.PARAMETER componentsField
    The field name for components (default: "components"). This parameter rarely needs to be changed
    as "components" is the standard field name in most Jira instances.

.EXAMPLE
    .\GetUserIssuesFromTimesheetData.ps1
    Runs the script with default parameters. Issues with multiple users will be skipped.

.EXAMPLE
    .\GetUserIssuesFromTimesheetData.ps1 -includeMultiUserIssues
    Runs the script and includes issues where multiple users have logged time. These issues will be
    included with the UserName set to "MULTIPLE_USERS".

.EXAMPLE
    .\GetUserIssuesFromTimesheetData.ps1 -dateFrom "2025-04-15" -dateTo "2025-04-30" -showConsoleLog
    Runs the script for a specific date range and shows console logs.

.EXAMPLE
    .\GetUserIssuesFromTimesheetData.ps1 -userEmails @("john.doe@company.com", "jane.smith@company.com")
    Runs the script for multiple users by their email addresses. The script will look up their account IDs and names.

.EXAMPLE
    .\GetUserIssuesFromTimesheetData.ps1 -includeIssueTypes @("Bug")
    Filters issues for the "Bug" issue type.

.EXAMPLE
    .\GetUserIssuesFromTimesheetData.ps1 -includeIssueTypes @("Bug", "Story")
    Filters issues for both "Bug" and "Story" issue types.

.EXAMPLE
    .\GetUserIssuesFromTimesheetData.ps1 -outputFolder "C:\Reports\Output" -logFolder "C:\Reports\Logs"
    Runs the script with custom output and log folder locations.

.EXAMPLE
    .\GetUserIssuesFromTimesheetData.ps1 -issueWorklogsDir "C:\Reports\Output\WorklogData" 
    Runs the script with a custom location for saving issue worklog data.

.EXAMPLE
    .\GetUserIssuesFromTimesheetData.ps1 -saveDetailedFiles -includeMultiUserIssues
    Runs the script with detailed file output and includes issues where multiple users have logged time.

.EXAMPLE
    .\GetUserIssuesFromTimesheetData.ps1 `
        -tempoApiToken "TEMPO_API_TOKEN" `
        -userEmails @("john.doe@company.com", "jane.smith@company.com") `
        -jiraBaseUrl "https://yourcompany.atlassian.net" `
        -jiraEmail "you@company.com" `
        -jiraApiToken "JIRA_API_TOKEN" `
        -tempoBaseUrl "https://api.tempo.io" `
        -tempoApiBase "https://api.tempo.io/4" `
        -offset 0 `
        -limit 100 `
        -maxPages 5 `
        -includeIssueTypes @("Bug") `
        -includeMultiUserIssues `
        -showConsoleLog

.EXAMPLE
    .\GetUserIssuesFromTimesheetData.ps1 -dateFrom "2024-01-01" -dateTo "2025-04-30" -userEmails @("adeel.aziz@company.com", "ahsan.farooq@company.com")
    Runs the script for a wide date range and specific users by email.

#>

param (
    [string]$tempoApiToken = "your_default_tempo_api_token_here",
    [string]$jiraBaseUrl = "https://yourcompany.atlassian.net",
    [string]$jiraEmail = "you@company.com",
    [string]$jiraApiToken = "your_default_jira_api_token_here",
    [string[]]$userEmails = @("john.doe@company.com", "jane.smith@company.com"),
    [string]$tempoBaseUrl = "https://api.tempo.io",
    [string]$tempoApiBase = "https://api.tempo.io/4",
    [string]$dateFrom = "2025-04-01",
    [string]$dateTo = "2025-04-30",
    [string[]]$includeIssueTypes = @("Story"),
    [int]$offset = 0,
    [int]$limit = 50,
    [int]$maxPages = 100,
    [string]$outputFolder = ".\Output",
    [string]$issueWorklogsDir = ".\Output\issue_worklogs",
    [string]$logFolder = ".\Logs",
    [switch]$showConsoleLog = $false,
    [switch]$saveDetailedFiles = $false,
    [switch]$includeMultiUserIssues = $false,
    # Custom field parameters for adaptability to different Jira configurations
    [string]$storyPointsField = "customfield_10031",
    [string]$kpiField = "customfield_10845",
    [string]$statusField = "status",
    [string]$componentsField = "components"
)

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Create log folder if it doesn't exist
if (-not (Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

$logFile = Join-Path -Path $logFolder -ChildPath "script_log_${timestamp}.txt"
Clear-Content $logFile -ErrorAction SilentlyContinue

$script:globalTempoApiCallCount = 0
$script:globalJiraApiCallCount = 0

# Create caches to avoid duplicate API calls
$script:issueDetailsCache = @{}
$script:childIssuesCache = @{}
$script:issueWorklogsCache = @{}

# Track cache hits for reporting
$script:cacheHits = @{
    "IssueDetails" = 0
    "ChildIssues" = 0
    "IssueWorklogs" = 0
}

function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp $message"
    $line | Out-File -FilePath $logFile -Append -Encoding utf8
    if ($showConsoleLog) {
        Write-Host $line
    }
}

$tempoHeaders = @{
    "Authorization" = "Bearer $tempoApiToken"
    "Accept" = "application/json"
}
$jiraBasicAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${jiraEmail}:${jiraApiToken}"))
$jiraHeaders = @{
    "Authorization" = "Basic $jiraBasicAuth"
    "Accept" = "application/json"
}

function Get-AllUserWorklogs {
    param (
        [string]$userAccountId,
        [string]$userFullName
    )
    
    $allResults = @()
    $currentOffset = $offset
    $pageCount = 0
    $functionCallCount = 0

    Write-Log "Retrieving worklogs for user: $userFullName (AccountID: $userAccountId)"

    do {
        $url = "${tempoApiBase}/worklogs/user/${userAccountId}?from=${dateFrom}&to=${dateTo}&offset=${currentOffset}&limit=${limit}"
        Write-Log "Calling Tempo API (User: $userFullName, offset=${currentOffset}, limit=${limit}, page=$($pageCount + 1))..."
        $response = Invoke-RestMethod -Uri $url -Headers $tempoHeaders -Method Get
        $allResults += $response.results
        $currentOffset += $limit
        $pageCount++
        $functionCallCount++
        $script:globalTempoApiCallCount++

        if ($pageCount -ge $maxPages) {
            Write-Log "Reached maximum page limit ($maxPages). Stopping pagination."
            break
        }
    } while ($response.metadata.next)

    Write-Log "Get-AllUserWorklogs for $userFullName → API calls made: $functionCallCount"
    Write-Log "Total worklogs retrieved for ${userFullName}: $($allResults.Count)"
    return $allResults
}

function Get-ChildIssues($parentIssueId) {
    # Check cache first
    if ($script:childIssuesCache.ContainsKey($parentIssueId)) {
        $script:cacheHits["ChildIssues"]++
        Write-Log "CACHE HIT: Using cached child issues for parentIssueId=${parentIssueId} (Total hits: $($script:cacheHits["ChildIssues"]))"
        return $script:childIssuesCache[$parentIssueId]
    }
    
    $childIssues = @()
    $functionCallCount = 1
    
    # JQL to find sub-tasks and issues that have the specified issue as parent
    # Using single quotes for the entire string to avoid escaping double quotes
    $jql = 'parent = ' + $parentIssueId + ' OR "Parent Link" = ' + $parentIssueId
    $encodedJql = [System.Web.HttpUtility]::UrlEncode($jql)
    
    $url = "${jiraBaseUrl}/rest/api/3/search?jql=${encodedJql}"
    Write-Log "Searching for child issues of ${parentIssueId} using JQL: ${jql}"
    
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $jiraHeaders -Method Get
        $script:globalJiraApiCallCount++
        
        if ($response.issues -and $response.issues.Count -gt 0) {
            foreach ($issue in $response.issues) {
                $childIssues += $issue.id
                
                # Cache the issue details while we have them
                if (-not $script:issueDetailsCache.ContainsKey($issue.id)) {
                    $script:issueDetailsCache[$issue.id] = @{
                        IssueType       = $issue.fields.issuetype.name
                        IssueKey        = $issue.key
                        Summary         = $issue.fields.summary
                        ParentId        = $parentIssueId
                        StoryPoints     = if ($issue.fields.PSObject.Properties.Name -contains $storyPointsField -and $issue.fields.$storyPointsField -ne $null) {
                            $issue.fields.$storyPointsField
                        } else { "None" }
                        KPI          = if ($issue.fields.PSObject.Properties.Name -contains $kpiField -and $issue.fields.$kpiField -ne $null) {
                            $issue.fields.$kpiField.value
                        } else { "Unknown" }
                        Status          = if ($issue.fields.PSObject.Properties.Name -contains $statusField -and $issue.fields.$statusField -ne $null) {
                            $issue.fields.$statusField.name
                        } else { "Unknown" }
                        Components      = if ($issue.fields.PSObject.Properties.Name -contains $componentsField -and $issue.fields.$componentsField -ne $null -and $issue.fields.$componentsField.Count -gt 0) {
                            $componentNames = @()
                            foreach ($component in $issue.fields.$componentsField) {
                                $componentNames += $component.name
                            }
                            [string]::Join(", ", $componentNames)
                        } else { "None" }
                    }
                }
            }
            Write-Log "Found $($childIssues.Count) child issues for ${parentIssueId}"
        } else {
            Write-Log "No child issues found for ${parentIssueId}"
        }
    } catch {
        Write-Log "Error searching for child issues of ${parentIssueId}: $_"
    }
    
    # Save to cache
    $script:childIssuesCache[$parentIssueId] = $childIssues
    
    Write-Log "Get-ChildIssues → API calls made: $functionCallCount (ParentIssueID: ${parentIssueId})"
    return $childIssues
}

function Get-IssueWorklogs($issueId) {
    # Check cache first
    if ($script:issueWorklogsCache.ContainsKey($issueId)) {
        $script:cacheHits["IssueWorklogs"]++
        Write-Log "CACHE HIT: Using cached worklogs for issueId=${issueId} (Total hits: $($script:cacheHits["IssueWorklogs"]))"
        return $script:issueWorklogsCache[$issueId]
    }
    
    $allResults = @()
    $processedIssues = @()
    $issuesToProcess = @($issueId)
    $functionCallCount = 0

    # Add the original issue to the list of processed issues
    $processedIssues += $issueId
    
    # Get child issues
    $childIssues = Get-ChildIssues $issueId
    foreach ($childIssue in $childIssues) {
        if ($childIssue -notin $processedIssues) {
            $issuesToProcess += $childIssue
        }
    }
    
    $childIssueCount = $issuesToProcess.Count - 1  # Subtract 1 to exclude the parent issue
    Write-Log "Processing worklogs for issue ${issueId} and ${childIssueCount} child issues"
    
    foreach ($currentIssueId in $issuesToProcess) {
        Write-Log "Getting worklogs for issue ${currentIssueId}"
        
        $currentOffset = $script:offset  # Explicitly reference the script-level parameter
        $pageCount = 0
        
        do {
            $url = "${tempoApiBase}/worklogs?issueId=${currentIssueId}&offset=${currentOffset}&limit=${limit}"
            Write-Log "Calling Tempo API for issue worklogs (issueId=${currentIssueId}, offset=${currentOffset}, limit=${limit}, page=$($pageCount + 1))..."
            
            try {
                $response = Invoke-RestMethod -Uri $url -Headers $tempoHeaders -Method Get
                $allResults += $response.results
                $currentOffset += $limit
                $pageCount++
                $functionCallCount++
                $script:globalTempoApiCallCount++
                
                if ($pageCount -ge $maxPages) {
                    Write-Log "Reached maximum page limit ($maxPages) for issue worklogs. Stopping pagination."
                    break
                }
            } catch {
                Write-Log "Error getting worklogs for issue ${currentIssueId}: $_"
                break
            }
        } while ($response.metadata.next)
        
        Write-Log "Retrieved $($response.results.Count) worklogs for issue ${currentIssueId}"
    }

    # Save to cache
    $script:issueWorklogsCache[$issueId] = $allResults
    
    Write-Log "Get-IssueWorklogs → API calls made: $functionCallCount (IssueID: ${issueId} and its children)"
    Write-Log "Total worklogs retrieved for issue ${issueId} and its children: $($allResults.Count)"
    return $allResults
}

function Get-IssueDetailsFromId($issueId) {
    # Check cache first
    if ($script:issueDetailsCache.ContainsKey($issueId)) {
        $script:cacheHits["IssueDetails"]++
        Write-Log "CACHE HIT: Using cached issue details for issueId=${issueId} (Total hits: $($script:cacheHits["IssueDetails"]))"
        return $script:issueDetailsCache[$issueId]
    }
    
    $functionCallCount = 1
    $url = "${jiraBaseUrl}/rest/api/3/issue/${issueId}"
    
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $jiraHeaders -Method Get
        $script:globalJiraApiCallCount++
        
        # Save raw issue response to a file if saveDetailedFiles is true
        if ($saveDetailedFiles) {
            $issueResponseFile = Join-Path -Path $issueWorklogsDir -ChildPath "issue_raw_${issueId}.json"
            $response | ConvertTo-Json -Depth 100 | Out-File -FilePath $issueResponseFile -Encoding utf8
            Write-Log "Saved raw issue response for ${issueId} to ${issueResponseFile}"
        }

        $issueType = $response.fields.issuetype.name
        $issueKey = $response.key
        $summary = $response.fields.summary
        $parentId = "None"
        
        # Get issue status
        $issueStatus = "Unknown"
        if ($response.fields.PSObject.Properties.Name -contains $statusField -and $response.fields.$statusField -ne $null) {
            $issueStatus = $response.fields.$statusField.name
            Write-Log "Status for issue ${issueId}: ${issueStatus}"
        }
        
        # Get story points
        $storyPoints = "None"
        if ($response.fields.PSObject.Properties.Name -contains $storyPointsField -and $response.fields.$storyPointsField -ne $null) {
            $storyPoints = $response.fields.$storyPointsField
            Write-Log "Story points for issue ${issueId}: ${storyPoints}"
        }

        $kpi = if ($response.fields.PSObject.Properties.Name -contains $kpiField -and $response.fields.$kpiField -ne $null) {
            $response.fields.$kpiField.value
        } else { "Unknown" }

        # Check if issue has parent and get parentId
        if ($response.fields.PSObject.Properties.Name -contains "parent") {
            $parentId = $response.fields.parent.id
            Write-Log "Found parent for issue ${issueId}: ParentId=${parentId}"
        } else {
            $parentId = "None"
        }

        # Fix for components processing
        $components = "None"
        if ($response.fields.PSObject.Properties.Name -contains $componentsField -and $response.fields.$componentsField -ne $null -and $response.fields.$componentsField.Count -gt 0) {
            $componentNames = @()
            foreach ($component in $response.fields.$componentsField) {
                $componentNames += $component.name
            }
            $components = [string]::Join(", ", $componentNames)
        }

        # Cache the result
        $issueDetails = @{
            IssueType       = $issueType
            IssueKey        = $issueKey
            Summary         = $summary
            ParentId        = $parentId
            StoryPoints     = $storyPoints
            KPI             = $kpi
            Status          = $issueStatus
            Components      = $components  
        }
        $script:issueDetailsCache[$issueId] = $issueDetails

        Write-Log "Get-IssueDetailsFromId → API calls made: $functionCallCount (IssueID: $issueId)"
        return $issueDetails
    } catch {
        Write-Log "ERROR in Get-IssueDetailsFromId for issueId ${issueId}: $_"
        $errorDetails = @{
            IssueType       = "Unknown"
            IssueKey        = "Unknown"
            Summary         = "Unknown"
            ParentId        = "None"
            StoryPoints     = "None"
            KPI             = "Unknown"
            Status          = "Unknown"
            Components      = "None"
        }
        # Even cache error details to prevent repeated failed calls
        $script:issueDetailsCache[$issueId] = $errorDetails
        return $errorDetails
    }
}


function Process-IssueWorklogData {
    param (
        [Parameter(Mandatory = $true)]
        [string]$issueId,
        [Parameter(Mandatory = $true)]
        [array]$issueWorklogs,
        [Parameter(Mandatory = $true)]
        [hashtable]$issueDetails,
        [Parameter(Mandatory = $true)]
        [string]$userName,
        [Parameter(Mandatory = $true)]
        [string]$allUsers,
        [Parameter(Mandatory = $false)]
        [string]$logPrefix = ""
    )
    
    # Get worklog dates
    $worklogDates = $issueWorklogs | ForEach-Object { $_.startDate } | Sort-Object
    
    # Debug information to help diagnose date issues
    Write-Log "${logPrefix}Raw worklog dates found: $($worklogDates -join ', ')"
    
    # Handle the dates properly based on the number of worklogs
    if ($worklogDates.Count -eq 0) {
        $oldestWorklogDate = "01/01/1900"
        $latestWorklogDate = "01/01/1900"
    } 
    elseif ($worklogDates.Count -eq 1) {
        # When there's only one worklog, use $worklogDates directly instead of indexing into it
        $oldestWorklogDate = $worklogDates
        $latestWorklogDate = $worklogDates
        Write-Log "${logPrefix}Single worklog detected, setting oldest and latest to the same date: ${oldestWorklogDate}"
    }
    else {
        # Multiple worklogs, get first and last
        $oldestWorklogDate = $worklogDates[0]
        $latestWorklogDate = $worklogDates[-1]
    }
    
    # Calculate total time spent in hours
    $totalTimeSpentSeconds = ($issueWorklogs | Measure-Object -Property timeSpentSeconds -Sum).Sum
    $timeSpentHours = [math]::Round($totalTimeSpentSeconds / 3600, 2)  # Convert seconds to hours and round to 2 decimal places
    
    # Calculate days from hours (assuming 8-hour workday)
    $timeSpentDays = [math]::Round($timeSpentHours / 8, 2)  # Convert hours to days and round to 2 decimal places
    
    # Calculate velocity (StoryPoints / Days)
    $velocity = "N/A"
    if ($timeSpentDays -gt 0 -and $issueDetails.StoryPoints -ne "None" -and $issueDetails.StoryPoints -ne $null) {
        # Convert StoryPoints to numeric if it's not already
        $storyPointsNumeric = 0
        if ([double]::TryParse($issueDetails.StoryPoints, [ref]$storyPointsNumeric)) {
            $velocity = [math]::Round($storyPointsNumeric / $timeSpentDays, 4)  # Round to 4 decimal places
        }
    }
    
    Write-Log "${logPrefix}Oldest worklog date: ${oldestWorklogDate}, Latest worklog date: ${latestWorklogDate}, Time spent: ${timeSpentHours} hours, Days: ${timeSpentDays}, Velocity: ${velocity}"

    # Convert numeric values to their respective types to avoid quotes in CSV
    $storyPointsValue = if ($issueDetails.StoryPoints -eq "None" -or $issueDetails.StoryPoints -eq $null) { 
        [DBNull]::Value 
    } else { 
        [double]$issueDetails.StoryPoints 
    }
    
    $velocityValue = if ($velocity -eq "N/A") { 
        [DBNull]::Value 
    } else { 
        [double]$velocity 
    }
    
    $parentIssueKey = "None"
    $parentIssueType = "None"
    $parentSummary = "None"
    
    if ($issueDetails.ParentId -ne "None") {
        Write-Log "Adding parent Info - ParentId: $($issueDetails.ParentId)"
        
        # Get parent issue details
        $parentDetails = Get-IssueDetailsFromId $issueDetails.ParentId
        Write-Log "Parent details received - Parent Issue Type: $($parentDetails.IssueType)"
        
        $parentIssueKey = $parentDetails.IssueKey
        $parentIssueType = $parentDetails.IssueType
        $parentSummary = $parentDetails.Summary
    }

    return [PSCustomObject]@{
        IssueId           = $issueId
        IssueKey          = $issueDetails.IssueKey
        IssueType         = $issueDetails.IssueType
        Summary           = $issueDetails.Summary
        UserName          = $userName
        Status            = $issueDetails.Status
        OldestWorklogDate = $oldestWorklogDate
        LatestWorklogDate = $latestWorklogDate
        TimeSpentHours    = [double]$timeSpentHours
        StoryPoints       = $storyPointsValue
        Days              = [double]$timeSpentDays
        Velocity          = $velocityValue
        KPI               = $issueDetails.KPI
        Components        = $issueDetails.Components
        ParentIssueKey    = $parentIssueKey
        ParentIssueType   = $parentIssueType
        ParentSummary     = $parentSummary
        AllUsers          = $allUsers
    }
}

function Get-UserDetailsByEmail {
    param (
        [Parameter(Mandatory = $true)]
        [string]$email
    )
    
    Write-Log "Looking up user details for email: $email"
    $url = "${jiraBaseUrl}/rest/api/3/user/search?query=${email}"
    
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $jiraHeaders -Method Get
        $script:globalJiraApiCallCount++
        
        if ($response.Count -eq 0) {
            Write-Log "ERROR: No user found with email $email"
            return $null
        }
        
        # Find the exact match or best match
        $exactMatch = $response | Where-Object { $_.emailAddress -eq $email }
        $user = if ($exactMatch) { $exactMatch } else { $response[0] }
        
        Write-Log "Found user account: $($user.displayName) (AccountID: $($user.accountId), Email: $($user.emailAddress))"
        return @{
            AccountId = $user.accountId
            DisplayName = $user.displayName
            Email = $user.emailAddress
        }
    } catch {
        Write-Log "ERROR getting user details for email ${email}: $_"
        return $null
    }
}

$scriptStartTime = Get-Date

Write-Log "========== STARTING TEMPO WORKLOG CHECK =========="

# Look up user account IDs and names from email addresses
$userAccountIds = @()
$userNames = @()

foreach ($email in $userEmails) {
    $userDetails = Get-UserDetailsByEmail -email $email
    
    if ($userDetails -eq $null) {
        Write-Log "ERROR: Could not find user with email address: $email"
        Write-Host "ERROR: Could not find user with email address: $email"
        exit 1
    }
    
    $userAccountIds += $userDetails.AccountId
    $userNames += $userDetails.DisplayName
    
    Write-Log "User found: $($userDetails.DisplayName) (AccountID: $($userDetails.AccountId), Email: $($userDetails.Email))"
}

# Create output folder if it doesn't exist
if (-not (Test-Path $outputFolder)) {
    New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
    Write-Log "Created output directory: $outputFolder"
} else {
    # Clear existing files in the output folder (except CSV files), but don't touch subfolders
    Get-ChildItem -Path $outputFolder -File | Where-Object { $_.Extension -ne '.csv' } | Remove-Item -Force
    Write-Log "Cleared existing non-CSV files in output directory (preserved subfolders)."
}

# Create directory for issue worklog files if it doesn't exist
if (-not (Test-Path $issueWorklogsDir)) {
    New-Item -Path $issueWorklogsDir -ItemType Directory -Force | Out-Null
    Write-Log "Created directory for issue worklog files: $issueWorklogsDir"
} else {
    # Clear existing files in the directory
    Get-ChildItem -Path $issueWorklogsDir -Filter "issue_*.json" | Remove-Item -Force
    Write-Log "Cleared existing issue worklog files."
}

# We'll create separate other_users.txt files for each user, so we don't need a shared one
$allResultsList = @()

# Process each user
for ($i = 0; $i -lt $userNames.Count; $i++) {
    $currentUserName = $userNames[$i]
    $currentUserAccountId = $userAccountIds[$i]
    
    Write-Log "========== PROCESSING USER: $currentUserName =========="
    Write-Log "User Account ID: $currentUserAccountId"
    
    # Create a user-specific other_users file if saveDetailedFiles is true
    $otherUsersFile = Join-Path -Path $outputFolder -ChildPath "other_users_$($currentUserName.Replace(' ', '_')).txt"
    if ($saveDetailedFiles) {
        Clear-Content $otherUsersFile -ErrorAction SilentlyContinue
    }
    
    $userWorklogs = Get-AllUserWorklogs -userAccountId $currentUserAccountId -userFullName $currentUserName
    
    # Save user worklogs to a file if saveDetailedFiles is true
    if ($saveDetailedFiles) {
        $userWorklogsFile = Join-Path -Path $outputFolder -ChildPath "user_worklogs_$($currentUserName.Replace(' ', '_')).json"
        $userWorklogs | ConvertTo-Json -Depth 10 | Out-File $userWorklogsFile
        Write-Log "User worklogs saved to $userWorklogsFile"
    }
    Write-Log "Total worklogs retrieved for ${currentUserName}: $($userWorklogs.Count)"
    
    # Create a filtered list of issue IDs that match the includeIssueType or have parent/child matching the type
    $filteredIssueIds = @()
    $allIssueIds = $userWorklogs | Select-Object -ExpandProperty issue | Select-Object -ExpandProperty id -Unique
    Write-Log "Found $($allIssueIds.Count) total unique issues where $currentUserName has logged time."
    
    Write-Log "Filtering issues by types: $($includeIssueTypes -join ', ')"
    foreach ($issueId in $allIssueIds) {
        $issueDetails = Get-IssueDetailsFromId $issueId
        
        # Case 1: Direct match - Issue type matches any of the specified types
        if ($includeIssueTypes -contains $issueDetails.IssueType) {
            Write-Log "Adding issue $issueId (type: $($issueDetails.IssueType)) - direct match"
            $filteredIssueIds += $issueId
            continue
        }
        
        # Case 2: Check parent issue if it exists
        if ($issueDetails.ParentId -ne "None") {
            Write-Log "Parent Info - ParentId: $($issueDetails.ParentId)"
            
            # Get parent issue details using our existing function instead of direct API call
            $parentDetails = Get-IssueDetailsFromId $issueDetails.ParentId
            Write-Log "Parent response received - Issue Type: $($parentDetails.IssueType)"
            
            if ($includeIssueTypes -contains $parentDetails.IssueType) {
                # Add the parent issue ID instead of the current issue ID
                Write-Log "Adding parent issue $($issueDetails.ParentId) - matches one of the specified types: $($parentDetails.IssueType)"
                $filteredIssueIds += $issueDetails.ParentId
                continue
            }
        }
        
        # Case 3: Check if this issue has child issues matching any of the types
        $childIssues = Get-ChildIssues $issueId
        $matchingChildIds = @()

        foreach ($childIssue in $childIssues) {
            # Get child issue details - function will handle cache lookup internally
            $childDetails = Get-IssueDetailsFromId $childIssue
            $childIssueType = $childDetails.IssueType
            
            if ($includeIssueTypes -contains $childIssueType) {
                # Add the child issue ID that matches the filter type
                $matchingChildIds += $childIssue
                Write-Log "Adding child issue $childIssue - matches one of the specified types: $childIssueType"
            }
        }
        
        if ($matchingChildIds.Count -gt 0) {
            $filteredIssueIds += $matchingChildIds
        }
    }
    
    # Remove duplicates from the filteredIssueIds list
    $filteredIssueIds = $filteredIssueIds | Select-Object -Unique
    Write-Log "After removing duplicates, filtered to $($filteredIssueIds.Count) unique issues for $currentUserName"
    
    # Write filtered issue IDs to a file for this user if saveDetailedFiles is true
    if ($saveDetailedFiles) {
        $filteredIssuesFile = Join-Path -Path $outputFolder -ChildPath "filtered_issues_by_type_$($currentUserName.Replace(' ', '_')).txt"
        $filteredIssueIds | Out-File -FilePath $filteredIssuesFile -Encoding utf8
        Write-Log "Filtered $($filteredIssueIds.Count) issues for $currentUserName saved to $filteredIssuesFile"
    }
    
    $uniqueIssues = $filteredIssueIds
    Write-Log "Filtered to $($uniqueIssues.Count) issues with type matching criteria: $includeIssueTypes (direct matches or parent/child relationships)"
    
    $resultList = @()
    $issueCounter = 1
    $totalIssues = $uniqueIssues.Count
    
    foreach ($issueId in $uniqueIssues) {
        Write-Log "Checking issue ${issueId} (${issueCounter}/${totalIssues}) for user $currentUserName..."
        $issueWorklogs = Get-IssueWorklogs $issueId
        
        # Get issue details
        $issueDetails = Get-IssueDetailsFromId $issueId
        $issueKey = $issueDetails.IssueKey
        
        # Save issue worklogs to separate JSON file if saveDetailedFiles is true
        if ($saveDetailedFiles) {
            $issueWorklogsFile = Join-Path -Path $issueWorklogsDir -ChildPath "issue_${issueKey}_${issueId}.json"
            $issueWorklogs | ConvertTo-Json -Depth 10 | Out-File -FilePath $issueWorklogsFile -Encoding utf8
            Write-Log "Saved worklogs for issue ${issueKey} (${issueId}) to ${issueWorklogsFile}"
        }
        
        # Check for other users who have logged time on this issue
        $otherUsers = $issueWorklogs | Where-Object { $_.author.accountId -ne $currentUserAccountId } | Select-Object -ExpandProperty author -Unique
        
        if ($otherUsers.Count -eq 0) {
            # No other users have logged time on this issue - process it
            Write-Log "No other users logged time on issue ${issueId} - processing..."
            $logPrefix = "Issue ${issueId} for user ${currentUserName}: "
            
            # Process issue data and add to result list
            $result = Process-IssueWorklogData -issueId $issueId -issueWorklogs $issueWorklogs -issueDetails $issueDetails `
                -userName $currentUserName -allUsers $currentUserAccountId -logPrefix $logPrefix
            
            $resultList += $result
        } 
        elseif ($includeMultiUserIssues) {
            # Other users have logged time on this issue AND includeMultiUserIssues is enabled
            # Get the list of all users who have logged time on this issue (including current user)
            $otherUserNames = ($otherUsers | ForEach-Object { $_.accountId }) -join ", "
            
            # Create allUserIdsString by combining other users with current user
            $allUserIdsString = if ($otherUserNames) {
                "$otherUserNames, $currentUserAccountId"
            } else {
                $currentUserAccountId
            }
			
			# Debug information
            Write-Log "OtherUserNames: ${otherUserNames} - AllUserIdsString: ${allUserIdsString}"
            
            $logPrefix = "Issue ${issueId} with multiple users: "
            
            # Process issue data and add to result list
            $result = Process-IssueWorklogData -issueId $issueId -issueWorklogs $issueWorklogs -issueDetails $issueDetails `
                -userName "MULTIPLE_USERS" -allUsers $allUserIdsString -logPrefix $logPrefix
            
            $resultList += $result
            
            # Log info about multiple users
            Write-Log "Issue ${issueId} has multiple users logged time on it: ${otherUserNames} - Including in results with UserName='MULTIPLE_USERS'"
            
            if ($saveDetailedFiles) {
                $line = "Issue ${issueId}: $otherUserNames"
                $line | Out-File $otherUsersFile -Encoding utf8 -Append
            }
        }
        else {
            # Multi-user issues are present but should be skipped (includeMultiUserIssues is false)
            $otherUserNames = ($otherUsers | ForEach-Object { $_.accountId }) -join ", "
            Write-Log "Skipping issue ${issueId} as it has multiple users (${otherUserNames}) and includeMultiUserIssues is disabled"
            
            if ($saveDetailedFiles) {
                $line = "Skipped issue ${issueId}: $otherUserNames"
                $line | Out-File $otherUsersFile -Encoding utf8 -Append
            }
        }

        $issueCounter++
    }
    
    # Add results to the combined list
    $allResultsList += $resultList
    
    # Generate per-user report
    $uniqueKeys = $resultList | Sort-Object IssueKey -Unique
    
    Write-Log "========== SUMMARY REPORT FOR $currentUserName =========="
    if ($uniqueKeys.Count -gt 0) {
        $uniqueKeys | Format-Table -AutoSize | Out-String | Write-Log
        Write-Log "Total unique keys for ${currentUserName}: $($uniqueKeys.Count)"
    } else {
        Write-Log "No matching keys found for $currentUserName."
    }
    
    # Create per-user output file only if saveDetailedFiles is true
    if ($saveDetailedFiles) {
        $fileTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $outputFile = Join-Path -Path $outputFolder -ChildPath "${dateFrom}_${dateTo}_tempo_issue_report_$($currentUserName.Replace(' ', '_'))_${fileTimestamp}.csv"
        $resultList | Export-Csv -Path $outputFile -NoTypeInformation
        Write-Log "Report for $currentUserName saved to ${outputFile}."
    }
    
    Write-Log "========== COMPLETED PROCESSING USER: $currentUserName =========="
}

# Generate a combined report for all users
if ($allResultsList.Count -gt 0) {
    $fileTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    Write-Log "========== COMBINED REPORT FOR ALL USERS =========="
    $combinedOutputFile = Join-Path -Path $outputFolder -ChildPath "${dateFrom}_${dateTo}_tempo_issue_report_ALL_USERS_${fileTimestamp}.csv"
    $allResultsList | Export-Csv -Path $combinedOutputFile -NoTypeInformation
    Write-Log "Combined report for all users saved to ${combinedOutputFile}."
    
    # Summary statistics per user
    Write-Log "========== USER SUMMARY STATISTICS =========="
    $userSummary = $allResultsList | Group-Object -Property UserName | ForEach-Object {
        $userData = $_.Group
        $totalHours = ($userData | Measure-Object -Property TimeSpentHours -Sum).Sum
        $totalDays = ($userData | Measure-Object -Property Days -Sum).Sum
        $issueCount = $userData.Count
        
        [PSCustomObject]@{
            UserName = $_.Name
            TotalIssues = $issueCount
            TotalHours = [math]::Round($totalHours, 2)
            TotalDays = [math]::Round($totalDays, 2)
            AverageHoursPerIssue = if ($issueCount -gt 0) { [math]::Round($totalHours / $issueCount, 2) } else { 0 }
        }
    }
    
    # Check if there's actual data before formatting and logging
    if ($userSummary.Count -gt 0) {
        # First, log each user's summary stats individually to ensure they appear in the log
        Write-Log "User Summary Statistics:"
        foreach ($userStat in $userSummary) {
            $statLine = "User: $($userStat.UserName), Issues: $($userStat.TotalIssues), Hours: $($userStat.TotalHours), Days: $($userStat.TotalDays), Avg Hours/Issue: $($userStat.AverageHoursPerIssue)"
            Write-Log "  $statLine"
        }
        
        # Then try the table format as a backup
        $formattedTable = $userSummary | Format-Table -AutoSize | Out-String
        if (![string]::IsNullOrWhiteSpace($formattedTable)) {
            Write-Log "User Summary Table:"
            # Split the table by lines and log each line separately
            $formattedTable.Trim() -split "`r`n" | ForEach-Object {
                Write-Log "  $_"
            }
        }
    } else {
        Write-Log "No user summary data available."
    }
}

Write-Log "========== API CALL SUMMARY =========="
Write-Log "Total Tempo API calls made: $script:globalTempoApiCallCount"
Write-Log "Total Jira API calls made: $script:globalJiraApiCallCount"

Write-Log "========== CACHE HITS SUMMARY =========="
Write-Log "IssueDetails cache hits: $($script:cacheHits["IssueDetails"])"
Write-Log "ChildIssues cache hits: $($script:cacheHits["ChildIssues"])"
Write-Log "IssueWorklogs cache hits: $($script:cacheHits["IssueWorklogs"])"
Write-Log "Total cache hits: $(($script:cacheHits.Values | Measure-Object -Sum).Sum)"

$scriptEndTime = Get-Date
$executionTime = $scriptEndTime - $scriptStartTime
$executionTimeFormatted = "{0:hh\:mm\:ss\.fff}" -f $executionTime

Write-Log "========== EXECUTION TIME =========="
Write-Log "Script started at: $scriptStartTime"
Write-Log "Script ended at: $scriptEndTime"
Write-Log "Total execution time: $executionTimeFormatted"

Write-Log "========== SCRIPT FINISHED =========="



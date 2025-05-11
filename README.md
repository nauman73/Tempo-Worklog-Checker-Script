# Tempo Worklog Checker Script

## Overview
A PowerShell script that retrieves and analyzes Tempo timesheets data from Jira cloud, specifically designed for tracking time spent on issues of particular types. The script processes worklogs for multiple users and generates comprehensive reports with detailed time tracking metrics.

## Features
- Retrieves Tempo timesheets worklogs for multiple users
- Filters issues by specific issue types
- Includes parent/child relationships in data analysis
- Supports multi-user issue tracking
- Generates detailed CSV reports
- Calculates key metrics including time spent, story points, and velocity
- Caches API responses to minimize API calls and improve performance
- Comprehensive logging of all operations

## Requirements
- PowerShell 5.1 or higher
- Jira Cloud instance with Tempo Timesheets
- Jira API token
- Tempo API token
- Appropriate permissions to access Jira and Tempo APIs

## Installation
1. Clone or download this repository
2. Ensure PowerShell 5.1 or higher is installed
3. No additional PowerShell modules are required

## Configuration
The script accepts multiple parameters that can be customized:

### Authentication Parameters
- `tempoApiToken`: Tempo API token
- `jiraBaseUrl`: Base URL of your Jira Cloud instance
- `jiraEmail`: Jira user email for API access
- `jiraApiToken`: Jira API token

### User Parameters
- `userEmails`: Array of email addresses of the users to include in results. The script will look up account IDs and names.

### Date Range Parameters
- `dateFrom`: Start date of the date range (default: "2025-04-01")
- `dateTo`: End date of the date range (default: "2025-04-30")

### Filter Parameters
- `includeIssueTypes`: Array of issue types to include in the result (default: @("Story"))
- `includeMultiUserIssues`: Include issues where multiple users have logged time

### API Request Parameters
- `offset`: Starting offset for Tempo API pagination (default: 0)
- `limit`: Number of records per Tempo API page (default: 50)
- `maxPages`: Maximum number of API pages to retrieve (default: 100)

### Output Parameters
- `outputFolder`: Path where output files will be stored (default: ".\Output")
- `issueWorklogsDir`: Path where issue worklog files will be stored (default: ".\Output\issue_worklogs")
- `logFolder`: Path where log files will be stored (default: ".\Logs")
- `showConsoleLog`: Show log output in console (default: $false)
- `saveDetailedFiles`: Save detailed output files for each user and issue (default: $false)

### Jira Custom Field Parameters
- `storyPointsField`: Custom field ID for story points (default: "customfield_10031")
- `kpiField`: Custom field ID for KPI information (default: "customfield_10845")
- `statusField`: Field name for issue status (default: "status")
- `componentsField`: Field name for components (default: "components")

## Usage Examples

### Basic Usage
```powershell
.\GetUserIssuesFromTimesheetData.ps1
```

### Include Multi-User Issues
```powershell
.\GetUserIssuesFromTimesheetData.ps1 -includeMultiUserIssues
```

### Custom Date Range with Console Logging
```powershell
.\GetUserIssuesFromTimesheetData.ps1 -dateFrom "2025-04-15" -dateTo "2025-04-30" -showConsoleLog
```

### Specify Users
```powershell
.\GetUserIssuesFromTimesheetData.ps1 -userEmails @("john.doe@example.com", "jane.smith@example.com")
```

### Filter by Issue Type
```powershell
.\GetUserIssuesFromTimesheetData.ps1 -includeIssueTypes @("Bug")
```

### Multiple Issue Types
```powershell
.\GetUserIssuesFromTimesheetData.ps1 -includeIssueTypes @("Bug", "Story")
```

### Custom Output Directories
```powershell
.\GetUserIssuesFromTimesheetData.ps1 -outputFolder "C:\Reports\Output" -logFolder "C:\Reports\Logs"
```

### Save Detailed Files
```powershell
.\GetUserIssuesFromTimesheetData.ps1 -saveDetailedFiles -includeMultiUserIssues
```

### Full Example with All Parameters
```powershell
.\GetUserIssuesFromTimesheetData.ps1 `
    -tempoApiToken "TEMPO_API_TOKEN" `
    -userEmails @("john.doe@example.com", "jane.smith@example.com") `
    -jiraBaseUrl "https://yourcompany.atlassian.net" `
    -jiraEmail "you@company.com" `
    -jiraApiToken "JIRA_API_TOKEN" `
    -tempoBaseUrl "https://api.tempo.io" `
    -tempoApiBase "https://api.tempo.io/4" `
    -dateFrom "2025-04-01" `
    -dateTo "2025-04-30" `
    -offset 0 `
    -limit 100 `
    -maxPages 5 `
    -includeIssueTypes @("Bug") `
    -includeMultiUserIssues `
    -outputFolder ".\Output" `
    -issueWorklogsDir ".\Output\issue_worklogs" `
    -logFolder ".\Logs" `
    -showConsoleLog `
    -saveDetailedFiles `
    -storyPointsField "customfield_10031" `
    -kpiField "customfield_10845" `
    -statusField "status" `
    -componentsField "components"
```

### Real-World Example
```powershell
.\GetUserIssuesFromTimesheetData.ps1 -dateFrom "2024-01-01" -dateTo "2025-04-30" -userEmails @("john.doe@example.com", "jane.smith@example.com")
```

## Output
The script generates the following outputs:

1. **CSV Report Files**: Contains detailed information about issues, time spent, and metrics
2. **Log Files**: Detailed logs of script execution with timestamps
3. **Detailed Files** (optional): Raw issue data, user worklogs, and filtered issue lists

## Generated Report Fields
The CSV reports include the following fields:
- IssueId: Jira issue ID
- IssueKey: Jira issue key (e.g., PROJ-123)
- IssueType: Type of the issue (e.g., Story, Bug)
- Summary: Issue summary/title
- UserName: Name of the user who logged time
- Status: Current status of the issue
- OldestWorklogDate: Date of the oldest worklog
- LatestWorklogDate: Date of the latest worklog
- TimeSpentHours: Total time spent in hours
- StoryPoints: Story points assigned to the issue
- Days: Time spent converted to days (based on 8-hour workday)
- Velocity: Story points divided by days spent
- KPI: KPI field value from Jira
- Components: Components associated with the issue
- ParentIssueKey: Key of the parent issue (if applicable)
- ParentIssueType: Type of the parent issue (if applicable)
- ParentSummary: Summary of the parent issue (if applicable)
- AllUsers: List of all users who logged time on the issue

## Notes
- The script caches API responses to minimize the number of API calls
- Multi-user issues are handled based on the `includeMultiUserIssues` parameter
- Parent/child relationships are automatically detected and reported
- Story points and velocity are calculated where applicable

## License
[MIT License](LICENSE)

## Author
Nauman Hameed

## Acknowledgments
- Tempo API Documentation: https://developer.tempo.io/
- Jira API Documentation: https://developer.atlassian.com/cloud/jira/platform/rest/v3/intro/
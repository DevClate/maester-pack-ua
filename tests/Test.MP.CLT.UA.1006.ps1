function Test-CltEmployeeHireDate {
    <#
    .SYNOPSIS
    Checks that every enabled member user has an employee hire date.

    .DESCRIPTION
    Graph returns employeeHireDate only when the connection has User-LifeCycleInfo.Read.All. Without it
    every user looks blank, so when no checked user has a hire date the result is Investigate rather than a
    failure for everyone. Converted from ENTRA.UA.1015 in DevClate/Custom-Maester-Tests.
    #>
    [MaesterTest(
        Id           = 'MP.CLT.UA.1006',
        Title        = 'All member users have an employee hire date.',
        Product      = 'entra',
        Feature      = 'identity-governance',
        Area         = 'identity-lifecycle',
        ResourceType = 'User',
        Severity     = 'Medium',
        UserImpact   = 'Low',
        ImplementationCost = 'Medium',
        Service      = 'Graph',
        Permission   = ('User.Read.All', 'User-LifeCycleInfo.Read.All', 'GroupMember.Read.All'),
        Tag          = ('UserAttributes', 'Presence', 'Governance', 'LifecycleWorkflows'),
        Author       = 'DevClate'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # Users (user principal name or object ID) that are exempt, such as break-glass and service accounts.
        [MaesterParameter(Kind = 'Entra.User')]
        [string[]] $ExcludedUsers,

        # Members of these groups (object IDs) are exempt, such as a group of contractors without HR records.
        [MaesterParameter(Kind = 'Entra.Group')]
        [string[]] $ExcludedGroups,

        # Also check disabled accounts, such as shared mailboxes and leavers.
        [bool] $IncludeDisabled = $false,

        # Most users to list in the result; 0 lists them all.
        [ValidateRange(0, 100000)]
        [int] $MaxRows = 100
    )

    $population = Get-CltPopulation -IncludeDisabled $IncludeDisabled
    $users = Get-CltUser -Property employeeHireDate -IncludeDisabled $IncludeDisabled -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups

    $withDate = @($users | Where-Object { -not (Test-CltIsBlank $_.employeeHireDate) })
    if ($users.Count -gt 1 -and $withDate.Count -eq 0) {
        Add-MtTestResultDetail -Investigate -Result ("None of the $($users.Count) $population has an employee hire date. Either none are set, or this " +
            "connection cannot read them: Microsoft Graph returns employeeHireDate only with the **User-LifeCycleInfo.Read.All** permission. " +
            "Add that permission to the app or connection Maester uses, then run the test again.")
        return $true
    }

    return (Invoke-CltPresenceCheck -Users $users -Property employeeHireDate -Label 'an employee hire date' -Population $population -MaxRows $MaxRows)
}

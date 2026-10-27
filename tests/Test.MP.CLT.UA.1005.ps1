function Test-CltEmployeeId {
    <#
    .SYNOPSIS
    Checks that every enabled member user has an employee ID.

    .DESCRIPTION
    Converted from ENTRA.UA.1016 in DevClate/Custom-Maester-Tests. MP.CLT.UA.1010 checks that the IDs are unique.
    #>
    [MaesterTest(
        Id           = 'MP.CLT.UA.1005',
        Title        = 'All member users have an employee ID.',
        Product      = 'entra',
        Feature      = 'identity-governance',
        Area         = 'identity-lifecycle',
        ResourceType = 'User',
        Severity     = 'Medium',
        UserImpact   = 'Low',
        ImplementationCost = 'Medium',
        Service      = 'Graph',
        Permission   = ('User.Read.All', 'GroupMember.Read.All'),
        Tag          = ('UserAttributes', 'Presence', 'Governance'),
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

    $users = Get-CltUser -Property employeeId -IncludeDisabled $IncludeDisabled -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups
    return (Invoke-CltPresenceCheck -Users $users -Property employeeId -Label 'an employee ID' -Population (Get-CltPopulation -IncludeDisabled $IncludeDisabled) -MaxRows $MaxRows)
}

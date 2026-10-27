function Test-CltOfficeLocation {
    <#
    .SYNOPSIS
    Checks that every enabled member user has an office location.

    .DESCRIPTION
    Converted from ENTRA.UA.1009 in DevClate/Custom-Maester-Tests.
    #>
    [MaesterTest(
        Id           = 'MP.CLT.UA.1017',
        Title        = 'All member users have an office location.',
        Product      = 'entra',
        Feature      = 'identity-governance',
        Area         = 'identity-lifecycle',
        ResourceType = 'User',
        Severity     = 'Low',
        UserImpact   = 'Low',
        ImplementationCost = 'Medium',
        Service      = 'Graph',
        Permission   = ('User.Read.All', 'GroupMember.Read.All'),
        Tag          = ('UserAttributes', 'Presence', 'Address', 'Optional'),
        Author       = 'DevClate'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # Users (user principal name or object ID) that are exempt, such as break-glass accounts.
        [MaesterParameter(Kind = 'Entra.User')]
        [string[]] $ExcludedUsers,

        # Members of these groups (object IDs) are exempt from this check.
        [MaesterParameter(Kind = 'Entra.Group')]
        [string[]] $ExcludedGroups,

        # Also check disabled accounts, such as shared mailboxes and leavers.
        [bool] $IncludeDisabled = $false,

        # Most users to list in the result; 0 lists them all.
        [ValidateRange(0, 100000)]
        [int] $MaxRows = 100
    )

    $users = Get-CltUser -Property officeLocation -IncludeDisabled $IncludeDisabled -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups
    return (Invoke-CltPresenceCheck -Users $users -Property officeLocation -Label 'an office location' -Population (Get-CltPopulation -IncludeDisabled $IncludeDisabled) -MaxRows $MaxRows)
}

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
        Permission   = ('Graph:Scope:User.Read.All', 'Graph:Scope:GroupMember.Read.All'),
        Tag          = ('UserAttributes', 'Presence', 'Address', 'Optional'),
        Author       = 'DevClate'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # More users (user principal name or object ID) to leave out of this test, on top of the pack-wide exclusions.
        [string[]] $ExcludedUsers,

        # More groups (object IDs) whose members, including nested members, are left out of this test.
        [MaesterParameter(Kind = 'Entra.Group')]
        [string[]] $ExcludedGroups,

        # Also check disabled accounts, such as shared mailboxes and leavers.
        [bool] $IncludeDisabled = $false,

        # Most users to list in the result; 0 lists them all.
        [ValidateRange(0, 100000)]
        [int] $MaxRows = 100
    )

    $set = Get-CltUser -Property officeLocation -IncludeDisabled $IncludeDisabled -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups
    $users = $set.Users
    return (Invoke-CltPresenceCheck -Users $users -Property officeLocation -Label 'an office location' -Population (Get-CltPopulation -IncludeDisabled $IncludeDisabled) -MaxRows $MaxRows -Note $set.Note)
}

function Test-CltMobilePhone {
    <#
    .SYNOPSIS
    Checks that every enabled member user has a mobile phone.

    .DESCRIPTION
    Converted from ENTRA.UA.1011 in DevClate/Custom-Maester-Tests. MP.CLT.UA.1011 checks the number's format.
    #>
    [MaesterTest(
        Id           = 'MP.CLT.UA.1015',
        Title        = 'All member users have a mobile phone.',
        Product      = 'entra',
        Feature      = 'identity-governance',
        Area         = 'identity-lifecycle',
        ResourceType = 'User',
        Severity     = 'Low',
        UserImpact   = 'Low',
        ImplementationCost = 'Medium',
        Service      = 'Graph',
        Permission   = ('User.Read.All', 'GroupMember.Read.All'),
        Tag          = ('UserAttributes', 'Presence', 'Phone', 'Optional'),
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

    $set = Get-CltUser -Property mobilePhone -IncludeDisabled $IncludeDisabled -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups
    $users = $set.Users
    return (Invoke-CltPresenceCheck -Users $users -Property mobilePhone -Label 'a mobile phone' -Population (Get-CltPopulation -IncludeDisabled $IncludeDisabled) -MaxRows $MaxRows -Note $set.Note)
}

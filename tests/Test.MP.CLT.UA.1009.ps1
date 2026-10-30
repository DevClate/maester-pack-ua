function Test-CltGuestSponsor {
    <#
    .SYNOPSIS
    Checks that every enabled guest user has at least one sponsor.

    .DESCRIPTION
    Sponsors are the people responsible for a guest. Reads each guest's sponsors in the same Graph request
    ($expand=sponsors). Rewritten from ENTRA.UA.1014 in DevClate/Custom-Maester-Tests, which checked all users
    with the beta SDK and wrote every user to the output; in Maester 3.0 that output would have made the
    test an InvalidReturn error.
    #>
    [MaesterTest(
        Id           = 'MP.CLT.UA.1009',
        Title        = 'All guest users have a sponsor.',
        Product      = 'entra',
        Feature      = 'external-identities',
        Area         = 'identity-lifecycle',
        ResourceType = 'User',
        Severity     = 'Medium',
        UserImpact   = 'Low',
        ImplementationCost = 'Medium',
        Service      = 'Graph',
        Permission   = ('User.Read.All', 'GroupMember.Read.All'),
        Tag          = ('UserAttributes', 'Presence', 'Guests', 'Governance'),
        Author       = 'DevClate'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # More guests (user principal name or object ID) to leave out of this test, on top of the pack-wide exclusions.
        [string[]] $ExcludedUsers,

        # More groups (object IDs) whose members, including nested members, are left out of this test.
        [MaesterParameter(Kind = 'Entra.Group')]
        [string[]] $ExcludedGroups,

        # Also check disabled guest accounts.
        [bool] $IncludeDisabled = $false,

        # Most users to list in the result; 0 lists them all.
        [ValidateRange(0, 100000)]
        [int] $MaxRows = 100
    )

    $set = Get-CltUser -UserType Guest -Expand 'sponsors($select=id,displayName)' -IncludeDisabled $IncludeDisabled -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups
    $users = $set.Users
    return (Invoke-CltPresenceCheck -Users $users -Property sponsors -Label 'a sponsor' -Population (Get-CltPopulation -UserType Guest -IncludeDisabled $IncludeDisabled) -MaxRows $MaxRows -Note $set.Note)
}

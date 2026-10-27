function Test-CltUsageLocation {
    <#
    .SYNOPSIS
    Checks that every enabled member user has a usage location, which licence assignment needs.

    .DESCRIPTION
    Microsoft 365 will not assign a licence to a user who has no usage location, and group-based
    licensing reports an error for that user instead. Converted from ENTRA.UA.1017 in DevClate/Custom-Maester-Tests.

    .EXAMPLE
    Invoke-MtTest -Path ./tests/Test.MP.CLT.UA.1001.ps1 -Parameter @{ ExcludedUsers = 'breakglass@contoso.com' }
    #>
    [MaesterTest(
        Id           = 'MP.CLT.UA.1001',
        Title        = 'All member users have a usage location.',
        Product      = 'entra',
        Feature      = 'identity-governance',
        Area         = 'identity-lifecycle',
        ResourceType = 'User',
        Severity     = 'High',
        UserImpact   = 'Low',
        ImplementationCost = 'Low',
        Service      = 'Graph',
        Permission   = ('User.Read.All', 'GroupMember.Read.All'),
        Tag          = ('UserAttributes', 'Presence', 'Licensing'),
        Author       = 'DevClate'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # More users (user principal name or object ID) to leave out of this test, on top of the pack-wide exclusions.
        [MaesterParameter(Kind = 'Entra.User')]
        [string[]] $ExcludedUsers,

        # More groups (object ID or mail address) whose members, including nested members, are left out of this test.
        [MaesterParameter(Kind = 'Entra.Group')]
        [string[]] $ExcludedGroups,

        # Also check disabled accounts, such as shared mailboxes and leavers.
        [bool] $IncludeDisabled = $false,

        # Most users to list in the result; 0 lists them all.
        [ValidateRange(0, 100000)]
        [int] $MaxRows = 100
    )

    $set = Get-CltUser -Property usageLocation -IncludeDisabled $IncludeDisabled -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups
    $users = $set.Users
    return (Invoke-CltPresenceCheck -Users $users -Property usageLocation -Label 'a usage location' -Population (Get-CltPopulation -IncludeDisabled $IncludeDisabled) -MaxRows $MaxRows -Note $set.Note)
}

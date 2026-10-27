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

    $users = Get-CltUser -Property usageLocation -IncludeDisabled $IncludeDisabled -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups
    return (Invoke-CltPresenceCheck -Users $users -Property usageLocation -Label 'a usage location' -Population (Get-CltPopulation -IncludeDisabled $IncludeDisabled) -MaxRows $MaxRows)
}

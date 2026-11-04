function Test-CltManager {
    <#
    .SYNOPSIS
    Checks that every enabled member user has a manager, apart from the top of the organisation.

    .DESCRIPTION
    Reads each user's manager in the same Graph request as the user ($expand=manager), instead of one
    request per user. Users whose job title is in ExcludedJobTitles (by default the CEO) are not checked.
    Converted from ENTRA.UA.1001 in DevClate/Custom-Maester-Tests.

    .EXAMPLE
    Invoke-MtTest -Path ./tests/Test.MP.CLT.UA.1002.ps1 -Parameter @{ ExcludedJobTitles = 'CEO', 'Managing Director' }
    #>
    [MaesterTest(
        Id           = 'MP.CLT.UA.1002',
        Title        = 'All member users have a manager.',
        Product      = 'entra',
        Feature      = 'identity-governance',
        Area         = 'identity-lifecycle',
        ResourceType = 'User',
        Severity     = 'Medium',
        UserImpact   = 'Low',
        ImplementationCost = 'Medium',
        Service      = 'Graph',
        Permission   = ('Graph:Scope:User.Read.All', 'Graph:Scope:GroupMember.Read.All'),
        Tag          = ('UserAttributes', 'Presence', 'Governance'),
        Author       = 'DevClate'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # Job titles at the top of the organisation that have no manager, matched exactly but ignoring case.
        [string[]] $ExcludedJobTitles = ('CEO', 'Chief Executive Officer'),

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

    $set = Get-CltUser -Property jobTitle -Expand 'manager($select=id,displayName)' -IncludeDisabled $IncludeDisabled -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups
    $users = $set.Users
    $topTitles = @($ExcludedJobTitles | Where-Object { $_ } | ForEach-Object { $_.Trim() })
    $users = @($users | Where-Object { -not ($_.jobTitle -and ($topTitles -contains "$($_.jobTitle)".Trim())) })

    return (Invoke-CltPresenceCheck -Users $users -Property manager -Label 'a manager' -Population (Get-CltPopulation -IncludeDisabled $IncludeDisabled) -MaxRows $MaxRows -Note $set.Note)
}

function Test-CltFaxNumber {
    <#
    .SYNOPSIS
    Checks that every enabled member user has a fax number.

    .DESCRIPTION
    Converted from ENTRA.UA.1013 in DevClate/Custom-Maester-Tests. Most organisations no longer use fax; disable this test in maester-config.json if yours does not.
    #>
    [MaesterTest(
        Id           = 'MP.CLT.UA.1016',
        Title        = 'All member users have a fax number.',
        Product      = 'entra',
        Feature      = 'identity-governance',
        Area         = 'identity-lifecycle',
        ResourceType = 'User',
        Severity     = 'Info',
        Service      = 'Graph',
        Permission   = ('User.Read.All', 'GroupMember.Read.All'),
        Tag          = ('UserAttributes', 'Presence', 'Phone', 'Fax', 'Optional'),
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

    $set = Get-CltUser -Property faxNumber -IncludeDisabled $IncludeDisabled -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups
    $users = $set.Users
    return (Invoke-CltPresenceCheck -Users $users -Property faxNumber -Label 'a fax number' -Population (Get-CltPopulation -IncludeDisabled $IncludeDisabled) -MaxRows $MaxRows -Note $set.Note)
}

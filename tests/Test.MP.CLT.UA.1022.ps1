function Test-CltApprovedCity {
    <#
    .SYNOPSIS
    Checks that every city set on enabled member users is one of the approved values.

    .DESCRIPTION
    The approved values come from this test's AllowedValues when it has any; otherwise from
    GlobalSettings."CLT.UA.AllowedValues".city (and the city of its approved locations) and the file in
    GlobalSettings."CLT.UA.AllowedValuesFile", together. Without any approved values the result is Investigate,
    with the values found, ready to copy into the config. Blank values are not checked here: the presence tests
    check those. Converted from ENTRA.UV.1003 in DevClate/Custom-Maester-Tests.

    .EXAMPLE
    Invoke-MtTest -Path ./tests/Test.MP.CLT.UA.1022.ps1 -Parameter @{ AllowedValues = 'Value one', 'Value two' }
    #>
    [MaesterTest(
        Id           = 'MP.CLT.UA.1022',
        Title        = 'User cities are on the approved list.',
        Product      = 'entra',
        Feature      = 'identity-governance',
        Area         = 'identity-lifecycle',
        ResourceType = 'User',
        Severity     = 'Low',
        UserImpact   = 'Low',
        ImplementationCost = 'Low',
        Service      = 'Graph',
        Permission   = ('Graph:Scope:User.Read.All', 'Graph:Scope:GroupMember.Read.All'),
        Tag          = ('UserAttributes', 'Validation', 'Address'),
        Author       = 'DevClate'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # Approved values for this test only; when set, the pack-wide CLT.UA.AllowedValues are not used.
        [string[]] $AllowedValues,

        # Treat values that differ only in letter case (finance and Finance) as different.
        [bool] $CaseSensitive = $true,

        # More users (user principal name or object ID) to leave out of this test, on top of the pack-wide exclusions.
        [string[]] $ExcludedUsers,

        # More groups (object IDs) whose members, including nested members, are left out of this test.
        [MaesterParameter(Kind = 'Entra.Group')]
        [string[]] $ExcludedGroups,

        # Also check disabled accounts, such as shared mailboxes and leavers.
        [bool] $IncludeDisabled = $false,

        # Most rows to list in the result; 0 lists them all.
        [ValidateRange(0, 100000)]
        [int] $MaxRows = 100
    )

    $set = Get-CltUser -Property city -IncludeDisabled $IncludeDisabled -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups
    return (Invoke-CltAllowedValueCheck -Set $set -Property city -Label 'city' -Column 'City' -Population (Get-CltPopulation -IncludeDisabled $IncludeDisabled) -AllowedValues $AllowedValues -CaseSensitive $CaseSensitive -MaxRows $MaxRows)
}

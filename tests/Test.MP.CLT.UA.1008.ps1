function Test-CltOfficeAddress {
    <#
    .SYNOPSIS
    Checks that every enabled member user has a complete office address.

    .DESCRIPTION
    One test for the address fields that were five separate 2.x tests (ENTRA.UA.1003 to 1007 in
    DevClate/Custom-Maester-Tests). Fields chooses which parts must be set; the result lists, for each user,
    the parts that are missing.

    .EXAMPLE
    Invoke-MtTest -Path ./tests/Test.MP.CLT.UA.1008.ps1 -Parameter @{ Fields = 'city', 'country', 'officeLocation' }
    #>
    [MaesterTest(
        Id           = 'MP.CLT.UA.1008',
        Title        = 'All member users have a complete office address.',
        Product      = 'entra',
        Feature      = 'identity-governance',
        Area         = 'identity-lifecycle',
        ResourceType = 'User',
        Severity     = 'Low',
        UserImpact   = 'Low',
        ImplementationCost = 'Medium',
        Service      = 'Graph',
        Permission   = ('Graph:Scope:User.Read.All', 'Graph:Scope:GroupMember.Read.All'),
        Tag          = ('UserAttributes', 'Presence', 'Address'),
        Author       = 'DevClate'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # Address fields that must all be set.
        [ValidateSet('streetAddress', 'city', 'state', 'postalCode', 'country', 'officeLocation')]
        [string[]] $Fields = ('streetAddress', 'city', 'state', 'postalCode', 'country'),

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

    $population = Get-CltPopulation -IncludeDisabled $IncludeDisabled
    $set = Get-CltUser -Property $Fields -IncludeDisabled $IncludeDisabled -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups
    $users = $set.Users
    if ($users.Count -eq 0) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason "There are no $population to check after exclusions."
    }

    $rows = [System.Collections.Generic.List[object]]::new()
    foreach ($user in $users) {
        $missing = @($Fields | Where-Object { Test-CltIsBlank $user.$_ })
        if ($missing.Count) {
            $rows.Add([pscustomobject]@{
                'User'           = "$($user.displayName) ($($user.userPrincipalName))"
                'Missing fields' = $missing -join ', '
            })
        }
    }

    $checked = $Fields -join ', '
    if ($rows.Count -eq 0) {
        Add-CltResult -Note $set.Note -Result "Well done. All $($users.Count) $population have a complete office address ($checked)."
        return $true
    }

    $table = Format-CltTable -Rows $rows.ToArray() -Columns 'User', 'Missing fields' -MaxRows $MaxRows
    Add-CltResult -Note $set.Note -Result "$($rows.Count) of $($users.Count) $population are missing part of their office address (checked: $checked).`n`n$table"
    return $false
}

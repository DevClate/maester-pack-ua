function Test-CltApprovedLocation {
    <#
    .SYNOPSIS
    Checks that each enabled member user's address matches one of the approved office locations.

    .DESCRIPTION
    The approved locations come from GlobalSettings."CLT.UA.AllowedValues".locations and the validLocations or
    locations of the file in GlobalSettings."CLT.UA.AllowedValuesFile". A user matches a location when every field
    in Fields equals the location's value; a field the location leaves out is not compared. Users with none of the
    fields set are not checked (MP.CLT.UA.1008 checks missing address fields). For each user that matches no
    location, the result names the closest location and the fields that differ.
    Replaces ENTRA.UV.1010.L01 (Fields with businessPhones) and ENTRA.UV.1010.L02 (without) in
    DevClate/Custom-Maester-Tests.

    .EXAMPLE
    Invoke-MtTest -Path ./tests/Test.MP.CLT.UA.1026.ps1 -Parameter @{ Fields = 'streetAddress', 'city', 'postalCode', 'businessPhones' }
    #>
    [MaesterTest(
        Id           = 'MP.CLT.UA.1026',
        Title        = 'User addresses match an approved office location.',
        Product      = 'entra',
        Feature      = 'identity-governance',
        Area         = 'identity-lifecycle',
        ResourceType = 'User',
        Severity     = 'Low',
        UserImpact   = 'Low',
        ImplementationCost = 'Medium',
        Service      = 'Graph',
        Permission   = ('Graph:Scope:User.Read.All', 'Graph:Scope:GroupMember.Read.All'),
        Tag          = ('UserAttributes', 'Validation', 'Address'),
        Author       = 'DevClate'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # Fields that must match an approved location; add businessPhones or officeLocation to compare them too.
        [ValidateSet('streetAddress', 'city', 'state', 'postalCode', 'country', 'companyName', 'businessPhones', 'officeLocation')]
        [string[]] $Fields = ('streetAddress', 'city', 'state', 'postalCode', 'country', 'companyName'),

        # Treat values that differ only in letter case (new york and New York) as different.
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

    $population = Get-CltPopulation -IncludeDisabled $IncludeDisabled
    $set = Get-CltUser -Property $Fields -IncludeDisabled $IncludeDisabled -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups
    $users = @($set.Users | Where-Object { $user = $_; @($Fields | Where-Object { -not (Test-CltIsBlank $user.$_) }).Count -gt 0 })
    if ($users.Count -eq 0) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason "None of the $population has any of $($Fields -join ', ') set."
    }

    $comparison = if ($CaseSensitive) { [System.StringComparison]::Ordinal } else { [System.StringComparison]::OrdinalIgnoreCase }
    $locations = @((Get-CltAllowedValueSet).Locations)
    $checked = $Fields -join ', '

    if ($locations.Count -eq 0) {
        $comparer = if ($CaseSensitive) { [System.StringComparer]::Ordinal } else { [System.StringComparer]::OrdinalIgnoreCase }
        $groups = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[object]]]::new($comparer)
        foreach ($user in $users) {
            $address = ($Fields | ForEach-Object { (@($user.$_) | Where-Object { $_ }) -join ' / ' }) -join ' · '
            if (-not $groups.ContainsKey($address)) { $groups[$address] = [System.Collections.Generic.List[object]]::new() }
            $groups[$address].Add($user)
        }
        $rows = @($groups.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | ForEach-Object { ConvertTo-CltValueRow -Entry $_ -Column 'Address' })
        $table = Format-CltTable -Rows $rows -Columns 'Address', 'Users', 'Examples' -MaxRows $MaxRows
        Add-CltResult -Note $set.Note -Investigate -Result ("No approved locations are set, so the $($groups.Count) addresses used by $($users.Count) $population are listed for review ($checked). " +
            "Add your offices to **CLT.UA.AllowedValues** → **locations** under GlobalSettings in maester-config.json so this test can enforce them.`n`n$table")
        return $true
    }

    $failed = [System.Collections.Generic.List[object]]::new()
    foreach ($user in $users) {
        $best = $null
        $bestScore = -1
        $bestDiffs = @()
        foreach ($location in $locations) {
            $diffs = [System.Collections.Generic.List[string]]::new()
            $score = 0
            foreach ($field in $Fields) {
                if (-not $location.ContainsKey($field)) { continue }
                $userValues = @(@($user.$field) | Where-Object { -not (Test-CltIsBlank $_) } | ForEach-Object { [string]$_ })
                $match = $false
                foreach ($value in $userValues) {
                    foreach ($approved in $location[$field]) { if ([string]::Equals($value, $approved, $comparison)) { $match = $true } }
                }
                if ($match) { $score++ } else {
                    $shown = if ($userValues.Count) { "``$($userValues -join ' / ')``" } else { '(blank)' }
                    $diffs.Add("$field $shown")
                }
            }
            if ($diffs.Count -eq 0) { $best = $location; $bestDiffs = @(); break }
            if ($score -gt $bestScore) { $best = $location; $bestScore = $score; $bestDiffs = $diffs.ToArray() }
        }
        if ($bestDiffs.Count -eq 0) { continue }
        $name = if ($best.name) { $best.name } else { (@($best['streetAddress']) + @($best['city']) | Where-Object { $_ } | Select-Object -First 2) -join ', ' }
        $failed.Add([pscustomobject]@{
                'User'                      = "$($user.displayName) ($($user.userPrincipalName))"
                'Closest approved location' = $name
                'Differs in'                = $bestDiffs -join '; '
            })
    }

    if ($failed.Count -eq 0) {
        Add-CltResult -Note $set.Note -Result "Well done. All $($users.Count) $population with an address match one of the $($locations.Count) approved locations ($checked)."
        return $true
    }

    $table = Format-CltTable -Rows $failed.ToArray() -Columns 'User', 'Closest approved location', 'Differs in' -MaxRows $MaxRows
    Add-CltResult -Note $set.Note -Result ("$($failed.Count) of $($users.Count) $population have an address that matches none of the $($locations.Count) approved locations (compared: $checked). " +
        "Each row shows the closest location and the fields that differ.`n`n$table")
    return $false
}

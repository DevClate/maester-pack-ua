function Test-CltCountrySpelling {
    <#
    .SYNOPSIS
    Checks that the country attribute on member users uses one approved spelling per country.

    .DESCRIPTION
    Country is free text, so US, USA, U.S. and United States can all appear in one tenant. With
    AllowedCountries set, every country that is set must be one of those values. Without it, the test lists
    the distinct values for review: Investigate when there is more than one, Passed when there is one.
    Blank countries are ignored (MP.CLT.UA.1008 checks for those).

    .EXAMPLE
    Invoke-MtTest -Path ./tests/Test.MP.CLT.UA.1013.ps1 -Parameter @{ AllowedCountries = 'United States', 'Canada' }
    #>
    [MaesterTest(
        Id           = 'MP.CLT.UA.1013',
        Title        = 'User country values use an approved spelling.',
        Product      = 'entra',
        Feature      = 'identity-governance',
        Area         = 'identity-lifecycle',
        ResourceType = 'User',
        Severity     = 'Low',
        UserImpact   = 'Low',
        ImplementationCost = 'Low',
        Service      = 'Graph',
        Permission   = ('User.Read.All', 'GroupMember.Read.All'),
        Tag          = ('UserAttributes', 'Format', 'Address'),
        Author       = 'DevClate'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # The exact country values your organisation uses, such as United States or US. Blank lists the values found instead.
        [string[]] $AllowedCountries,

        # Treat values that differ only in letter case (united states and United States) as different spellings.
        [bool] $CaseSensitive = $true,

        # More users (user principal name or object ID) to leave out of this test, on top of the pack-wide exclusions.
        [MaesterParameter(Kind = 'Entra.User')]
        [string[]] $ExcludedUsers,

        # More groups (object ID or mail address) whose members, including nested members, are left out of this test.
        [MaesterParameter(Kind = 'Entra.Group')]
        [string[]] $ExcludedGroups,

        # Also check disabled accounts, such as shared mailboxes and leavers.
        [bool] $IncludeDisabled = $false,

        # Most rows to list in the result; 0 lists them all.
        [ValidateRange(0, 100000)]
        [int] $MaxRows = 100
    )

    $population = Get-CltPopulation -IncludeDisabled $IncludeDisabled
    $set = Get-CltUser -Property country -IncludeDisabled $IncludeDisabled -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups
    $users = @($set.Users |
        Where-Object { -not (Test-CltIsBlank $_.country) })
    if ($users.Count -eq 0) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason "None of the $population has a country set."
    }

    $comparer = if ($CaseSensitive) { [System.StringComparer]::Ordinal } else { [System.StringComparer]::OrdinalIgnoreCase }
    $groups = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[object]]]::new($comparer)
    foreach ($user in $users) {
        $value = "$($user.country)"
        if (-not $groups.ContainsKey($value)) { $groups[$value] = [System.Collections.Generic.List[object]]::new() }
        $groups[$value].Add($user)
    }

    $allowed = [System.Collections.Generic.HashSet[string]]::new($comparer)
    foreach ($country in $AllowedCountries) {
        if (-not [string]::IsNullOrWhiteSpace($country)) { [void]$allowed.Add($country) }
    }

    if ($allowed.Count -eq 0) {
        $rows = @($groups.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | ForEach-Object { ConvertTo-CltCountryRow -Entry $_ })
        $table = Format-CltTable -Rows $rows -Columns 'Country value', 'Users', 'Examples' -MaxRows $MaxRows
        if ($groups.Count -eq 1) {
            Add-CltResult -Note $set.Note -Result "Well done. All $($users.Count) $population with a country use the same value.`n`n$table"
            return $true
        }
        Add-CltResult -Note $set.Note -Investigate -Result ("The $($users.Count) $population with a country use $($groups.Count) different values. " +
            "Check whether any are different spellings of the same country, then list the spellings you use in **AllowedCountries** " +
            "for MP.CLT.UA.1013 in maester-config.json so this test can enforce them.`n`n$table")
        return $true
    }

    $rejected = @($groups.GetEnumerator() | Where-Object { -not $allowed.Contains($_.Key) })
    if ($rejected.Count -eq 0) {
        Add-CltResult -Note $set.Note -Result "Well done. All $($users.Count) $population with a country use an approved value."
        return $true
    }

    $rows = @($rejected | Sort-Object { $_.Value.Count } -Descending | ForEach-Object { ConvertTo-CltCountryRow -Entry $_ })
    $userCount = ($rejected | ForEach-Object { $_.Value.Count } | Measure-Object -Sum).Sum
    $table = Format-CltTable -Rows $rows -Columns 'Country value', 'Users', 'Examples' -MaxRows $MaxRows
    Add-CltResult -Note $set.Note -Result ("$userCount of $($users.Count) $population have a country that is not an approved value " +
        "($(@($AllowedCountries | Where-Object { $_ }) -join ', ')).`n`n$table")
    return $false
}

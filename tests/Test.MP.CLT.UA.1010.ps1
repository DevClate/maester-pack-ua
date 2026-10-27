function Test-CltEmployeeIdUnique {
    <#
    .SYNOPSIS
    Checks that no two member users share an employee ID.

    .DESCRIPTION
    Compares employee IDs after trimming spaces and ignoring case, and optionally leading zeros, so
    "E100" and " e100" count as the same ID. Disabled accounts are checked by default, because a rehire
    whose new account collides with their old one is the most common duplicate. Blank IDs are ignored
    (MP.CLT.UA.1005 checks for those).
    #>
    [MaesterTest(
        Id           = 'MP.CLT.UA.1010',
        Title        = 'Every employee ID belongs to only one user.',
        Product      = 'entra',
        Feature      = 'identity-governance',
        Area         = 'identity-lifecycle',
        ResourceType = 'User',
        Severity     = 'Medium',
        UserImpact   = 'Low',
        ImplementationCost = 'Medium',
        Service      = 'Graph',
        Permission   = ('User.Read.All', 'GroupMember.Read.All'),
        Tag          = ('UserAttributes', 'Format', 'Governance'),
        Author       = 'DevClate'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # Also check disabled accounts, where old accounts of rehired staff are found.
        [bool] $IncludeDisabled = $true,

        # Treat IDs that differ only in leading zeros (00123 and 123) as the same ID.
        [bool] $IgnoreLeadingZeros = $false,

        # More users (user principal name or object ID) to leave out of this test, on top of the pack-wide exclusions.
        [MaesterParameter(Kind = 'Entra.User')]
        [string[]] $ExcludedUsers,

        # More groups (object ID or mail address) whose members, including nested members, are left out of this test.
        [MaesterParameter(Kind = 'Entra.Group')]
        [string[]] $ExcludedGroups,

        # Most rows to list in the result; 0 lists them all.
        [ValidateRange(0, 100000)]
        [int] $MaxRows = 100
    )

    $population = Get-CltPopulation -IncludeDisabled $IncludeDisabled
    $set = Get-CltUser -Property employeeId -IncludeDisabled $IncludeDisabled -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups
    $users = @($set.Users |
        Where-Object { -not (Test-CltIsBlank $_.employeeId) })
    if ($users.Count -eq 0) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason "None of the $population has an employee ID, so there is nothing to compare."
    }

    $byId = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[object]]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($user in $users) {
        $key = "$($user.employeeId)".Trim()
        if ($IgnoreLeadingZeros) {
            $key = $key.TrimStart('0')
            if (-not $key) { $key = '0' }
        }
        if (-not $byId.ContainsKey($key)) { $byId[$key] = [System.Collections.Generic.List[object]]::new() }
        $byId[$key].Add($user)
    }

    $rows = foreach ($entry in $byId.GetEnumerator()) {
        if ($entry.Value.Count -lt 2) { continue }
        [pscustomobject]@{
            'Employee ID' = $entry.Key
            'Users'       = ($entry.Value | ForEach-Object {
                    $state = if ($_.accountEnabled -eq $false) { ', disabled' } else { '' }
                    "$($_.userPrincipalName) (ID ``$($_.employeeId)``$state)"
                }) -join '<br>'
        }
    }
    $rows = @($rows | Sort-Object 'Employee ID')

    if ($rows.Count -eq 0) {
        Add-CltResult -Note $set.Note -Result "Well done. The $($users.Count) $population with an employee ID all have different IDs."
        return $true
    }

    $table = Format-CltTable -Rows $rows -Columns 'Employee ID', 'Users' -MaxRows $MaxRows
    Add-CltResult -Note $set.Note -Result "$($rows.Count) employee ID(s) are shared by more than one user. Each ID should identify one person.`n`n$table"
    return $false
}

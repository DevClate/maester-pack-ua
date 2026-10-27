function Test-CltAttributeWhitespace {
    <#
    .SYNOPSIS
    Checks user name, job and location attributes for leading, trailing, repeated or invisible spaces.

    .DESCRIPTION
    Flags values that start or end with white space, contain two or more spaces in a row, contain tabs or
    line breaks, or contain non-breaking or zero-width characters (usually pasted from a spreadsheet or
    web page). These are invisible in most admin screens but break exact matches in dynamic group rules,
    filters and HR matching.
    #>
    [MaesterTest(
        Id           = 'MP.CLT.UA.1012',
        Title        = 'User name, job and location attributes have no stray spaces.',
        Product      = 'entra',
        Feature      = 'identity-governance',
        Area         = 'identity-lifecycle',
        ResourceType = 'User',
        Severity     = 'Low',
        UserImpact   = 'Low',
        ImplementationCost = 'Low',
        Service      = 'Graph',
        Permission   = ('User.Read.All', 'GroupMember.Read.All'),
        Tag          = ('UserAttributes', 'Format'),
        Author       = 'DevClate'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # Text attributes to check.
        [ValidateSet('displayName', 'givenName', 'surname', 'jobTitle', 'department', 'companyName', 'officeLocation',
            'streetAddress', 'city', 'state', 'postalCode', 'country', 'employeeId', 'employeeType')]
        [string[]] $Attributes = ('displayName', 'givenName', 'surname', 'jobTitle', 'department', 'companyName', 'officeLocation', 'city', 'state', 'country'),

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
    $set = Get-CltUser -Property $Attributes -IncludeDisabled $IncludeDisabled -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups
    $users = $set.Users
    if ($users.Count -eq 0) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason "There are no $population to check after exclusions."
    }

    $invisible = "[$([char]0x00A0)$([char]0x2007)$([char]0x202F)$([char]0x200B)$([char]0x200C)$([char]0x200D)$([char]0xFEFF)]"
    $rows = [System.Collections.Generic.List[object]]::new()
    foreach ($user in $users) {
        foreach ($attribute in $Attributes) {
            $value = $user.$attribute
            if ($value -isnot [string] -or $value.Length -eq 0) { continue }

            $problems = @(
                if ($value -match '^\s') { 'leading space' }
                if ($value -match '\s$') { 'trailing space' }
                if ($value -match ' {2,}') { 'repeated spaces' }
                if ($value -match '[\t\r\n]') { 'tab or line break' }
                if ($value -match $invisible) { 'invisible character' }
            )
            if ($problems.Count -eq 0) { continue }

            # Show where the problem is: spaces as a visible mark, other characters by name.
            $shown = $value -replace ' ', ([string][char]0x2423) -replace "`t", '[tab]' -replace '\r?\n', '[line break]' -replace $invisible, '[invisible]'
            $rows.Add([pscustomobject]@{
                'User'      = "$($user.userPrincipalName)"
                'Attribute' = $attribute
                'Problem'   = $problems -join ', '
                'Value'     = $shown
            })
        }
    }

    if ($rows.Count -eq 0) {
        Add-CltResult -Note $set.Note -Result "Well done. None of the $($users.Count) $population has stray spaces in $($Attributes -join ', ')."
        return $true
    }

    $table = Format-CltTable -Rows $rows.ToArray() -Columns 'User', 'Attribute', 'Problem', 'Value' -MaxRows $MaxRows
    Add-CltResult -Note $set.Note -Result ("$($rows.Count) attribute value(s) on $population have stray or invisible spaces. In the table, " +
        "$([char]0x2423) marks each space.`n`n$table")
    return $false
}

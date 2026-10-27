function Get-CltUserSelect {
    <#
    .SYNOPSIS
    Returns the user properties every devclate.user-attributes test reads, so they share one cached Graph request.

    .DESCRIPTION
    Invoke-MtGraphRequest caches each request by its full URI. When every test asks for the same $select, the
    first test reads the directory and the rest are answered from the cache. employeeHireDate is not in the list:
    it needs User-LifeCycleInfo.Read.All, so only MP.CLT.UA.1006 asks for it.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param()

    return @(
        'id', 'displayName', 'userPrincipalName', 'userType', 'accountEnabled',
        'givenName', 'surname', 'usageLocation', 'jobTitle', 'department', 'companyName', 'employeeId',
        'streetAddress', 'city', 'state', 'postalCode', 'country', 'officeLocation',
        'businessPhones', 'mobilePhone', 'faxNumber'
    )
}

function Get-CltUser {
    <#
    .SYNOPSIS
    Returns the users a devclate.user-attributes test checks, with the requested properties.

    .DESCRIPTION
    Reads users from Microsoft Graph with Invoke-MtGraphRequest (cached and paged by Maester).
    Leaves out the Microsoft Entra Connect sync account, the users and group members a test is told to
    exempt and, unless IncludeDisabled is set, disabled accounts.

    Without Expand, every test sends the same request (all users, the properties from Get-CltUserSelect) and
    filters the user type and account state here, so the directory is read from Graph once per run. With
    Expand (manager, sponsors), Graph does not accept every $filter together with $expand on users, so those
    are filtered here too.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        # Extra user properties to select, beyond the ones every test shares.
        [string[]] $Property,

        # Member or Guest.
        [ValidateSet('Member', 'Guest')]
        [string] $UserType = 'Member',

        # Also return disabled accounts.
        [bool] $IncludeDisabled = $false,

        # User principal names or object IDs to leave out.
        [string[]] $ExcludedUsers,

        # Object IDs of groups whose members (including nested members) are left out.
        [string[]] $ExcludedGroups,

        # A relationship to expand, such as manager($select=id,displayName).
        [string] $Expand
    )

    # Named parameters, not a splat: Maester's pack scan must see that every request is a read.
    if ($Expand) {
        $select = @('id', 'displayName', 'userPrincipalName', 'userType', 'accountEnabled') + @($Property | Where-Object { $_ }) |
            Select-Object -Unique
        $users = @(Invoke-MtGraphRequest -RelativeUri 'users' -ApiVersion v1.0 -Select $select -QueryParameters @{ '$expand' = $Expand })
    } else {
        $select = @(Get-CltUserSelect) + @($Property | Where-Object { $_ }) | Select-Object -Unique
        $users = @(Invoke-MtGraphRequest -RelativeUri 'users' -ApiVersion v1.0 -Select $select)
    }

    $excluded = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($user in $ExcludedUsers) {
        if (-not [string]::IsNullOrWhiteSpace($user)) { [void]$excluded.Add($user.Trim()) }
    }
    foreach ($group in $ExcludedGroups) {
        if ([string]::IsNullOrWhiteSpace($group)) { continue }
        $members = @(Invoke-MtGraphRequest -RelativeUri "groups/$([uri]::EscapeDataString($group.Trim()))/transitiveMembers" -ApiVersion v1.0 -Select id)
        foreach ($member in $members) {
            if ($member.id) { [void]$excluded.Add([string]$member.id) }
        }
    }

    $kept = foreach ($user in $users) {
        if (-not $user) { continue }
        # Some old accounts have no userType; Microsoft Entra treats them as members.
        $type = if ($user.userType) { "$($user.userType)" } else { 'Member' }
        if ($type -ne $UserType) { continue }
        if (-not $IncludeDisabled -and $user.accountEnabled -eq $false) { continue }
        # Microsoft Entra Connect creates this account; it never has HR attributes.
        if ("$($user.userPrincipalName)" -like 'Sync_*' -or $user.displayName -eq 'On-Premises Directory Synchronization Service Account') { continue }
        if ($excluded.Contains([string]$user.id) -or $excluded.Contains([string]$user.userPrincipalName)) { continue }
        $user
    }
    return @($kept)
}

function Test-CltIsBlank {
    <#
    .SYNOPSIS
    Returns $true when a Graph value is null, empty, white space, or a list with no non-blank items.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param($Value)

    if ($null -eq $Value) { return $true }
    if ($Value -is [string]) { return [string]::IsNullOrWhiteSpace($Value) }
    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [System.Collections.IDictionary]) {
        foreach ($item in $Value) {
            if ($null -ne $item -and -not [string]::IsNullOrWhiteSpace([string]$item)) { return $false }
        }
        return $true
    }
    return [string]::IsNullOrWhiteSpace([string]$Value)
}

function Get-CltPopulation {
    <#
    .SYNOPSIS
    Returns the words used in results for the users a test checked, such as "enabled member users".
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [ValidateSet('Member', 'Guest')]
        [string] $UserType = 'Member',
        [bool] $IncludeDisabled = $false
    )

    $type = $UserType.ToLowerInvariant()
    if ($IncludeDisabled) { return "$type users" }
    return "enabled $type users"
}

function Get-CltMoreRowsNote {
    <#
    .SYNOPSIS
    Returns the line under a capped list that says how many were left out and how to list them all.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [int] $Shown,
        [int] $Total
    )

    return ("Showing the first $Shown of $Total. To list them all, set **MaxRows** to ``0`` for this test in " +
        "maester-config.json, or run it with ``Invoke-MtTest -Id <test ID> -Parameter @{ MaxRows = 0 }``.")
}

function Format-CltTable {
    <#
    .SYNOPSIS
    Builds a Markdown table from objects, escaping pipes and line breaks, and showing at most MaxRows rows (0 for all).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [object[]] $Rows,
        [string[]] $Columns,
        [int] $MaxRows = 100
    )

    $shown = if ($MaxRows -gt 0) { @($Rows | Select-Object -First $MaxRows) } else { @($Rows) }
    $lines = [System.Collections.Generic.List[string]]::new()
    $lines.Add('| ' + ($Columns -join ' | ') + ' |')
    $lines.Add('|' + (' --- |' * $Columns.Count))
    foreach ($row in $shown) {
        $cells = foreach ($column in $Columns) { ("$($row.$column)" -replace '\|', '\|') -replace '\r?\n', ' ' }
        $lines.Add('| ' + ($cells -join ' | ') + ' |')
    }
    if ($Rows.Count -gt $shown.Count) {
        $lines.Add('')
        $lines.Add((Get-CltMoreRowsNote -Shown $shown.Count -Total $Rows.Count))
    }
    return ($lines -join "`n")
}

function ConvertTo-CltCountryRow {
    <#
    .SYNOPSIS
    Turns one country value and the users that have it into a table row for MP.CLT.UA.1013.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param($Entry)

    [pscustomobject]@{
        'Country value' = "``$($Entry.Key)``"
        'Users'         = $Entry.Value.Count
        'Examples'      = (@($Entry.Value | Select-Object -First 3 | ForEach-Object { $_.userPrincipalName }) -join ', ')
    }
}

function Invoke-CltPresenceCheck {
    <#
    .SYNOPSIS
    Reports the users that have no value in Property, and returns $true when there are none.

    .DESCRIPTION
    Shared by the presence tests in this pack. Lists failing users with Maester's user list, which links
    each user to the Microsoft Entra admin center, and shows each user's name and user principal name.
    Lists at most MaxRows users (0 lists them all), so a value most users lack does not fill the report.
    Skips the test as not applicable when no users are left to check after exclusions.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [object[]] $Users,

        # The property that must have a value.
        [string] $Property,

        # How the value is named in results, such as "a job title".
        [string] $Label,

        # How the checked users are named in results, such as "enabled member users".
        [string] $Population,

        # Most users to list in the result; 0 lists them all.
        [int] $MaxRows = 100
    )

    if ($Users.Count -eq 0) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason "There are no $Population to check after exclusions."
    }

    $missing = [System.Collections.Generic.List[object]]::new()
    foreach ($user in $Users) {
        if (Test-CltIsBlank $user.$Property) { $missing.Add($user) }
    }

    if ($missing.Count -eq 0) {
        Add-MtTestResultDetail -Result "Well done. All $($Users.Count) $Population have $Label."
        return $true
    }

    $listed = if ($MaxRows -gt 0) { @($missing | Select-Object -First $MaxRows) } else { $missing.ToArray() }
    # Name and user principal name, because display names are often shared.
    $objects = foreach ($user in $listed) {
        $name = if ($user.displayName) { "$($user.displayName) ($($user.userPrincipalName))" } else { "$($user.userPrincipalName)" }
        [pscustomobject]@{ id = $user.id; displayName = $name; userPrincipalName = $user.userPrincipalName }
    }

    $result = "$($missing.Count) of $($Users.Count) $Population have no $Label.`n`n%TestResult%"
    if ($missing.Count -gt $listed.Count) {
        $result += "`n" + (Get-CltMoreRowsNote -Shown $listed.Count -Total $missing.Count)
    }
    Add-MtTestResultDetail -Result $result -GraphObjects @($objects) -GraphObjectType Users
    return $false
}

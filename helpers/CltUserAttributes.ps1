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
        'id', 'displayName', 'userPrincipalName', 'userType', 'accountEnabled', 'assignedLicenses',
        'givenName', 'surname', 'usageLocation', 'jobTitle', 'department', 'companyName', 'employeeId',
        'streetAddress', 'city', 'state', 'postalCode', 'country', 'officeLocation',
        'businessPhones', 'mobilePhone', 'faxNumber'
    )
}

function Get-CltSetting {
    <#
    .SYNOPSIS
    Returns a GlobalSettings value from maester-config.json, or Default when it is not set or cannot be read.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        # The setting's name, such as CLT.UA.ExcludedUsers.
        [string] $Name,

        # The value to return when the setting is not set.
        $Default
    )

    if (-not (Get-Command -Name Get-MtSetting -ErrorAction SilentlyContinue)) { return $Default }
    $value = Get-MtSetting -Name $Name -Default $Default
    if ($null -eq $value) { return $Default }
    return $value
}

function Get-CltSettingList {
    <#
    .SYNOPSIS
    Returns a GlobalSettings value as a list of non-blank strings, whether the config holds one string or a list.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        # The setting's name, such as CLT.UA.ExcludedGroups.
        [string] $Name
    )

    $list = foreach ($item in @(Get-CltSetting -Name $Name -Default @())) {
        if ($null -ne $item -and -not [string]::IsNullOrWhiteSpace([string]$item)) { ([string]$item).Trim() }
    }
    return @($list)
}

function Test-CltSettingTrue {
    <#
    .SYNOPSIS
    Reads a true/false GlobalSettings value, accepting true, false, "true" or "false".
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # The setting's name, such as CLT.UA.OnlyLicensedUsers.
        [string] $Name,

        # The value when the setting is not set.
        [bool] $Default = $false
    )

    $value = Get-CltSetting -Name $Name -Default $Default
    if ($value -is [bool]) { return $value }
    if ($value -is [string]) {
        if ($value -match '^\s*(true|yes|1)\s*$') { return $true }
        if ($value -match '^\s*(false|no|0)\s*$') { return $false }
        return $Default
    }
    return [bool]$value
}

function Get-CltGroupMemberId {
    <#
    .SYNOPSIS
    Returns the object IDs of a group's members, including nested members. The group is an object ID or a mail address.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        # The group's object ID, or its mail address or mail nickname.
        [string] $Group
    )

    $Group = $Group.Trim()
    $groupIds = if ($Group -match '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$') {
        @($Group)
    } else {
        $escaped = $Group.Replace("'", "''")
        @(Invoke-MtGraphRequest -RelativeUri 'groups' -ApiVersion v1.0 -Select id -Filter "mail eq '$escaped' or mailNickname eq '$escaped'" |
                ForEach-Object { $_.id } | Where-Object { $_ })
    }

    $ids = foreach ($id in $groupIds) {
        $members = @(Invoke-MtGraphRequest -RelativeUri "groups/$([uri]::EscapeDataString($id))/transitiveMembers" -ApiVersion v1.0 -Select id -QueryParameters @{ '$top' = 999 })
        foreach ($member in $members) { if ($member.id) { [string]$member.id } }
    }
    return @($ids)
}

function New-CltExclusionSet {
    <#
    .SYNOPSIS
    Builds a set of user object IDs and user principal names from users and groups, for leaving users out.
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.HashSet[string]])]
    param(
        # User principal names or object IDs.
        [string[]] $Users,

        # Group object IDs or mail addresses; their members, including nested members, are added.
        [string[]] $Groups
    )

    $set = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($user in $Users) {
        if (-not [string]::IsNullOrWhiteSpace($user)) { [void]$set.Add($user.Trim()) }
    }
    foreach ($group in $Groups) {
        if ([string]::IsNullOrWhiteSpace($group)) { continue }
        foreach ($id in (Get-CltGroupMemberId -Group $group)) { [void]$set.Add($id) }
    }
    return , $set
}

function Get-CltExclusionSource {
    <#
    .SYNOPSIS
    Returns the three lists of users to leave out, in the order they are applied: emergency access accounts,
    the pack-wide exclusions and the test's own exclusions.

    .DESCRIPTION
    - Emergency access: Maester's GlobalSettings.EmergencyAccessAccounts (entries with Id or UserPrincipalName,
      and Type User or Group). Turn it off for this pack with GlobalSettings."CLT.UA.ExcludeEmergencyAccessAccounts" = false.
    - Pack-wide: GlobalSettings."CLT.UA.ExcludedUsers" and "CLT.UA.ExcludedGroups", for every test in the pack.
    - This test: the test's ExcludedUsers and ExcludedGroups parameters.
    The lists add up: a test's own exclusions never replace the others.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        # The test's own ExcludedUsers parameter.
        [string[]] $ExcludedUsers,

        # The test's own ExcludedGroups parameter.
        [string[]] $ExcludedGroups
    )

    $emergencyUsers = [System.Collections.Generic.List[string]]::new()
    $emergencyGroups = [System.Collections.Generic.List[string]]::new()
    if (Test-CltSettingTrue -Name 'CLT.UA.ExcludeEmergencyAccessAccounts' -Default $true) {
        foreach ($account in @(Get-CltSetting -Name 'EmergencyAccessAccounts' -Default @())) {
            if ($null -eq $account) { continue }
            if ($account -is [string]) { $emergencyUsers.Add($account); continue }
            $identifier = if ($account.Id) { [string]$account.Id } else { [string]$account.UserPrincipalName }
            if ([string]::IsNullOrWhiteSpace($identifier)) { continue }
            if ("$($account.Type)" -eq 'Group') { $emergencyGroups.Add($identifier) } else { $emergencyUsers.Add($identifier) }
        }
    }

    return @(
        [pscustomobject]@{ Name = 'emergency access'; Set = (New-CltExclusionSet -Users $emergencyUsers -Groups $emergencyGroups) }
        [pscustomobject]@{ Name = 'pack-wide'; Set = (New-CltExclusionSet -Users (Get-CltSettingList -Name 'CLT.UA.ExcludedUsers') -Groups (Get-CltSettingList -Name 'CLT.UA.ExcludedGroups')) }
        [pscustomobject]@{ Name = 'this test'; Set = (New-CltExclusionSet -Users $ExcludedUsers -Groups $ExcludedGroups) }
    )
}

function Get-CltUser {
    <#
    .SYNOPSIS
    Returns the users a devclate.user-attributes test checks (Users), and a note for the result that says who
    was left out and why (Note).

    .DESCRIPTION
    Reads users from Microsoft Graph with Invoke-MtGraphRequest (cached and paged by Maester), then leaves out:
    users of the other type (member or guest); disabled accounts unless IncludeDisabled is set; the Microsoft
    Entra Connect sync account; unlicensed members when GlobalSettings."CLT.UA.OnlyLicensedUsers" is true; and
    the users from Get-CltExclusionSource.

    Without Expand, every test sends the same request (all users, the properties from Get-CltUserSelect, 999 per
    page), so the directory is read from Graph once per run. With Expand (manager, sponsors), Graph does not
    accept every $filter together with $expand on users, so the filtering is done here.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        # Extra user properties to select, beyond the ones every test shares.
        [string[]] $Property,

        # Member or Guest.
        [ValidateSet('Member', 'Guest')]
        [string] $UserType = 'Member',

        # Also return disabled accounts.
        [bool] $IncludeDisabled = $false,

        # The test's own user principal names or object IDs to leave out.
        [string[]] $ExcludedUsers,

        # The test's own group object IDs (or mail addresses) whose members, including nested members, are left out.
        [string[]] $ExcludedGroups,

        # A relationship to expand, such as manager($select=id,displayName).
        [string] $Expand
    )

    # Named parameters, not a splat: Maester's pack scan must see that every request is a read.
    if ($Expand) {
        $select = @('id', 'displayName', 'userPrincipalName', 'userType', 'accountEnabled', 'assignedLicenses') + @($Property | Where-Object { $_ }) |
            Select-Object -Unique
        $users = @(Invoke-MtGraphRequest -RelativeUri 'users' -ApiVersion v1.0 -Select $select -QueryParameters @{ '$expand' = $Expand })
    } else {
        $select = @(Get-CltUserSelect) + @($Property | Where-Object { $_ }) | Select-Object -Unique
        $users = @(Invoke-MtGraphRequest -RelativeUri 'users' -ApiVersion v1.0 -Select $select -QueryParameters @{ '$top' = 999 })
    }

    $onlyLicensed = $UserType -eq 'Member' -and (Test-CltSettingTrue -Name 'CLT.UA.OnlyLicensedUsers' -Default $false)
    $sources = @(Get-CltExclusionSource -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups)
    $counts = [ordered]@{}
    foreach ($source in $sources) { $counts[$source.Name] = 0 }
    $unlicensed = 0

    $kept = foreach ($user in $users) {
        if (-not $user) { continue }
        # Some old accounts have no userType; Microsoft Entra treats them as members.
        $type = if ($user.userType) { "$($user.userType)" } else { 'Member' }
        if ($type -ne $UserType) { continue }
        if (-not $IncludeDisabled -and $user.accountEnabled -eq $false) { continue }
        # Microsoft Entra Connect creates this account; it never has HR attributes.
        if ("$($user.userPrincipalName)" -like 'Sync_*' -or $user.displayName -eq 'On-Premises Directory Synchronization Service Account') { continue }
        if ($onlyLicensed -and @($user.assignedLicenses).Count -eq 0) { $unlicensed++; continue }
        $leftOut = $false
        foreach ($source in $sources) {
            if ($source.Set.Contains([string]$user.id) -or $source.Set.Contains([string]$user.userPrincipalName)) {
                $counts[$source.Name]++
                $leftOut = $true
                break
            }
        }
        if ($leftOut) { continue }
        $user
    }

    $parts = [System.Collections.Generic.List[string]]::new()
    if ($counts['emergency access']) { $parts.Add("$($counts['emergency access']) emergency access (EmergencyAccessAccounts)") }
    if ($counts['pack-wide']) { $parts.Add("$($counts['pack-wide']) by the pack-wide exclusions (CLT.UA.ExcludedUsers and CLT.UA.ExcludedGroups)") }
    if ($counts['this test']) { $parts.Add("$($counts['this test']) by this test's ExcludedUsers and ExcludedGroups") }
    if ($onlyLicensed -and $unlicensed) { $parts.Add("$unlicensed unlicensed, skipped because only licensed users are checked (CLT.UA.OnlyLicensedUsers)") }
    $lines = [System.Collections.Generic.List[string]]::new()
    $total = ($counts.Values | Measure-Object -Sum).Sum + $unlicensed
    if ($total) {
        $noun = if ($total -eq 1) { 'user' } else { 'users' }
        $lines.Add("Left out $total ${noun}:")
        $lines.Add('')
        foreach ($part in $parts) { $lines.Add("- $part") }
    } elseif ($onlyLicensed) {
        $lines.Add('Only licensed users were checked (CLT.UA.OnlyLicensedUsers); no unlicensed users were skipped.')
    }
    $note = if ($lines.Count) { "`n`n" + ($lines -join "`n") } else { '' }

    return [pscustomobject]@{ Users = @($kept); Note = $note }
}

function Add-CltResult {
    <#
    .SYNOPSIS
    Writes a test's result with Add-MtTestResultDetail, followed by the note from Get-CltUser about who was left out.
    #>
    [CmdletBinding()]
    param(
        # The result text, in Markdown.
        [string] $Result,

        # The note from Get-CltUser, or empty.
        [string] $Note,

        # Report the result as Investigate.
        [switch] $Investigate,

        # Users to list where the result has %TestResult%.
        [object[]] $GraphObjects
    )

    if ($GraphObjects) {
        Add-MtTestResultDetail -Result ($Result + $Note) -Investigate:$Investigate -GraphObjects $GraphObjects -GraphObjectType Users
    } else {
        Add-MtTestResultDetail -Result ($Result + $Note) -Investigate:$Investigate
    }
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
    if ($UserType -eq 'Member' -and (Test-CltSettingTrue -Name 'CLT.UA.OnlyLicensedUsers' -Default $false)) { $type = "licensed $type" }
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
        [int] $MaxRows = 100,

        # The note from Get-CltUser about who was left out, added to the end of the result.
        [string] $Note
    )

    if ($Users.Count -eq 0) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason "There are no $Population to check after exclusions."
    }

    $missing = [System.Collections.Generic.List[object]]::new()
    foreach ($user in $Users) {
        if (Test-CltIsBlank $user.$Property) { $missing.Add($user) }
    }

    if ($missing.Count -eq 0) {
        Add-CltResult -Note $Note -Result "Well done. All $($Users.Count) $Population have $Label."
        return $true
    }

    $listed = if ($MaxRows -gt 0) { @($missing | Select-Object -First $MaxRows) } else { $missing.ToArray() }
    # Name and user principal name, because display names are often shared.
    $objects = foreach ($user in $listed) {
        $name = if ($user.displayName) { "$($user.displayName) ($($user.userPrincipalName))" } else { "$($user.userPrincipalName)" }
        [pscustomobject]@{ id = $user.id; displayName = $name; userPrincipalName = $user.userPrincipalName }
    }

    $result = "$($missing.Count) of $($Users.Count) $Population do not have $Label.`n`n%TestResult%"
    if ($missing.Count -gt $listed.Count) {
        $result += "`n" + (Get-CltMoreRowsNote -Shown $listed.Count -Total $missing.Count)
    }
    Add-CltResult -Note $Note -Result $result -GraphObjects @($objects)
    return $false
}

function Get-CltObjectValue {
    <#
    .SYNOPSIS
    Returns a property of an object or dictionary from JSON, matching the name without regard to case, or $null.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        # A PSCustomObject or a dictionary.
        $InputObject,

        # The property name.
        [string] $Name
    )

    if ($null -eq $InputObject) { return $null }
    if ($InputObject -is [System.Collections.IDictionary]) {
        foreach ($key in $InputObject.Keys) { if ("$key" -ieq $Name) { return $InputObject[$key] } }
        return $null
    }
    $property = $InputObject.PSObject.Properties | Where-Object { $_.Name -ieq $Name } | Select-Object -First 1
    if ($property) { return $property.Value }
    return $null
}

function ConvertTo-CltStringList {
    <#
    .SYNOPSIS
    Flattens a value from JSON (a string, a list, or a list of single-property objects) into non-blank strings.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        # The value to flatten.
        $Value,

        # For a list of objects (as in the 2.x validation.json), the property to read from each, such as title.
        [string] $ItemProperty
    )

    $list = foreach ($item in @($Value)) {
        if ($null -eq $item) { continue }
        if ($item -is [string]) { $item; continue }
        if ($ItemProperty) { foreach ($inner in @(Get-CltObjectValue -InputObject $item -Name $ItemProperty)) { if ($null -ne $inner) { [string]$inner } } }
    }
    return @($list | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function ConvertTo-CltAllowedLocation {
    <#
    .SYNOPSIS
    Turns an approved location from JSON into a hashtable keyed by Graph property name (zipCode becomes postalCode).
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        # One location object from CLT.UA.AllowedValues.locations or validation.json validLocations.
        $Location
    )

    $fields = 'streetAddress', 'city', 'state', 'postalCode', 'country', 'companyName', 'businessPhones', 'officeLocation'
    $result = @{ name = [string](Get-CltObjectValue -InputObject $Location -Name 'name') }
    foreach ($field in $fields) {
        $value = Get-CltObjectValue -InputObject $Location -Name $field
        if ($null -eq $value -and $field -eq 'postalCode') { $value = Get-CltObjectValue -InputObject $Location -Name 'zipCode' }
        $values = @(ConvertTo-CltStringList -Value $value)
        if ($values.Count) { $result[$field] = $values }
    }
    return $result
}

function Read-CltAllowedValueFile {
    <#
    .SYNOPSIS
    Reads the file named by GlobalSettings."CLT.UA.AllowedValuesFile", or returns $null when none is set.

    .DESCRIPTION
    A relative path is resolved from the folder the run started in. The file can use the shape of
    CLT.UA.AllowedValues (department, jobTitle, ..., locations) or the 2.x validation.json shape (validTitles,
    validDepartments, validLocations with zipCode).
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param()

    $path = [string](Get-CltSetting -Name 'CLT.UA.AllowedValuesFile' -Default '')
    if ([string]::IsNullOrWhiteSpace($path)) { return $null }
    $full = if ([System.IO.Path]::IsPathRooted($path)) { $path } else { Join-Path -Path (Get-Location).Path -ChildPath $path }
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        throw "CLT.UA.AllowedValuesFile: '$path' was not found (looked for $full). Use an absolute path, or start the run from the folder that holds the file."
    }
    try {
        return (Get-Content -LiteralPath $full -Raw | ConvertFrom-Json -Depth 10)
    } catch {
        throw "CLT.UA.AllowedValuesFile: '$full' is not valid JSON: $($_.Exception.Message)"
    }
}

function Get-CltAllowedValueSet {
    <#
    .SYNOPSIS
    Returns the pack-wide approved values: lists by Graph property name and approved locations, from
    GlobalSettings."CLT.UA.AllowedValues" and the file in GlobalSettings."CLT.UA.AllowedValuesFile" together.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $keys = 'department', 'jobTitle', 'companyName', 'streetAddress', 'city', 'state', 'postalCode', 'country', 'businessPhones', 'officeLocation'
    $lists = @{}
    foreach ($key in $keys) { $lists[$key] = [System.Collections.Generic.List[string]]::new() }
    $locations = [System.Collections.Generic.List[hashtable]]::new()
    $sources = [System.Collections.Generic.List[string]]::new()

    $config = Get-CltSetting -Name 'CLT.UA.AllowedValues' -Default $null
    $file = Read-CltAllowedValueFile
    foreach ($origin in @(
            [pscustomobject]@{ Name = 'CLT.UA.AllowedValues'; Data = $config }
            [pscustomobject]@{ Name = 'CLT.UA.AllowedValuesFile'; Data = $file })) {
        if ($null -eq $origin.Data) { continue }
        $sources.Add($origin.Name)
        foreach ($key in $keys) {
            foreach ($value in (ConvertTo-CltStringList -Value (Get-CltObjectValue -InputObject $origin.Data -Name $key))) { $lists[$key].Add($value) }
        }
        # The 2.x validation.json names.
        foreach ($value in (ConvertTo-CltStringList -Value (Get-CltObjectValue -InputObject $origin.Data -Name 'validTitles') -ItemProperty 'title')) { $lists['jobTitle'].Add($value) }
        foreach ($value in (ConvertTo-CltStringList -Value (Get-CltObjectValue -InputObject $origin.Data -Name 'validDepartments') -ItemProperty 'department')) { $lists['department'].Add($value) }
        $rawLocations = @(Get-CltObjectValue -InputObject $origin.Data -Name 'locations') + @(Get-CltObjectValue -InputObject $origin.Data -Name 'validLocations')
        foreach ($raw in $rawLocations) {
            if ($null -eq $raw -or $raw -is [string]) { continue }
            $location = ConvertTo-CltAllowedLocation -Location $raw
            $locations.Add($location)
            # A location's values are approved values of each attribute too.
            foreach ($field in $location.Keys) { if ($field -ne 'name' -and $lists.ContainsKey($field)) { foreach ($v in $location[$field]) { $lists[$field].Add($v) } } }
        }
    }

    return [pscustomobject]@{ Lists = $lists; Locations = $locations.ToArray(); Source = ($sources -join ' and ') }
}

function ConvertTo-CltValueRow {
    <#
    .SYNOPSIS
    Turns one value and the users that have it into a table row: the value, how many users, and up to three of them.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        # A dictionary entry: Key is the value, Value the list of users.
        $Entry,

        # The heading of the value column, such as Department.
        [string] $Column
    )

    $row = [ordered]@{}
    $row[$Column] = "``$($Entry.Key)``"
    $row['Users'] = $Entry.Value.Count
    $row['Examples'] = (@($Entry.Value | Select-Object -First 3 | ForEach-Object { $_.userPrincipalName }) -join ', ')
    return [pscustomobject]$row
}

function Invoke-CltAllowedValueCheck {
    <#
    .SYNOPSIS
    Checks that every value of Property on the users is an approved value, and returns $true when it is.

    .DESCRIPTION
    Shared by the approved-value tests. The approved values come from the test's AllowedValues when it has any,
    else from GlobalSettings."CLT.UA.AllowedValues" and "CLT.UA.AllowedValuesFile" together (including the values
    of approved locations). Blank values are not checked: the presence tests check those. Without any approved
    values, the test reports Investigate with the values it found, so they can be copied into the config.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # The result of Get-CltUser.
        $Set,

        # The user property, such as department.
        [string] $Property,

        # How the attribute is named in results, such as "department".
        [string] $Label,

        # The heading of the value column, such as Department.
        [string] $Column,

        # How the checked users are named in results, such as "enabled member users".
        [string] $Population,

        # The test's own approved values; when set, the pack-wide values are not used.
        [string[]] $AllowedValues,

        # Treat values that differ only in letter case as different.
        [bool] $CaseSensitive = $true,

        # Most rows to list in the result; 0 lists them all.
        [int] $MaxRows = 100
    )

    $users = @($Set.Users | Where-Object { -not (Test-CltIsBlank $_.$Property) })
    if ($users.Count -eq 0) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason "None of the $Population has a $Label set."
    }

    $comparer = if ($CaseSensitive) { [System.StringComparer]::Ordinal } else { [System.StringComparer]::OrdinalIgnoreCase }
    $groups = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[object]]]::new($comparer)
    foreach ($user in $users) {
        foreach ($value in @($user.$Property)) {
            if (Test-CltIsBlank $value) { continue }
            $text = [string]$value
            if (-not $groups.ContainsKey($text)) { $groups[$text] = [System.Collections.Generic.List[object]]::new() }
            if (-not $groups[$text].Contains($user)) { $groups[$text].Add($user) }
        }
    }

    $own = @($AllowedValues | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($own.Count) {
        $allowedList = $own
        $source = "this test's AllowedValues"
    } else {
        $shared = Get-CltAllowedValueSet
        $allowedList = @($shared.Lists[$Property])
        $source = $shared.Source
    }
    $allowed = [System.Collections.Generic.HashSet[string]]::new($comparer)
    foreach ($value in $allowedList) { [void]$allowed.Add($value) }

    if ($allowed.Count -eq 0) {
        $rows = @($groups.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending | ForEach-Object { ConvertTo-CltValueRow -Entry $_ -Column $Column })
        $table = Format-CltTable -Rows $rows -Columns $Column, 'Users', 'Examples' -MaxRows $MaxRows
        Add-CltResult -Note $Set.Note -Investigate -Result ("No approved ${Label} values are set, so the $($groups.Count) values used by $($users.Count) $Population are listed for review. " +
            "Add the correct ones to **CLT.UA.AllowedValues** → **$Property** under GlobalSettings in maester-config.json (or to this test's **AllowedValues**) so this test can enforce them.`n`n$table")
        return $true
    }

    $rejected = @($groups.GetEnumerator() | Where-Object { -not $allowed.Contains($_.Key) })
    if ($rejected.Count -eq 0) {
        Add-CltResult -Note $Set.Note -Result "Well done. All $($users.Count) $Population with a $Label use one of the $($allowed.Count) approved values (from $source)."
        return $true
    }

    $affected = [System.Collections.Generic.HashSet[object]]::new()
    foreach ($entry in $rejected) { foreach ($user in $entry.Value) { [void]$affected.Add($user) } }
    $rows = @($rejected | Sort-Object { $_.Value.Count } -Descending | ForEach-Object { ConvertTo-CltValueRow -Entry $_ -Column $Column })
    $table = Format-CltTable -Rows $rows -Columns $Column, 'Users', 'Examples' -MaxRows $MaxRows
    Add-CltResult -Note $Set.Note -Result ("$($affected.Count) of $($users.Count) $Population have a $Label that is not one of the $($allowed.Count) approved values (from $source). " +
        "$($rejected.Count) value(s) are not approved:`n`n$table")
    return $false
}

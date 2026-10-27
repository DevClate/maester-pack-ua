function Test-CltPhoneFormat {
    <#
    .SYNOPSIS
    Checks that user phone numbers that are set use international E.164 format, such as +14255550100.

    .DESCRIPTION
    Only numbers that are set are checked; blank phones are not a failure. By default a trailing extension
    (;ext=123, x123 or ext. 123) is allowed and spaces are not. PhonePattern replaces the whole rule.

    .EXAMPLE
    Invoke-MtTest -Path ./tests/Test.MP.CLT.UA.1011.ps1 -Parameter @{ AllowSpaces = $true }
    #>
    [MaesterTest(
        Id           = 'MP.CLT.UA.1011',
        Title        = 'User phone numbers use international E.164 format.',
        Product      = 'entra',
        Feature      = 'identity-governance',
        Area         = 'identity-lifecycle',
        ResourceType = 'User',
        Severity     = 'Low',
        UserImpact   = 'Low',
        ImplementationCost = 'Low',
        Service      = 'Graph',
        Permission   = ('User.Read.All', 'GroupMember.Read.All'),
        Tag          = ('UserAttributes', 'Format', 'Phone'),
        Author       = 'DevClate'
    )]
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        # Phone attributes to check.
        [ValidateSet('businessPhones', 'mobilePhone', 'faxNumber')]
        [string[]] $Attributes = ('businessPhones', 'mobilePhone'),

        # Regular expression a number must match after any allowed extension and spaces are removed.
        [string] $PhonePattern = '^\+[1-9]\d{6,14}$',

        # Allow a trailing extension such as ;ext=123, x123 or ext. 123.
        [bool] $AllowExtension = $true,

        # Allow spaces inside the number, such as +1 425 555 0100.
        [bool] $AllowSpaces = $false,

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

    try {
        $rule = [regex]::new($PhonePattern)
    } catch {
        throw "PhonePattern for MP.CLT.UA.1011 is not a valid regular expression: $PhonePattern"
    }
    $extension = [regex]::new('(\s*;\s*ext=\d+|\s*(x|ext\.?)\s*\d+)$', 'IgnoreCase')

    $population = Get-CltPopulation -IncludeDisabled $IncludeDisabled
    $set = Get-CltUser -Property $Attributes -IncludeDisabled $IncludeDisabled -ExcludedUsers $ExcludedUsers -ExcludedGroups $ExcludedGroups
    $users = $set.Users

    $checkedNumbers = 0
    $rows = [System.Collections.Generic.List[object]]::new()
    foreach ($user in $users) {
        foreach ($attribute in $Attributes) {
            foreach ($number in @($user.$attribute)) {
                if (Test-CltIsBlank $number) { continue }
                $checkedNumbers++
                $candidate = "$number".Trim()
                if ($AllowExtension) { $candidate = $extension.Replace($candidate, '') }
                if ($AllowSpaces) { $candidate = $candidate -replace ' ', '' }
                if (-not $rule.IsMatch($candidate)) {
                    $rows.Add([pscustomobject]@{
                        'User'      = "$($user.displayName) ($($user.userPrincipalName))"
                        'Attribute' = $attribute
                        'Value'     = "``$number``"
                    })
                }
            }
        }
    }

    if ($checkedNumbers -eq 0) {
        Add-MtTestResultDetail -SkippedBecause Custom -SkippedCustomReason "None of the $population has a phone number in $($Attributes -join ', ')."
    }
    if ($rows.Count -eq 0) {
        Add-CltResult -Note $set.Note -Result "Well done. All $checkedNumbers phone numbers set on $population match the required format."
        return $true
    }

    $table = Format-CltTable -Rows $rows.ToArray() -Columns 'User', 'Attribute', 'Value' -MaxRows $MaxRows
    Add-CltResult -Note $set.Note -Result ("$($rows.Count) of $checkedNumbers phone numbers do not match the required format (``$PhonePattern``). " +
        "Write them as + country code and number with no punctuation, for example ``+14255550100``.`n`n$table")
    return $false
}

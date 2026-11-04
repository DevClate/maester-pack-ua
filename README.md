![User Attributes, a Maester pack by DevClate](assets/banner.png)

# User Attributes for Maester

A [Maester Pack](https://maester.dev/docs/packs/) that checks that Microsoft Entra users have the attributes your HR processes, dynamic groups and licensing depend on, and that those values are formatted consistently.

> **Requirements:** PowerShell 7.4 or later and the Maester 3.x prerelease (`Install-PSResource -Name Maester -Prerelease`). Pack support is not yet available in a stable release; see the [pack documentation](https://maester.dev/docs/packs/).
>
> **Trust:** Maester reviews a pack before installation and pins the approved files, but it does not sandbox PowerShell. This pack's Graph permissions are read-only; its code still runs in your Maester session with access to your local environment. Review the install summary and the pack's declared access in [maester-pack.json](maester-pack.json) before approving it.

## Quick start

```powershell
Install-PSResource -Name Maester -Prerelease -TrustRepository -Scope CurrentUser
Import-Module Maester -MinimumVersion 3.0.0 -MaximumVersion 3.99.99 -Force
Install-MtPack DevClate/maester-pack-ua
Connect-MgGraph -Scopes ((Get-MtGraphScope) + 'User-LifeCycleInfo.Read.All')
Invoke-Maester -Pack CLT.UA -SkipBuiltIn
```

`Install-MtPack` installs the newest release, or `main` while this repository has no release. The extra `User-LifeCycleInfo.Read.All` scope lets MP.CLT.UA.1006 read hire dates; without it, that test reports **Investigate**. To run only this pack use `-Pack CLT.UA -SkipBuiltIn`; `-Pack CLT.UA` also runs Maester's built-in tests.

## Tests

### Attributes are set

| ID | Title | Severity |
| --- | --- | --- |
| MP.CLT.UA.1001 | All member users have a usage location. | High |
| MP.CLT.UA.1002 | All member users have a manager. | Medium |
| MP.CLT.UA.1003 | All member users have a job title. | Low |
| MP.CLT.UA.1004 | All member users have a department. | Low |
| MP.CLT.UA.1005 | All member users have an employee ID. | Medium |
| MP.CLT.UA.1006 | All member users have an employee hire date. | Medium |
| MP.CLT.UA.1007 | All member users have a company name. | Low |
| MP.CLT.UA.1008 | All member users have a complete office address. | Low |
| MP.CLT.UA.1009 | All guest users have a sponsor. | Medium |
| MP.CLT.UA.1014 | All member users have a business phone. | Low |
| MP.CLT.UA.1015 | All member users have a mobile phone. | Low |
| MP.CLT.UA.1016 | All member users have a fax number. | Info |
| MP.CLT.UA.1017 | All member users have an office location. | Low |

MP.CLT.UA.1014–1017 check fields that many organisations deliberately leave blank (fax especially), so they carry the tag `Optional`. Leave them all out with `-ExcludeTag Optional`, or turn one off in `maester-config.json`, for example `{ "Id": "MP.CLT.UA.1016", "Enabled": false, "Reason": "Fax not used" }`.

### Attributes are formatted correctly

| ID | Title | Severity |
| --- | --- | --- |
| MP.CLT.UA.1010 | Every employee ID belongs to only one user. | Medium |
| MP.CLT.UA.1011 | User phone numbers use international E.164 format. | Low |
| MP.CLT.UA.1012 | User name, job and location attributes have no stray spaces. | Low |
| MP.CLT.UA.1013 | User country values use an approved spelling. | Low |

### Attributes use approved values

| ID | Title | Severity |
| --- | --- | --- |
| MP.CLT.UA.1018 | User departments are on the approved list. | Low |
| MP.CLT.UA.1019 | User job titles are on the approved list. | Low |
| MP.CLT.UA.1020 | User company names are on the approved list. | Low |
| MP.CLT.UA.1021 | User street addresses are on the approved list. | Low |
| MP.CLT.UA.1022 | User cities are on the approved list. | Low |
| MP.CLT.UA.1023 | User states or provinces are on the approved list. | Low |
| MP.CLT.UA.1024 | User postal codes are on the approved list. | Low |
| MP.CLT.UA.1025 | User business phone numbers are on the approved list. | Low |
| MP.CLT.UA.1026 | User addresses match an approved office location. | Low |

MP.CLT.UA.1013 (country spelling) reads the same approved values. Until you set approved values, these tests report **Investigate** and list the values they find, so your first run gives you the list to start from. See [Approved values](#approved-values).

## Choosing which tests run

| To | Use |
| --- | --- |
| Leave out business phone, mobile, fax and office location (MP.CLT.UA.1014–1017) | `Invoke-Maester -Pack CLT.UA -SkipBuiltIn -ExcludeTag Optional` |
| Run only the formatting tests | `Invoke-Maester -Pack CLT.UA -SkipBuiltIn -Tag Format` |
| Turn a test off for good | `{ "Id": "MP.CLT.UA.1007", "Enabled": false, "Reason": "Single company" }` in `TestSettings` |

Tags used by this pack: `UserAttributes` (all), `Presence`, `Format`, `Optional`, `Governance`, `Licensing`, `Guests`, `Address`, `Phone`, `Fax`, `LifecycleWorkflows`.

## Permissions

The connection Maester uses needs these Microsoft Graph permissions (all read-only):

| Permission | Used for |
| --- | --- |
| `User.Read.All` | Reading users, managers and sponsors |
| `GroupMember.Read.All` | `ExcludedGroups` on every test |
| `User-LifeCycleInfo.Read.All` | `employeeHireDate` (MP.CLT.UA.1006). Without it Graph returns no hire dates, and that test reports **Investigate**. |

`Connect-Maester` already asks for `Directory.Read.All`, which covers the first two. It does not ask for `User-LifeCycleInfo.Read.All`: to include it, connect with `Connect-MgGraph -Scopes ((Get-MtGraphScope) + 'User-LifeCycleInfo.Read.All')`.

## Which users are checked

By default every test checks **enabled member users** (MP.CLT.UA.1009 checks enabled guests, and MP.CLT.UA.1010 also checks disabled accounts). The Microsoft Entra Connect sync account is always left out.

### Leaving users out

Users are left out at three levels, and the levels add up: a test's own list never replaces the others.

| Level | Set in `maester-config.json` | Applies to |
| --- | --- | --- |
| Emergency access accounts | `GlobalSettings.EmergencyAccessAccounts` (Maester's own setting, users or groups) | Every test in this pack, and Maester's Conditional Access tests |
| Pack-wide | `GlobalSettings` → `"CLT.UA.ExcludedUsers"` and `"CLT.UA.ExcludedGroups"` | Every test in this pack |
| This test | `TestSettings` → `ExcludedUsers` and `ExcludedGroups` | Only that test |

Users are user principal names or object IDs. Groups are object IDs (the pack-wide `CLT.UA.ExcludedGroups` also accepts a group's mail address), and their nested members are left out too. Each result ends with a line such as *Left out 14 users: 2 emergency access, 9 by the pack-wide exclusions, 3 by this test's ExcludedUsers and ExcludedGroups*, so you can see why someone isn't listed.

```json
{
  "GlobalSettings": {
    "EmergencyAccessAccounts": [ { "UserPrincipalName": "breakglass1@contoso.com", "Type": "User" } ],
    "CLT.UA.ExcludedUsers": ["svc-scanner@contoso.com"],
    "CLT.UA.ExcludedGroups": ["<object id of a Service Accounts group>"]
  },
  "TestSettings": [
    { "Id": "MP.CLT.UA.1005", "Parameters": { "ExcludedGroups": ["<object id of a Contractors group>"] } }
  ]
}
```

### Pack settings

| `GlobalSettings` key | Default | What it does |
| --- | --- | --- |
| `CLT.UA.ExcludedUsers` | none | Users to leave out of every test. |
| `CLT.UA.ExcludedGroups` | none | Groups whose members are left out of every test. |
| `CLT.UA.ExcludeEmergencyAccessAccounts` | `true` | Leave out Maester's `EmergencyAccessAccounts`. Set `false` to check them like any other user. |
| `CLT.UA.AllowedValues` | none | Approved values for MP.CLT.UA.1013 and 1018–1026: lists by attribute, and office `locations`. See [Approved values](#approved-values). |
| `CLT.UA.AllowedValuesFile` | none | Path to a JSON file with more approved values, in the same shape or the 2.x `validation.json` shape. A relative path starts from the folder the run starts in. |
| `CLT.UA.OnlyLicensedUsers` | `false` | Check only member users with a licence, which leaves out most service, room and leftover accounts. Guests are not affected. |

## Approved values

The approved-value tests (MP.CLT.UA.1018–1026, and MP.CLT.UA.1013 for countries) compare each user's value with a list you approve. Blank values are not checked by these tests; the presence tests check those. There are three ways to give the lists, and you can mix them:

The checked-in [example configuration](maester-config.example.json) is validated against [the configuration JSON Schema](schemas/maester-config.schema.json) in CI. Start with that file when building your tenant configuration. Validate your own config without a tenant:

```powershell
Test-Json -Json (Get-Content ./maester-config.json -Raw) -SchemaFile ./schemas/maester-config.schema.json
```

| Where | Good for |
| --- | --- |
| **`CLT.UA.AllowedValues` in `GlobalSettings`** (recommended) | One place for every list and your office locations. It travels with `maester-config.json`, and an MSP can put each tenant's lists in `maester-config.<TenantId>.json`, which Maester merges in. |
| **`CLT.UA.AllowedValuesFile`** | Keeping the lists in their own file, for example one HR exports, or a 2.x `validation.json`. Its values add to `CLT.UA.AllowedValues`. |
| **A test's own `AllowedValues`** (or `AllowedCountries` on 1013) | A one-off list for one test. It replaces the shared values for that test only. |

```json
{
  "GlobalSettings": {
    "CLT.UA.AllowedValues": {
      "department": ["IT", "Finance", "Human Resources"],
      "jobTitle": ["Chief Executive Officer", "IT Manager", "Accountant"],
      "country": ["United States", "Canada"],
      "locations": [
        { "name": "Seattle HQ", "streetAddress": "1 Microsoft Way", "city": "Redmond", "state": "WA",
          "postalCode": "98052", "country": "United States", "companyName": "Contoso Ltd",
          "businessPhones": "+14255550100" },
        { "name": "New York", "streetAddress": "500 Fifth Avenue", "city": "New York", "state": "NY",
          "postalCode": "10110", "country": "United States", "companyName": "Contoso Ltd" }
      ]
    },
    "CLT.UA.AllowedValuesFile": "./validation.json"
  },
  "TestSettings": [
    { "Id": "MP.CLT.UA.1019", "Parameters": { "AllowedValues": ["IT Manager", "Accountant"] } }
  ]
}
```

- **Keys** are the Graph property names: `department`, `jobTitle`, `companyName`, `streetAddress`, `city`, `state`, `postalCode`, `country`, `businessPhones`, `officeLocation`, plus `locations`. Each takes a list, or a single value.
- **Locations count as lists too.** The values in `locations` are approved values of each attribute, so the cities, postal codes and phone numbers of your offices don't need listing twice. MP.CLT.UA.1026 also checks that a user's fields belong to the **same** location. A field a location leaves out is not compared, and `name` is shown in results.
- **The 2.x `validation.json` works as it is.** Its `validTitles`, `validDepartments` and `validLocations` are read, and `zipCode` counts as `postalCode`. Point `CLT.UA.AllowedValuesFile` at it.
- **The file path** is read from the folder the run starts in, unless it is absolute. If the file is missing or not valid JSON, the tests that need it report an error that names the setting and the path.
- **Letter case matters** by default (`Finance` is not `finance`). Set a test's `CaseSensitive` to `false` to ignore case.

**First run:** with no approved values set, each test reports **Investigate** with a table of the values in use and how many users have each. Copy the correct ones into `CLT.UA.AllowedValues`, then run again to see what to fix.

### Test parameters

Every test takes these parameters:

| Parameter | What it does |
| --- | --- |
| `ExcludedUsers` | More users to leave out of this test, on top of the levels above. |
| `ExcludedGroups` | More groups (object IDs) whose members are left out of this test. Maester checks that each value is an object ID. |
| `IncludeDisabled` | Also check disabled accounts. |
| `MaxRows` | Most users or rows a result lists (default `100`). The result says how many were left out; set `0` to list them all. |

Test-specific parameters:

| Test | Parameter | Default |
| --- | --- | --- |
| MP.CLT.UA.1002 | `ExcludedJobTitles` | `CEO`, `Chief Executive Officer` |
| MP.CLT.UA.1008 | `Fields` | `streetAddress`, `city`, `state`, `postalCode`, `country` (can add `officeLocation`) |
| MP.CLT.UA.1010 | `IgnoreLeadingZeros` | `false` |
| MP.CLT.UA.1011 | `Attributes`, `PhonePattern`, `AllowExtension`, `AllowSpaces` | business and mobile phones, `^\+[1-9]\d{6,14}$`, `true`, `false` |
| MP.CLT.UA.1012 | `Attributes` | name, job and location attributes |
| MP.CLT.UA.1013 | `AllowedCountries`, `CaseSensitive` | none (uses `CLT.UA.AllowedValues` → `country`, else lists the values found), `true` |
| MP.CLT.UA.1018–1025 | `AllowedValues`, `CaseSensitive` | none (uses `CLT.UA.AllowedValues`), `true` |
| MP.CLT.UA.1026 | `Fields`, `CaseSensitive` | `streetAddress`, `city`, `state`, `postalCode`, `country`, `companyName` (can add `businessPhones`, `officeLocation`), `true` |

Set them in `maester-config.json`:

```json
{
  "TestSettings": [
    { "Id": "MP.CLT.UA.1008", "Parameters": { "Fields": ["city", "country", "officeLocation"] } },
    { "Id": "MP.CLT.UA.1016", "Parameters": { "MaxRows": 0 } },
    { "Id": "MP.CLT.UA.1011", "Parameters": { "AllowSpaces": true } },
    { "Id": "MP.CLT.UA.1013", "Parameters": { "AllowedCountries": ["United States", "Canada"] } },
    { "Id": "MP.CLT.UA.1007", "Enabled": false, "Reason": "Single company" }
  ]
}
```

## Developing

See **[TESTING.md](TESTING.md)** for the full guide: loading the pack-enabled Maester without touching the Maester repository, offline checks, connecting with the right scopes, running tests while you develop, installing locally for a full report, and seeding test users. The short version:

```powershell
Test-MtPack .              # the checks Install-MtPack runs, without installing
Connect-Maester
Invoke-MtTest -Path .      # run the pack from this folder
Invoke-MtTest -Path ./tests/Test.MP.CLT.UA.1011.ps1 -Parameter @{ AllowSpaces = $true }
Invoke-MtTest -Path ./tests/Test.MP.CLT.UA.1016.ps1 -Parameter @{ MaxRows = 0 }   # list every failing user
```

## Versions and releases

`Install-MtPack DevClate/maester-pack-ua` installs the newest GitHub release, or the `main` branch while the repository has no release. The repository includes the pack workflows: `check-pack.yml` checks every push and pull request with Maester 3.x, validates the example configuration, and checks version/changelog consistency. `bump-version.yml` and `release.yml` publish a release for each merged pull request once the repository variable `PACK_RELEASES` is `true`; the release workflow warns if the release is not immutable or the pack index does not show its status. Until releases are enabled, raise `Version` in `maester-pack.json` by hand. Every change is written under `## Unreleased` in [CHANGELOG.md](CHANGELOG.md). Report security problems as described in [SECURITY.md](SECURITY.md).

## History

The presence tests started as Maester 2.x Pester tests in [DevClate/Custom-Maester-Tests](https://github.com/DevClate/Custom-Maester-Tests/tree/main/tests/Entra/Attributes) (ENTRA.UA.1001–1017). In this pack they:

- run on the Maester 3.0 native test engine, with no Pester, connection checks or try/catch;
- share one query helper, so exclusions work the same way in every test;
- read managers and sponsors in one Graph request instead of one per user;
- skip disabled accounts by default and take exclusions as parameters instead of hard-coded names;
- merge the five address tests into one (MP.CLT.UA.1008).

| 2.x test | Pack test |
| --- | --- |
| ENTRA.UA.1001 Manager | MP.CLT.UA.1002 |
| ENTRA.UA.1002 Job title | MP.CLT.UA.1003 |
| ENTRA.UA.1003–1007 Street, city, state, postal code, country | MP.CLT.UA.1008 |
| ENTRA.UA.1008 Department | MP.CLT.UA.1004 |
| ENTRA.UA.1009 Office location | MP.CLT.UA.1017 |
| ENTRA.UA.1010 Company name | MP.CLT.UA.1007 |
| ENTRA.UA.1011 Mobile phone | MP.CLT.UA.1015 |
| ENTRA.UA.1012 Business phone | MP.CLT.UA.1014 |
| ENTRA.UA.1013 Fax number | MP.CLT.UA.1016 |
| ENTRA.UA.1014 Sponsor | MP.CLT.UA.1009 (guests only) |
| ENTRA.UA.1015 Employee hire date | MP.CLT.UA.1006 |
| ENTRA.UA.1016 Employee ID | MP.CLT.UA.1005 |
| ENTRA.UA.1017 Usage location | MP.CLT.UA.1001 |

The approved-value tests started as the [Validating tests](https://github.com/DevClate/Custom-Maester-Tests/tree/main/tests/Entra/Validating) (ENTRA.UV). In this pack they read their lists from `maester-config.json` or a file you name instead of a `validation.json` beside the tests, list each unapproved value once with how many users have it, ignore blank values (the presence tests check those), and read `zipCode` correctly as the postal code.

| 2.x test | Pack test |
| --- | --- |
| ENTRA.UV.1001 Company name | MP.CLT.UA.1020 |
| ENTRA.UV.1002 Street address | MP.CLT.UA.1021 |
| ENTRA.UV.1003 City | MP.CLT.UA.1022 |
| ENTRA.UV.1004 State | MP.CLT.UA.1023 |
| ENTRA.UV.1005 Postal code | MP.CLT.UA.1024 |
| ENTRA.UV.1006 Country | MP.CLT.UA.1013 |
| ENTRA.UV.1007 Business number | MP.CLT.UA.1025 |
| ENTRA.UV.1008 Title | MP.CLT.UA.1019 |
| ENTRA.UV.1009 Department | MP.CLT.UA.1018 |
| ENTRA.UV.1010.L01 and L02 Locations (with and without business phone) | MP.CLT.UA.1026 (`Fields` chooses whether to compare `businessPhones`) |

## License

MIT

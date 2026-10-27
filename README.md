![User Attributes, a Maester pack by DevClate](assets/banner.png)

# User Attributes for Maester

A [Maester Pack](https://maester.dev/docs/next/packs/) that checks that Microsoft Entra users have the attributes your HR processes, dynamic groups and licensing depend on, and that those values are formatted consistently.

> **Status:** Maester Packs are in the Maester preview build (`Install-PSResource Maester -Prerelease`) and documented at [maester.dev/docs/next/packs](https://maester.dev/docs/next/packs/). The format may still change before a stable release.

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

## Install

```powershell
Install-MtPack DevClate/maester-pack-ua
Connect-Maester
Invoke-Maester -Pack CLT.UA -SkipBuiltIn
```

To confirm the install, type the pack's code, `CLT.UA`. Installed packs only run when you name them: `-Pack CLT.UA -SkipBuiltIn` runs only this pack, and `-Pack CLT.UA` runs it alongside Maester's built-in tests.

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

Users are user principal names or object IDs; groups are object IDs or mail addresses, and their nested members are left out too. Each result ends with a line such as *Left out 14 users: 2 emergency access, 9 by the pack-wide exclusions, 3 by this test's ExcludedUsers and ExcludedGroups*, so you can see why someone isn't listed.

```json
{
  "GlobalSettings": {
    "EmergencyAccessAccounts": [ { "UserPrincipalName": "breakglass1@contoso.com", "Type": "User" } ],
    "CLT.UA.ExcludedUsers": ["svc-scanner@contoso.com"],
    "CLT.UA.ExcludedGroups": ["<object id of a Service Accounts group>"]
  },
  "TestSettings": [
    { "Id": "MP.CLT.UA.1005", "Parameters": { "ExcludedGroups": ["contractors@contoso.com"] } }
  ]
}
```

### Pack settings

| `GlobalSettings` key | Default | What it does |
| --- | --- | --- |
| `CLT.UA.ExcludedUsers` | none | Users to leave out of every test. |
| `CLT.UA.ExcludedGroups` | none | Groups whose members are left out of every test. |
| `CLT.UA.ExcludeEmergencyAccessAccounts` | `true` | Leave out Maester's `EmergencyAccessAccounts`. Set `false` to check them like any other user. |
| `CLT.UA.OnlyLicensedUsers` | `false` | Check only member users with a licence, which leaves out most service, room and leftover accounts. Guests are not affected. |

### Test parameters

Every test takes these parameters:

| Parameter | What it does |
| --- | --- |
| `ExcludedUsers` | More users to leave out of this test, on top of the levels above. |
| `ExcludedGroups` | More groups (object ID or mail) whose members are left out of this test. |
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
| MP.CLT.UA.1013 | `AllowedCountries`, `CaseSensitive` | none (lists the values found), `true` |

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

`Install-MtPack DevClate/maester-pack-ua` installs the newest GitHub release, or the `main` branch while the repository has no release. The repository includes the demo pack's workflows: `check-pack.yml` checks every push and pull request, and `bump-version.yml` and `release.yml` publish a release for each merged pull request once the repository variable `PACK_RELEASES` is `true`. Until then, raise `Version` in `maester-pack.json` by hand. Every change is written under `## Unreleased` in [CHANGELOG.md](CHANGELOG.md). Report security problems as described in [SECURITY.md](SECURITY.md).

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

## License

MIT

# Testing and running the User Attributes pack

How to get a Maester build with pack support, check this pack without a tenant, run it against a tenant while you develop, and run it the way users will after installing it.

> **Status (October 2026):** Pack support is merged into Maester's `main` branch and documented under [maester.dev/docs/next/packs](https://maester.dev/docs/next/packs/). Until it is in a stable release, use the Gallery preview build (step 3), a test tenant, and keep scheduled Maester runs on the stable build.

## Contents

1. [Will this touch the Maester repository?](#1-will-this-touch-the-maester-repository)
2. [What you need](#2-what-you-need)
3. [Get a Maester build with packs](#3-get-a-maester-build-with-packs)
4. [Put the pack in your own repository](#4-put-the-pack-in-your-own-repository)
5. [Check the pack without a tenant](#5-check-the-pack-without-a-tenant)
6. [Connect to a tenant](#6-connect-to-a-tenant)
7. [Run tests while you develop](#7-run-tests-while-you-develop)
8. [Run it the way users will (install and report)](#8-run-it-the-way-users-will-install-and-report)
9. [Optional: seed test users with known problems](#9-optional-seed-test-users-with-known-problems)
10. [Publishing](#10-publishing)
11. [Troubleshooting](#11-troubleshooting)

## 1. Will this touch the Maester repository?

No. You use two separate folders, and only one of them is yours:

| Folder | What it is | Points at | You change it? |
| --- | --- | --- | --- |
| `C:\Tools\maester-packs` | Only if you use the fallback in step 3: a read-only copy of Maester, used only to load the module | `maester365/maester` | No, only `git pull` |
| `C:\Code\maester-pack-ua` | This pack | `DevClate/maester-pack-ua` | Yes |

Cloning never creates a pull request. A pull request is only opened when someone pushes a branch and then explicitly creates one (`gh pr create`, the GitHub website, or a "Create pull request" button in VS Code or GitHub Desktop). You also have no write access to `maester365/maester`, so a push there fails. Even so, the fallback in step 3 turns off pushing from the Maester copy, so nothing can be sent from it by accident.

If you want to contribute a change to Maester itself, fork it on GitHub and work in your fork, not in this copy.

## 2. What you need

| Requirement | Check | Install |
| --- | --- | --- |
| PowerShell 7.4 or later | `$PSVersionTable.PSVersion` | `winget install Microsoft.PowerShell` |
| Git | `git --version` | `winget install Git.Git` |
| Microsoft Graph authentication module 2.27.0 or later | `Get-Module Microsoft.Graph.Authentication -ListAvailable` | `Install-Module Microsoft.Graph.Authentication -Scope CurrentUser` |
| A test tenant where you can consent to Graph read permissions | | |

Pester is not needed.

## 3. Get a Maester build with packs

Install the preview build from the PowerShell Gallery and check that it has the pack commands:

```powershell
Install-PSResource -Name Maester -Prerelease -TrustRepository -Scope CurrentUser
Import-Module Maester -Force
Get-Command New-MtPack, Test-MtPack, Install-MtPack | Select-Object Name
```

This is what the pack's CI does (`.github/workflows/check-pack.yml`). When a stable Maester release includes packs, drop `-Prerelease`.

### Fallback: a read-only copy of Maester's main branch

Use this only if `Get-Command` above cannot find `Test-MtPack`. Clone `main`, then turn off pushing:

```powershell
$MaesterSrc = 'C:\Tools\maester-packs'
git clone --branch main --single-branch https://github.com/maester365/maester.git $MaesterSrc
git -C $MaesterSrc remote set-url --push origin DISABLED
git -C $MaesterSrc remote -v      # the (push) line must show DISABLED
```

Load it in each new session (start a fresh `pwsh` window first if the Gallery Maester is already loaded), and pick up the maintainers' changes later with `git -C $MaesterSrc pull`:

```powershell
$MaesterSrc = 'C:\Tools\maester-packs'
Remove-Module Maester -ErrorAction SilentlyContinue
Import-Module "$MaesterSrc\powershell\Maester.psd1" -Force
(Get-Module Maester).Path              # must be under C:\Tools\maester-packs
```

**Without Git:** download `https://github.com/maester365/maester/archive/refs/heads/main.zip`, extract it, then unblock the files so PowerShell will load them: `Get-ChildItem C:\Tools\maester-packs -Recurse | Unblock-File`.

## 4. Put the pack in your own repository

Extract `maester-pack-ua.zip` to `C:\Code\maester-pack-ua`, then create your repository from it:

```powershell
Set-Location C:\Code\maester-pack-ua
git init -b main
git add .
git commit -m 'User Attributes pack 0.4.0'
gh repo create DevClate/maester-pack-ua --public --source . --push
git remote -v                          # origin must be DevClate/maester-pack-ua
```

The pack's `.gitignore` keeps files such as `.DS_Store` out of the repository. Keep it: a binary file in the pack makes `Test-MtPack` rate it **High** risk (`Unscannable`), and the CI fails on High risk.

Keep the repository owner as `DevClate`: the manifest's `Publisher` is `devclate`, and Maester refuses a pack whose publisher is not the repository owner.

Keep **`Invoke-PackLogicTests.ps1` outside this folder**, for example in `C:\Code\maester-pack-dev`. Maester scans every script in a pack, and that script builds code at run time, which raises the pack's risk from Low to Medium.

## 5. Check the pack without a tenant

These checks need no connection. Run them after every change.

```powershell
Set-Location C:\Code\maester-pack-ua

# 1. Every check Install-MtPack runs, without installing
Test-MtPack .
#    Expect: IsValid True, Risk Low, no Errors or Findings, 17 TestIds

# 2. Each test's metadata ([MaesterTest] attribute, parameters, file names)
Get-MtTest -Path .\tests | Sort-Object Id | Format-Table Id, IsValid, Severity, Errors -AutoSize
#    Expect: 17 rows, all IsValid True

# 3. Each test's logic, against made-up users, with Graph replaced by fixtures
pwsh -NoProfile -File C:\Code\maester-pack-dev\Invoke-PackLogicTests.ps1 -PackPath C:\Code\maester-pack-ua
#    Expect: 33 "ok" lines and "0 failure(s)"
```

The logic tests check pass, fail, Investigate and Skipped results, exclusions, disabled accounts and each test-specific parameter. When you add a test, add a few `Assert-Case` lines for it at the bottom of that script.

## 6. Connect to a tenant

`Connect-Maester` asks for Maester's standard read-only scopes. They include `Directory.Read.All`, which covers users, managers, sponsors and group members. They do **not** include `User-LifeCycleInfo.Read.All`, which MP.CLT.UA.1006 needs to read hire dates. Without it, that test reports **Investigate** instead of results.

Connect with Maester's scopes plus that one:

```powershell
Connect-MgGraph -Scopes ((Get-MtGraphScope) + 'User-LifeCycleInfo.Read.All') -NoWelcome
Get-MgContext | Select-Object Account, TenantId, @{ n = 'HasLifecycle'; e = { $_.Scopes -contains 'User-LifeCycleInfo.Read.All' } }
```

Or use `Connect-Maester` and accept that MP.CLT.UA.1006 will ask you to investigate.

For an app registration (pipelines), grant these **application** permissions and admin consent: `User.Read.All`, `GroupMember.Read.All`, `User-LifeCycleInfo.Read.All`, plus whatever the rest of your Maester run needs.

## 7. Run tests while you develop

`Invoke-MtTest -Path` runs the pack straight from its folder, with its helpers, and reloads it on every call. Edit a file, save, and run again.

```powershell
Set-Location C:\Code\maester-pack-ua

# The whole pack
Invoke-MtTest -Path . | Sort-Object Id | Format-Table Id, Result, ReasonCode -AutoSize

# One test, and the Markdown it writes to the report
$r = Invoke-MtTest -Path .\tests\Test.MP.CLT.UA.1011.ps1
$r | Format-List Id, Result, ReasonCode, ReasonDetail
$r.ResultDetail.TestResult

# One test with parameters (only allowed when exactly one test is selected)
Invoke-MtTest -Path .\tests\Test.MP.CLT.UA.1011.ps1 -Parameter @{ AllowSpaces = $true }
Invoke-MtTest -Path .\tests\Test.MP.CLT.UA.1013.ps1 -Parameter @{ AllowedCountries = 'United States', 'Canada' }
Invoke-MtTest -Path .\tests\Test.MP.CLT.UA.1001.ps1 -Parameter @{ ExcludedUsers = 'breakglass@contoso.com' }
```

What to expect on a first run against a real tenant:

| Result | Meaning |
| --- | --- |
| Passed / Failed | The check ran. Failed rows list the users to fix. |
| Investigate on MP.CLT.UA.1006 | No user has a hire date: either none are set, or the connection lacks `User-LifeCycleInfo.Read.All` (step 6). |
| Investigate on MP.CLT.UA.1013 | Expected until you set `AllowedCountries`: it lists the country spellings it found. |
| Skipped | Nothing to check, for example no guests (MP.CLT.UA.1009) or no phone numbers set (MP.CLT.UA.1011). The reason says which. |
| Error | Read `ReasonDetail`. A 403 means a missing permission. |

Large tenants: the tests share one Graph request for users, which Maester caches for the session, so the directory is read once (plus one request each for managers, sponsors and hire dates). Expect the first test to take the longest.

Each failing result lists at most 100 users or rows, with a line saying how many were left out. To see them all, run the test with `-Parameter @{ MaxRows = 0 }`, or set `MaxRows` to `0` for it in `maester-config.json`:

```powershell
Invoke-MtTest -Path .\tests\Test.MP.CLT.UA.1016.ps1 -Parameter @{ MaxRows = 0 }
```

## 8. Run it the way users will (install and report)

Installing checks and copies the pack the way it will work for everyone else, and lets you use `Invoke-Maester` with its HTML report and `maester-config.json`. Use a separate run folder, not the pack's own folder:

```powershell
$Run = 'C:\Maester\pack-run'
New-Item -ItemType Directory -Path $Run -Force | Out-Null
Set-Location $Run
if (-not (Test-Path .\maester-config.json)) { '{}' | Set-Content .\maester-config.json }

Install-MtPack C:\Code\maester-pack-ua    # shows what the pack reaches and its risk; approve it
Get-MtPack | Format-Table Id, Version, Status, Reason -AutoSize    # Status should be Ready

Invoke-Maester -Pack CLT.UA -SkipBuiltIn -OutputFolder .\test-results
```

`Install-MtPack` writes a `Packs` entry to `maester-config.json` and creates `maester-packs.lock.json` beside it. It also stores a read-only copy of the pack under `~\.maester\packs`. A local folder has no 72-hour cooldown; that applies only to GitHub releases.

**The installed copy is a snapshot.** After you change the pack, run `Install-MtPack C:\Code\maester-pack-ua` again, or `Invoke-Maester` keeps running the old copy. For quick edits, use `Invoke-MtTest -Path` (step 7) instead.

Set per-tenant values in the run folder's `maester-config.json`:

```json
{
  "Packs": [ { "Id": "devclate.user-attributes", "Source": "C:\\Code\\maester-pack-ua", "Version": "0.4.0" } ],
  "TestSettings": [
    { "Id": "MP.CLT.UA.1001", "Parameters": { "ExcludedUsers": ["breakglass@contoso.com"] } },
    { "Id": "MP.CLT.UA.1013", "Parameters": { "AllowedCountries": ["United States", "Canada"] } },
    { "Id": "MP.CLT.UA.1016", "Parameters": { "MaxRows": 0 } },
    { "Id": "MP.CLT.UA.1015", "Enabled": false, "Reason": "No company mobiles" }
  ]
}
```

Keep the `Packs` entry that `Install-MtPack` wrote. To run Maester's built-in tests too, leave out `-TestId`. To remove the pack, run `Uninstall-MtPack devclate.user-attributes`.

## 9. Optional: seed test users with known problems

**Test tenant only.** This creates three enabled member users with deliberate problems, so you can see each format test fail for the right reason, then deletes them. It needs `User.ReadWrite.All`.

```powershell
Connect-MgGraph -Scopes 'User.ReadWrite.All' -NoWelcome
$domain = ((Invoke-MgGraphRequest GET 'v1.0/domains').value | Where-Object isDefault).id

function New-PackTestUser([string]$Nick, [hashtable]$Extra) {
    $body = @{
        accountEnabled    = $true
        displayName       = "Pack Test $Nick"
        mailNickname      = "packtest$Nick"
        userPrincipalName = "packtest$Nick@$domain"
        usageLocation     = 'US'
        passwordProfile   = @{ forceChangePasswordNextSignIn = $true; password = "Pt!$([guid]::NewGuid().ToString('N'))" }
    }
    foreach ($key in $Extra.Keys) { $body[$key] = $Extra[$key] }   # $Extra overrides the defaults
    Invoke-MgGraphRequest POST 'v1.0/users' -Body ($body | ConvertTo-Json -Depth 3)
}

$created = @(
    New-PackTestUser 'one'   @{ department = 'Finance '; jobTitle = 'Analyst'; employeeId = 'PT100'; country = 'USA'; businessPhones = @('(425) 555-0100') }
    New-PackTestUser 'two'   @{ employeeId = 'pt100'; country = 'United States'; mobilePhone = '+14255550101' }
    New-PackTestUser 'three' @{ displayName = 'Pack  Test Three'; department = 'Finance'; jobTitle = 'Analyst'; employeeId = 'PT300' }
)
$created | Select-Object id, userPrincipalName | ConvertTo-Json | Set-Content .\pack-test-users.json
```

Wait a minute for the users to appear, start a new PowerShell session (so Maester's cache is empty), reconnect as in step 6, and run the pack. These users should be listed in:

| Test | Why |
| --- | --- |
| MP.CLT.UA.1003, 1004 | `two` has no job title or department |
| MP.CLT.UA.1010 | `one` and `two` share employee ID `PT100` / `pt100` |
| MP.CLT.UA.1011 | `one` has `(425) 555-0100` |
| MP.CLT.UA.1012 | `one` has `Finance ` (trailing space); `three` has two spaces in its display name |
| MP.CLT.UA.1013 | `one` has `USA`, `two` has `United States` |

Clean up afterwards (deleted users stay in the recycle bin for 30 days unless you also remove them there):

```powershell
Connect-MgGraph -Scopes 'User.ReadWrite.All' -NoWelcome
foreach ($u in (Get-Content .\pack-test-users.json -Raw | ConvertFrom-Json)) {
    Invoke-MgGraphRequest DELETE "v1.0/users/$($u.id)"
    Invoke-MgGraphRequest DELETE "v1.0/directory/deletedItems/$($u.id)"
}
```

## 10. Publishing

1. Choose how versions ship (see **Versions and releases** in the README): track `main`, or turn on releases with `gh variable set PACK_RELEASES --body true -R DevClate/maester-pack-ua`.
2. Write each change under `## Unreleased` in `CHANGELOG.md`, and raise `Version` in `maester-pack.json` (the release workflows do this for you when releases are on).
3. Run the checks in step 5. The CI (`.github/workflows/check-pack.yml`) runs `Test-MtPack` and every test on each push and pull request.
4. Make releases **immutable** in the repository settings, so the install cooldown starts when a release is published rather than when each user first sees it.
5. Once there is a release, list the pack once at [packs.maester.cloud/publish](https://packs.maester.cloud/publish): choose **Yes, I have a pack repository**, sign in as a repository admin, **Check**, then **Publish**. This registers the pack's `Guid` and the code `CLT.UA` to DevClate. Later releases are picked up on their own. If it isn't listed within about ten minutes, read `https://packs.maester.cloud/status/DevClate/maester-pack-ua`.
6. Users install it with `Install-MtPack DevClate/maester-pack-ua`. Pipelines commit `maester-config.json` and `maester-packs.lock.json`, and run `Restore-MtPack` before `Invoke-Maester -Pack CLT.UA -NonInteractive`.

## 11. Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| `Test-MtPack` / `Install-MtPack` not found | A Maester build without packs is loaded | Install the preview build, or load the fallback copy (step 3) in a new `pwsh` window |
| `Test-MtPack` shows Risk High, `Unscannable` | A binary file such as `.DS_Store` is in the pack folder | Delete it; the `.gitignore` keeps it out of the repository |
| `Get-MtPack` says `requires Maester >=3.1` | An older copy of the manifest | Use pack 0.2.0 or later (it allows `>=3.0`), and run `Install-MtPack` again |
| `PackUnavailable`, or old results after an edit | The installed copy no longer matches, or is out of date | `Install-MtPack C:\Code\maester-pack-ua` again |
| `Test-MtPack` shows Risk Medium | A script with dynamic code is inside the pack folder | Move it out (for example the logic-test script) and check `Findings` |
| Every test `Skipped` / `ServiceNotConnected` | Not connected to Graph | Step 6 |
| `Invoke-Maester` says not connected, even with `-DryRun` | `Invoke-Maester` needs a Graph connection | Connect first, or use `Get-MtTest` and `Test-MtPack` offline |
| `Error` with 403 in `ReasonDetail` | Missing permission | Check the scopes in step 6 |
| MP.CLT.UA.1006 always Investigate | Missing `User-LifeCycleInfo.Read.All`, or no hire dates set | Step 6 |
| `-Parameter can be used only when exactly one test is selected` | `-Parameter` with a folder | Point `-Path` at one test file |
| Results don't change after editing a user | Maester caches Graph results in the session | Start a new session, or wait and run again |
| A result says "Showing the first 100 of …" | Results list at most `MaxRows` users or rows | Set `MaxRows` to `0` for that test (step 7) |

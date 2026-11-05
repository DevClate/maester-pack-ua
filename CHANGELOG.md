# Changelog

## 0.5.0

- **Nine approved-value tests**, converted from the ENTRA.UV Validating tests in DevClate/Custom-Maester-Tests: department (MP.CLT.UA.1018), job title (1019), company name (1020), street address (1021), city (1022), state or province (1023), postal code (1024) and business phone number (1025) are on the approved list, and each user's address matches an approved office location (1026, which replaces the two 2.x location tests; its `Fields` parameter chooses whether the business phone is compared).
- **Approved values in one place:** `GlobalSettings` → `"CLT.UA.AllowedValues"` holds lists by Graph property name and office `locations`. `"CLT.UA.AllowedValuesFile"` names a JSON file whose values add to them, in the same shape or the 2.x `validation.json` shape (`validTitles`, `validDepartments`, `validLocations`, with `zipCode` read as `postalCode`). A test's own `AllowedValues` replaces the shared values for that test.
- Without approved values, these tests report **Investigate** and list the values in use with how many users have each, ready to copy into the config. Unapproved values are listed once each, with the number of users and examples; MP.CLT.UA.1026 shows each user's closest approved location and the fields that differ.
- MP.CLT.UA.1013 uses `CLT.UA.AllowedValues` → `country` when its own `AllowedCountries` is empty.
- Qualify every test's permission metadata with `Graph:Scope:` so current Maester builds accept the pack.
- Added a quick start and a clear note about the pack's PowerShell trust boundary.
- Added schema validation for the example configuration and CI checks for changelog and documentation version drift.
- CI installs the Maester prerelease and requires Maester 3.x for pack validation; release jobs report release immutability and pack-index status.

## 0.4.0

- **Exclusions in three levels that add up.** Every test leaves out:
  1. the emergency access accounts and groups in Maester's own `GlobalSettings.EmergencyAccessAccounts` (turn this off for the pack with `"CLT.UA.ExcludeEmergencyAccessAccounts": false`);
  2. the pack-wide `GlobalSettings` `"CLT.UA.ExcludedUsers"` and `"CLT.UA.ExcludedGroups"`, set once for all 17 tests;
  3. the test's own `ExcludedUsers` and `ExcludedGroups`, as before.
  A test's own exclusions add to the others and never replace them. Each result ends with a line saying how many users each level left out. Groups are object IDs; the pack-wide `CLT.UA.ExcludedGroups` also accepts a group's mail address.
- A test's own `ExcludedUsers` accepts user principal names, as the README always said. The parameter declared Maester's `Entra.User` kind, which only accepts object IDs, so a UPN made the test fail with `InvalidConfiguration`.
- **Only licensed users (option).** `"CLT.UA.OnlyLicensedUsers": true` in `GlobalSettings` checks only member users with a licence, which leaves out most service, room and leftover accounts. Guests (MP.CLT.UA.1009) are not affected.
- The shared users request asks Graph for 999 users per page instead of 100, so large tenants need about a tenth of the requests.
- Failing presence results read "N of M users do not have a job title" (they read "have no a job title").
- The pack's repository is `DevClate/maester-pack-ua`: install it with `Install-MtPack DevClate/maester-pack-ua`. The pack's Id (`devclate.user-attributes`), Guid and code (`CLT.UA`) are unchanged.
- Added a banner (`assets/banner.png`, 1200 × 630) for the pack's card on packs.maester.cloud and the top of the README.
- Every test has a `MaxRows` parameter (default `100`). A failing result lists at most that many users or rows and says how many were left out; set it to `0` to list them all. Before, the presence tests listed every failing user, which could fill the report on a large tenant.
- Failing users are listed with their user principal name beside their display name.
- The tests share one Graph request for users, so Maester's cache reads the directory once per run instead of once per test. Users with no `userType` (some old accounts) are now treated as members, as Microsoft Entra does.
- `Feature` and `Area` use Maester's standard values (`identity-governance` or `external-identities`, and `identity-lifecycle`), so the results group with Maester's own Entra tests. Tests rated above `Info` now declare `UserImpact` and `ImplementationCost`.
- MP.CLT.UA.1014–1017 (business phone, mobile, fax, office location) have the tag `Optional`: leave them out with `-ExcludeTag Optional`.
- `RequiresMaester` is `>=3.0` (the `<4.0` bound blocked a future Maester without a known reason).
- Added `Homepage`, `Support`, `SecurityContact`, `Categories` and a pack page Guide (`maester-pack.guide.json`) to the manifest, plus `SECURITY.md` and the demo pack's CI and release workflows.
- Added the `.gitignore` that 0.3.0 described; it was missing from the folder. A `.DS_Store` file in the pack made `Test-MtPack` rate it High risk.
- README and TESTING.md: pack support is in the Maester preview build, not only a draft pull request.

## 0.3.0

- **Breaking:** the pack code is now `CLT.UA` (was `CLT`), so test IDs are `MP.CLT.UA.1001` to `MP.CLT.UA.1017` (were `MP.CLT.1001` to `MP.CLT.1017`). A bare `CLT` code would stop any other DevClate pack from being installed beside this one. Update `TestSettings`, `Selection` and `-TestId` values in your `maester-config.json` and scripts: replace `MP.CLT.` with `MP.CLT.UA.`.
- The suite Id is now `CLT.UA.UserAttributes`.
- Added the `Guid` the current Maester requires, and the manifest `$schema`.
- The user query helper passes its Graph parameters by name, so the current Maester's scan can confirm it only reads (it refused the pack before).
- The README and TESTING.md run the pack with `Invoke-Maester -Pack CLT.UA`: the current Maester only runs installed packs that are named with `-Pack` or `-AllPacks`.
- Added a `.gitignore` for files the operating system creates (`.DS_Store`, `Thumbs.db`).

# Changelog

## Unreleased

- The pack's repository is `DevClate/maester-pack-ua`: install it with `Install-MtPack DevClate/maester-pack-ua`. The pack's Id (`devclate.user-attributes`), Guid and code (`CLT.UA`) are unchanged.
- Added a banner (`assets/banner.png`, 1200 × 630) for the pack's card on packs.maester.cloud and the top of the README.

## 0.4.0

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

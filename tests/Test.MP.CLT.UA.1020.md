Checks that every company name set on enabled member users is one of your approved values. Blank values are not checked here (the presence tests check those).

In organisations with more than one legal entity or brand, company name decides which signature, policy or licence a user gets, and separates the companies in the address book and in dynamic groups. A variant spelling leaves the user out of all of them.

The approved values come from **companyName** in `CLT.UA.AllowedValues` under `GlobalSettings` in `maester-config.json` (approved office locations count too), from the file named in `CLT.UA.AllowedValuesFile`, or from this test's own `AllowedValues`, which replaces the shared list for this test only. Until any are set, this test lists the values it finds and asks you to review them (**Investigate**) instead of failing.

#### Remediation action

1. Review the values listed below and decide which are correct.
2. Add the approved values to `maester-config.json`:

   ```json
   { "GlobalSettings": { "CLT.UA.AllowedValues": { "companyName": ["Contoso Ltd", "Fabrikam Inc"] } } }
   ```

3. Change the users with a value that is not approved, in the [Microsoft Entra admin center](https://entra.microsoft.com) (**Entra ID** > **Users** > the user > **Edit properties** > **Job information** > **Company name**) or with PowerShell: `Update-MgUser -UserId <UPN> -CompanyName 'Contoso Ltd'`.
4. For users synced from Active Directory or provisioned from an HR system, fix the value at the source (`company` in AD), because changes made in Microsoft Entra ID are overwritten at the next sync.
5. If a value is correct but not listed, add it to the approved values rather than changing the user.

#### Related links

* [Manage rules for dynamic membership groups](https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership)
* [Add or update a user's profile information](https://learn.microsoft.com/entra/fundamentals/how-to-manage-user-profile-info)

<!--- Results --->
%TestResult%

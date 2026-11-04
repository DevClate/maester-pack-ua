Checks that every job title set on enabled member users is one of your approved values. Blank values are not checked here (the presence tests check those).

Job titles drive dynamic groups, approval routing, access reviews and the organisation chart. Free-typed titles (`IT Mgr`, `It manager`) multiply quickly, so rules and reports built on the approved titles miss people.

The approved values come from **jobTitle** in `CLT.UA.AllowedValues` under `GlobalSettings` in `maester-config.json`, from the file named in `CLT.UA.AllowedValuesFile`, or from this test's own `AllowedValues`, which replaces the shared list for this test only. Until any are set, this test lists the values it finds and asks you to review them (**Investigate**) instead of failing.

#### Remediation action

1. Review the values listed below and decide which are correct.
2. Add the approved values to `maester-config.json`:

   ```json
   { "GlobalSettings": { "CLT.UA.AllowedValues": { "jobTitle": ["Chief Executive Officer", "IT Manager", "Accountant"] } } }
   ```

3. Change the users with a value that is not approved, in the [Microsoft Entra admin center](https://entra.microsoft.com) (**Entra ID** > **Users** > the user > **Edit properties** > **Job information** > **Job title**) or with PowerShell: `Update-MgUser -UserId <UPN> -JobTitle 'IT Manager'`.
4. For users synced from Active Directory or provisioned from an HR system, fix the value at the source (`title` in AD), because changes made in Microsoft Entra ID are overwritten at the next sync.
5. If a value is correct but not listed, add it to the approved values rather than changing the user.

#### Related links

* [Manage rules for dynamic membership groups](https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership)
* [Cloud HR application to Microsoft Entra user provisioning](https://learn.microsoft.com/entra/identity/app-provisioning/plan-cloud-hr-provision)

<!--- Results --->
%TestResult%

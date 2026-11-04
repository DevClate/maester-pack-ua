Checks that every department set on enabled member users is one of your approved values. Blank values are not checked here (the presence tests check those).

Department is the attribute dynamic groups, licence assignment, Conditional Access scoping and HR reports use most. A department typed slightly differently (`Fin`, `Finance Dept`, `Finanace`) puts the user outside every group and policy built on the approved name, so they silently lose access or licences.

The approved values come from **department** in `CLT.UA.AllowedValues` under `GlobalSettings` in `maester-config.json`, from the file named in `CLT.UA.AllowedValuesFile`, or from this test's own `AllowedValues`, which replaces the shared list for this test only. Until any are set, this test lists the values it finds and asks you to review them (**Investigate**) instead of failing.

#### Remediation action

1. Review the values listed below and decide which are correct.
2. Add the approved values to `maester-config.json`:

   ```json
   { "GlobalSettings": { "CLT.UA.AllowedValues": { "department": ["IT", "Finance", "Human Resources"] } } }
   ```

3. Change the users with a value that is not approved, in the [Microsoft Entra admin center](https://entra.microsoft.com) (**Entra ID** > **Users** > the user > **Edit properties** > **Job information** > **Department**) or with PowerShell: `Update-MgUser -UserId <UPN> -Department 'Finance'`.
4. For users synced from Active Directory or provisioned from an HR system, fix the value at the source (`department` in AD), because changes made in Microsoft Entra ID are overwritten at the next sync.
5. If a value is correct but not listed, add it to the approved values rather than changing the user.

#### Related links

* [Manage rules for dynamic membership groups](https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership)
* [Cloud HR application to Microsoft Entra user provisioning](https://learn.microsoft.com/entra/identity/app-provisioning/plan-cloud-hr-provision)

<!--- Results --->
%TestResult%

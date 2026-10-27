Checks that every enabled member user has an employee hire date.

Lifecycle Workflows run joiner tasks (such as creating a Temporary Access Pass, adding groups, or emailing the manager) a set number of days before or after `employeeHireDate`. A user without a hire date never triggers those workflows. The date also helps access reviews and audits tell new starters from long-standing accounts.

Reading this attribute needs the **User-LifeCycleInfo.Read.All** Graph permission. If the connection Maester uses does not have it, every user looks blank; this test then reports **Investigate** instead of failing every user.

#### Remediation action

1. Make sure the app or account Maester connects with has **User-LifeCycleInfo.Read.All**.
2. For HR-provisioned users, map the HR start date to `employeeHireDate` in the provisioning app's attribute mappings.
3. For users synced from Active Directory, sync a start-date attribute to `employeeHireDate` (in Microsoft Entra Connect, through a directory extension and a sync rule).
4. For cloud users, set it with PowerShell: `Update-MgUser -UserId <UPN> -EmployeeHireDate '2026-11-02T00:00:00Z'`.

#### Related links

* [How to synchronize attributes for Lifecycle Workflows](https://learn.microsoft.com/entra/id-governance/how-to-lifecycle-workflow-sync-attributes)
* [user resource type: employeeHireDate](https://learn.microsoft.com/graph/api/resources/user)

<!--- Results --->
%TestResult%

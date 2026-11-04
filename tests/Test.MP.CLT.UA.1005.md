Checks that every enabled member user has an employee ID.

The employee ID is how HR-driven provisioning (Workday, SuccessFactors or API-driven inbound provisioning) matches an HR record to an account. Without it, a rehire can get a second account, a leaver's account may never be disabled, and audits cannot tie an account to a person. Accounts that are not people, such as service accounts, usually have no employee ID: exempt them with `ExcludedUsers` or `ExcludedGroups`.

#### Remediation action

1. Find each user listed below in your HR system and copy their employee number.
2. In the [Microsoft Entra admin center](https://entra.microsoft.com), go to **Entra ID** > **Users**, open the user, select **Edit properties** > **Job information**, enter the **Employee ID**, and save.
3. For many users, set it with PowerShell: `Update-MgUser -UserId <UPN> -EmployeeId '100234'`.
4. For users synced from Active Directory, set `employeeID` in AD. For HR-provisioned users, fix the attribute mapping so it is always written.

#### Related links

* [Cloud HR application to Microsoft Entra user provisioning](https://learn.microsoft.com/entra/identity/app-provisioning/plan-cloud-hr-provision)
* [user resource type: employeeId](https://learn.microsoft.com/graph/api/resources/user)

<!--- Results --->
%TestResult%

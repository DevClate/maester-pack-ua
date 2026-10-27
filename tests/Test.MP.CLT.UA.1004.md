Checks that every enabled member user has a department.

Department is one of the most common attributes in dynamic group rules (`user.department -eq "Finance"`), and those groups often grant access to apps, SharePoint sites and Conditional Access exclusions. Lifecycle Workflows can also use it to scope who a workflow runs for. A user with no department silently misses all of them.

#### Remediation action

1. In the [Microsoft Entra admin center](https://entra.microsoft.com), go to **Entra ID** > **Users** and open each user listed below.
2. Select **Edit properties** > **Job information**, enter the **Department**, and save.
3. For many users, set it with PowerShell: `Update-MgUser -UserId <UPN> -Department 'Finance'`.
4. For users synced from Active Directory or provisioned from an HR system, fix the value at the source (the AD `department` attribute, or the HR record).

#### Related links

* [Add or update a user's profile information](https://learn.microsoft.com/entra/fundamentals/how-to-manage-user-profile-info)
* [Manage rules for dynamic membership groups](https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership)

<!--- Results --->
%TestResult%

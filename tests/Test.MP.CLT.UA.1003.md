Checks that every enabled member user has a job title.

Job title shows in the Outlook and Teams profile card and the address book, and is often used in dynamic group rules (for example `user.jobTitle -eq "Nurse"`) that grant licences, apps and access. A missing title leaves people out of those groups without anyone noticing.

#### Remediation action

1. In the [Microsoft Entra admin center](https://entra.microsoft.com), go to **Entra ID** > **Users** and open each user listed below.
2. Select **Edit properties** > **Job information**, enter the **Job title**, and save.
3. For many users, set it with PowerShell: `Update-MgUser -UserId <UPN> -JobTitle 'Accountant'`.
4. For users synced from Active Directory or provisioned from an HR system, fix the value at the source (the AD `title` attribute, or the HR record), not in Microsoft Entra ID.

#### Related links

* [Add or update a user's profile information](https://learn.microsoft.com/entra/fundamentals/how-to-manage-user-profile-info)
* [Manage rules for dynamic membership groups](https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership)

<!--- Results --->
%TestResult%

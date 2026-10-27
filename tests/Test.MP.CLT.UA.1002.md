Checks that every enabled member user has a manager, except people at the top of the organisation (by default, the CEO).

Many Microsoft Entra features route decisions to a user's manager: access reviews where managers review their reports, access package approvals, Lifecycle Workflows tasks (such as emailing a new starter's manager), and the organisation chart in Outlook and Teams. A user without a manager makes those steps fail or fall back to an administrator.

#### Remediation action

1. In the [Microsoft Entra admin center](https://entra.microsoft.com), go to **Entra ID** > **Users** and open each user listed below.
2. Select **Edit properties** > **Job information**, choose the **Manager**, and save.
3. For many users, set it with PowerShell: `Set-MgUserManagerByRef -UserId <UPN> -BodyParameter @{ '@odata.id' = 'https://graph.microsoft.com/v1.0/users/<manager id>' }`.
4. For users synced from Active Directory, set the `manager` attribute in AD. Microsoft Entra Connect syncs it.
5. If someone legitimately has no manager, add their job title to `ExcludedJobTitles`, or the user to `ExcludedUsers`, for this test in `maester-config.json`.

#### Related links

* [Add or update a user's profile information](https://learn.microsoft.com/entra/fundamentals/how-to-manage-user-profile-info)
* [Assign a manager with Microsoft Graph](https://learn.microsoft.com/graph/api/user-post-manager)

<!--- Results --->
%TestResult%

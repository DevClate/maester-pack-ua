Checks that every enabled member user has a usage location (the two-letter country code licences are assigned for).

Microsoft 365 cannot assign a licence to a user without a usage location. Direct assignment fails, and group-based licensing puts the user in an error state, so new starters can end up without mailboxes or Teams. Usage location also decides which services are offered, because some are not available in every country.

#### Remediation action

1. In the [Microsoft Entra admin center](https://entra.microsoft.com), go to **Entra ID** > **Users** and open each user listed below.
2. Select **Edit properties** > **Settings**, choose the **Usage location**, and save.
3. For many users, set it with PowerShell: `Update-MgUser -UserId <UPN> -UsageLocation US`.
4. For users synced from Active Directory, set the source attribute (often `msExchUsageLocation` or `c`) and map it in Microsoft Entra Connect, or set a default in your provisioning process, so new users get one.

#### Related links

* [Assign Microsoft 365 licenses with PowerShell (includes usage location)](https://learn.microsoft.com/microsoft-365/enterprise/assign-licenses-to-user-accounts-with-microsoft-365-powershell)
* [user resource type: usageLocation](https://learn.microsoft.com/graph/api/resources/user)

<!--- Results --->
%TestResult%

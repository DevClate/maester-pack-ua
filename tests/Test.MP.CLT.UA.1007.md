Checks that every enabled member user has a company name.

In organisations with more than one legal entity or brand, company name separates them in the address book and in dynamic group rules (`user.companyName -eq "Contoso Ltd"`), and it often drives which email signature, policy or licence a user gets. In multi-tenant organisations it is also how people tell colleagues from different tenants apart.

#### Remediation action

1. In the [Microsoft Entra admin center](https://entra.microsoft.com), go to **Entra ID** > **Users** and open each user listed below.
2. Select **Edit properties** > **Job information**, enter the **Company name**, and save.
3. For many users, set it with PowerShell: `Update-MgUser -UserId <UPN> -CompanyName 'Contoso Ltd'`.
4. For users synced from Active Directory or provisioned from an HR system, fix the value at the source (the AD `company` attribute, or the HR record).

#### Related links

* [Add or update a user's profile information](https://learn.microsoft.com/entra/fundamentals/how-to-manage-user-profile-info)
* [Manage rules for dynamic membership groups](https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership)

<!--- Results --->
%TestResult%

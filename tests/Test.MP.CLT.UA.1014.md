Checks that every enabled member user has a business (office) phone number.

The business phone is the number colleagues and customers see on the Outlook and Teams profile card and in the address book, and it is often the number shown in email signatures and used by help desks to verify a caller. Organisations that give everyone a desk or Teams phone number should have it on every account. If some staff have no business number, exempt them with `ExcludedGroups`, or disable this test.

MP.CLT.UA.1011 checks that the numbers that are set use international format.

#### Remediation action

1. In the [Microsoft Entra admin center](https://entra.microsoft.com), go to **Entra ID** > **Users** and open each user listed below.
2. Select **Edit properties** > **Contact info**, enter the **Business phone** in international format (for example `+14255550100`), and save.
3. For many users, set it with PowerShell: `Update-MgUser -UserId <UPN> -BusinessPhones '+14255550100'`.
4. For users synced from Active Directory or provisioned from an HR system, fix the value at the source (the AD `telephoneNumber` attribute, or the HR record).

#### Related links

* [Add or update a user's profile information](https://learn.microsoft.com/entra/fundamentals/how-to-manage-user-profile-info)
* [user resource type: businessPhones](https://learn.microsoft.com/graph/api/resources/user)

<!--- Results --->
%TestResult%

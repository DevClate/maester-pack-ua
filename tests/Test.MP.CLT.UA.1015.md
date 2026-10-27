Checks that every enabled member user has a mobile phone number.

Organisations that issue company phones, or that need to reach staff out of hours, often require a mobile number on every account so it shows in the address book and on the profile card and can feed on-call, emergency-notification and HR systems. This attribute is the directory's mobile number. It is not the phone a user registered for MFA or self-service password reset, which is stored separately and is not checked here.

If some staff have no company mobile, exempt them with `ExcludedGroups`, or disable this test. MP.CLT.UA.1011 checks that the numbers that are set use international format.

#### Remediation action

1. In the [Microsoft Entra admin center](https://entra.microsoft.com), go to **Entra ID** > **Users** and open each user listed below.
2. Select **Edit properties** > **Contact info**, enter the **Mobile phone** in international format (for example `+14255550100`), and save.
3. For many users, set it with PowerShell: `Update-MgUser -UserId <UPN> -MobilePhone '+14255550100'`.
4. For users synced from Active Directory or provisioned from an HR system, fix the value at the source (the AD `mobile` attribute, or the HR record).

#### Related links

* [Add or update a user's profile information](https://learn.microsoft.com/entra/fundamentals/how-to-manage-user-profile-info)
* [user resource type: mobilePhone](https://learn.microsoft.com/graph/api/resources/user)

<!--- Results --->
%TestResult%

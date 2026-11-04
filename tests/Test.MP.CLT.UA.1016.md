Checks that every enabled member user has a fax number.

Some organisations, especially in healthcare, legal and government, still send and receive documents by fax and list each person's fax number in the address book. For them, a missing fax number means documents go to the wrong place or nobody knows where to send them. Most organisations no longer use fax: if yours does not, disable this test in `maester-config.json`.

#### Remediation action

1. In the [Microsoft Entra admin center](https://entra.microsoft.com), go to **Entra ID** > **Users** and open each user listed below.
2. Select **Edit properties** > **Contact info**, enter the **Fax number**, and save.
3. For many users, set it with PowerShell: `Update-MgUser -UserId <UPN> -FaxNumber '+14255550199'`.
4. For users synced from Active Directory or provisioned from an HR system, fix the value at the source (the AD `facsimileTelephoneNumber` attribute, or the HR record).
5. If you do not use fax, turn this test off: `{ "TestSettings": [ { "Id": "MP.CLT.UA.1016", "Enabled": false, "Reason": "Fax not used" } ] }`.

#### Related links

* [Add or update a user's profile information](https://learn.microsoft.com/entra/fundamentals/how-to-manage-user-profile-info)
* [user resource type: faxNumber](https://learn.microsoft.com/graph/api/resources/user)

<!--- Results --->
%TestResult%

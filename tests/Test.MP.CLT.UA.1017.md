Checks that every enabled member user has an office location, such as a building, floor or site name.

Office location appears on the Outlook and Teams profile card, helps colleagues find each other, and is used in dynamic groups that target a site (`user.physicalDeliveryOfficeName -eq "Seattle HQ"`) for printers, Wi-Fi, building access or local news. If some staff work fully remotely, exempt them with `ExcludedGroups`, or disable this test.

You can also require the office location as part of the full address check, by adding `officeLocation` to `Fields` in MP.CLT.UA.1008.

#### Remediation action

1. In the [Microsoft Entra admin center](https://entra.microsoft.com), go to **Entra ID** > **Users** and open each user listed below.
2. Select **Edit properties** > **Job information**, enter the **Office location**, and save.
3. For many users, set it with PowerShell: `Update-MgUser -UserId <UPN> -OfficeLocation 'Seattle HQ'`.
4. For users synced from Active Directory or provisioned from an HR system, fix the value at the source (the AD `physicalDeliveryOfficeName` attribute, or the HR record).

#### Related links

* [Add or update a user's profile information](https://learn.microsoft.com/entra/fundamentals/how-to-manage-user-profile-info)
* [Manage rules for dynamic membership groups](https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership)

<!--- Results --->
%TestResult%

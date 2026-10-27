Checks that every enabled member user has a complete office address. By default the street address, city, state or province, postal code and country must all be set; the `Fields` parameter changes which parts are required, and can add the office location.

The address appears on the profile card and in the address book, and is used in dynamic groups that target a site or region. It also feeds location-dependent processes such as emergency calling addresses, payroll and tax regions, and data-residency or compliance reporting. A partial address is often worse than none, because it looks right at a glance.

#### Remediation action

1. Review the missing fields for each user listed below.
2. In the [Microsoft Entra admin center](https://entra.microsoft.com), go to **Entra ID** > **Users**, open the user, select **Edit properties** > **Contact info**, fill in the missing fields, and save.
3. For many users, set them with PowerShell: `Update-MgUser -UserId <UPN> -StreetAddress '1 Main St' -City 'Seattle' -State 'WA' -PostalCode '98101' -Country 'United States'`.
4. For users synced from Active Directory or provisioned from an HR system, fix the values at the source (`streetAddress`, `l`, `st`, `postalCode` and `co` in AD), not in Microsoft Entra ID.
5. If some users have no office (fully remote staff), exempt them with `ExcludedGroups`, or reduce `Fields` to the parts you do require.

#### Related links

* [Add or update a user's profile information](https://learn.microsoft.com/entra/fundamentals/how-to-manage-user-profile-info)
* [user resource type](https://learn.microsoft.com/graph/api/resources/user)

<!--- Results --->
%TestResult%

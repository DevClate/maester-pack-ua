Checks that every enabled guest user has at least one sponsor.

A sponsor is the person or group responsible for a guest: they can be asked to review the guest's access, and entitlement management notifies them about the guest. Guests without a sponsor have nobody accountable for them, so they tend to keep their access long after the project that needed it has ended.

#### Remediation action

1. In the [Microsoft Entra admin center](https://entra.microsoft.com), go to **Entra ID** > **Users**, filter by **User type** = **Guest**, and open each guest listed below.
2. Select **Edit properties** > **Job information**, add the employee or group responsible for the guest under **Sponsors** (up to five), and save.
3. For many guests, the `Update-MsIdInvitedUserSponsorsFromInvitedBy` command in the Microsoft Identity Tools module (`MSIdentityTools`) sets each guest's sponsor to the person who invited them.
4. Make sponsors part of how guests arrive: when an invitation names no sponsor, the inviter becomes the sponsor.

#### Related links

* [Add sponsors to a guest user](https://learn.microsoft.com/entra/external-id/b2b-sponsors)
* [user resource type: sponsors](https://learn.microsoft.com/graph/api/resources/user)

<!--- Results --->
%TestResult%

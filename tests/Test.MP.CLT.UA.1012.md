Checks user name, job and location attributes for white space that should not be there: a leading or trailing space, two or more spaces in a row, a tab or line break, or an invisible character such as a non-breaking or zero-width space.

These mistakes are invisible in the admin center and the profile card, but they break anything that compares values exactly. A dynamic group rule `user.department -eq "Finance"` does not match `"Finance "`, so the user silently loses the access the group grants. Search, sorting, the address book and matching with HR or ITSM systems are affected in the same way. Invisible characters usually come from copying values out of a spreadsheet, email or web page.

#### Remediation action

1. Review the values listed below. In the **Value** column, ␣ marks each space, and invisible characters are shown as `[invisible]`.
2. Retype the value, or trim it with PowerShell: `Update-MgUser -UserId <UPN> -Department 'Finance'`.
3. For users synced from Active Directory or provisioned from an HR system, fix the value at the source; changes made in Microsoft Entra ID are overwritten at the next sync.
4. To stop it recurring, clean values where they enter: in the HR system, in your provisioning attribute mappings, or in the script that creates users (for example `$value.Trim() -replace ' {2,}', ' '`).

#### Related links

* [Manage rules for dynamic membership groups](https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership)
* [Writing expressions for attribute mappings](https://learn.microsoft.com/entra/identity/app-provisioning/functions-for-customizing-application-data)

<!--- Results --->
%TestResult%

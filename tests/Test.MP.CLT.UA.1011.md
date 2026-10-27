Checks that user phone numbers that are set are written in international E.164 format: a plus sign, the country code and the number, with no spaces or punctuation, such as `+14255550100`. Blank numbers are not a failure. By default the business and mobile phones are checked, a trailing extension (`;ext=123`, `x123`) is allowed, and spaces are not.

Numbers like `(425) 555-0100` or `0425 555 0100` only work for callers in the same country, and tools that read the directory (Teams calling, contact sync to phones, SMS and click-to-call apps, and HR or ITSM integrations) cannot dial or match them reliably. One consistent format also makes the address book searchable.

#### Remediation action

1. Review the numbers listed below and rewrite each one as `+<country code><number>`, dropping the national trunk prefix (the leading `0` in many countries) and any spaces, dashes, dots or brackets.
2. For cloud users, update them in the [Microsoft Entra admin center](https://entra.microsoft.com) under **Entra ID** > **Users** > the user > **Edit properties** > **Contact info**, or with PowerShell: `Update-MgUser -UserId <UPN> -MobilePhone '+14255550100' -BusinessPhones '+14255550100'`.
3. For users synced from Active Directory or provisioned from an HR system, fix the numbers at the source (`telephoneNumber` and `mobile` in AD), because changes made in Microsoft Entra ID are overwritten.
4. If your organisation deliberately stores numbers with spaces (`+1 425 555 0100`), set `AllowSpaces` to `true` for this test. To use a different rule entirely, set `PhonePattern`.

#### Related links

* [ITU-T Recommendation E.164](https://www.itu.int/rec/T-REC-E.164)
* [Add or update a user's profile information](https://learn.microsoft.com/entra/fundamentals/how-to-manage-user-profile-info)

<!--- Results --->
%TestResult%

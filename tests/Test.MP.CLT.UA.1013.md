Checks that the country attribute on member users uses one approved spelling per country.

The country (or region) attribute is free text, so one tenant can hold `US`, `USA`, `U.S.` and `United States` for the same place. Dynamic group rules, Conditional Access exclusions based on those groups, reports and HR integrations all compare the text exactly, so each spelling behaves like a different country. This is separate from **usage location** (checked by MP.CLT.UA.1001), which is a two-letter code chosen from a list.

Until you list the spellings your organisation uses in `AllowedCountries`, this test shows the values it finds and asks you to review them (**Investigate**) instead of failing.

#### Remediation action

1. Review the values listed below and pick one spelling for each country, for example `United States`.
2. Set those values for this test in `maester-config.json`:

   ```json
   { "TestSettings": [ { "Id": "MP.CLT.UA.1013", "Parameters": { "AllowedCountries": ["United States", "Canada"] } } ] }
   ```

3. Change the users with another spelling, in the [Microsoft Entra admin center](https://entra.microsoft.com) (**Edit properties** > **Contact info** > **Country or region**) or with PowerShell: `Update-MgUser -UserId <UPN> -Country 'United States'`.
4. For users synced from Active Directory or provisioned from an HR system, fix the value at the source (`co` in AD).

#### Related links

* [Add or update a user's profile information](https://learn.microsoft.com/entra/fundamentals/how-to-manage-user-profile-info)
* [Manage rules for dynamic membership groups](https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership)

<!--- Results --->
%TestResult%

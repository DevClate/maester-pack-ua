Checks that each enabled member user's address matches one of your approved office locations. By default the street address, city, state, postal code, country and company name must all match one location; set `Fields` to compare fewer fields, or to add the business phone (`businessPhones`) or office location. A field that an approved location leaves out is not compared. Users with none of the fields set are not checked (MP.CLT.UA.1008 checks missing address fields).

Each field can be valid on its own and still describe an address that does not exist: the Seattle street with the New York postal code, or the right office with another company's name. Those mixed addresses send mail and deliveries to the wrong place, give Teams emergency calling the wrong location, and put users in the wrong location-based groups. For each user that matches no location, the result shows the closest approved location and exactly which fields differ.

#### Remediation action

1. List your offices under `locations` in `CLT.UA.AllowedValues` in `maester-config.json`. Each location can have a `name`, which the results show:

   ```json
   {
     "GlobalSettings": {
       "CLT.UA.AllowedValues": {
         "locations": [
           { "name": "Seattle HQ", "streetAddress": "1 Microsoft Way", "city": "Redmond", "state": "WA",
             "postalCode": "98052", "country": "United States", "companyName": "Contoso Ltd",
             "businessPhones": "+14255550100" }
         ]
       }
     }
   }
   ```

   A 2.x `validation.json` works too: point `CLT.UA.AllowedValuesFile` at it (`zipCode` is read as `postalCode`).
2. For each user listed below, correct the fields in **Differs in** to match the closest location, in the [Microsoft Entra admin center](https://entra.microsoft.com) (**Entra ID** > **Users** > the user > **Edit properties** > **Contact info**) or with `Update-MgUser`.
3. For users synced from Active Directory or provisioned from an HR system, fix the address at the source, because changes made in Microsoft Entra ID are overwritten at the next sync.
4. If the user works at an office that is not listed, add the office to `locations`.

#### Related links

* [Add or update a user's profile information](https://learn.microsoft.com/entra/fundamentals/how-to-manage-user-profile-info)
* [Manage rules for dynamic membership groups](https://learn.microsoft.com/entra/identity/users/groups-dynamic-membership)

<!--- Results --->
%TestResult%

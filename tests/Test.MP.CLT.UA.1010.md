Checks that no two member users share an employee ID. IDs are compared ignoring surrounding spaces and letter case (and, if `IgnoreLeadingZeros` is set, leading zeros). Disabled accounts are included by default.

HR-driven provisioning and many identity tools use the employee ID as the key that ties an account to a person. When two accounts share an ID, provisioning can update or disable the wrong account, a rehire can inherit a leaver's group memberships, and access reviews and audits cannot tell who an account belongs to. Duplicates usually come from rehires, typos, or a test account copied from a real one.

#### Remediation action

1. For each shared ID listed below, check the HR record to see which account the ID belongs to.
2. Correct the other accounts' employee ID (or clear it, for accounts that are not a person). For a rehire, decide with HR whether to reactivate the old account or keep the new one, then remove the ID from the account you are not keeping.
3. Change the value at its source: the AD `employeeID` attribute for synced users, the HR record for HR-provisioned users, or **Edit properties** > **Job information** in the [Microsoft Entra admin center](https://entra.microsoft.com) for cloud users.
4. If your HR system pads IDs with zeros inconsistently, set `IgnoreLeadingZeros` to `true` for this test so `00123` and `123` are treated as the same ID.

#### Related links

* [Cloud HR application to Microsoft Entra user provisioning](https://learn.microsoft.com/entra/identity/app-provisioning/plan-cloud-hr-provision)
* [user resource type: employeeId](https://learn.microsoft.com/graph/api/resources/user)

<!--- Results --->
%TestResult%

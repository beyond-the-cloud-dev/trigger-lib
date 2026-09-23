- **Apex in the same transaction** (anonymous Apex, a script, a batch). Switch the object off before the DML and clear the switch afterwards:

  ```apex
  TriggerOrchestrator.bypass().sObject(Account.SObjectType);
  try {
      update accounts;
  } finally {
      TriggerOrchestrator.bypass().clear();
  }
  ```

  In a batch, set the switch inside `execute`: every `execute` call runs in its own transaction, and the switch does not carry over from `start`.
- **Data Loader, Bulk API or an import wizard.** None of your Apex runs before the load, so use custom metadata. Check `Bypass__c` on the object's `TriggerObject__mdt` record to switch off every handler on the object, or on `TriggerHandler__mdt` records to switch off single handlers. Both apply to every user in the org while they are checked, so uncheck them after the load.
- **Only the migration user.** Assign the migration user a custom permission and check it with `FeatureManagement.checkPermission('<Custom Permission>')` in the handlers' Bypassable methods. Other users' saves keep running the handlers during the load.

The full recipe: [Bypassing](/guide/bypasses#data-migration).

The method returns one entry per lookup field of the trigger object. Each value lists the parent fields to load, built with `TriggerHandler.ParentFields`:

```apex
return new Map<SObjectField, TriggerHandler.ParentFields>{
    Contact.AccountId => TriggerHandler.ParentFields.with(Account.Name, Account.Industry).with('Owner', User.IsActive),
    Contact.ReportsToId => TriggerHandler.ParentFields.with(Contact.Email)
};
```

- **Parent fields.** `with(...)` takes 1 to 5 fields of the parent object. For more, pass an `Iterable<SObjectField>`, such as a `List` or a `Set`.
- **Grandparent fields.** `with('Owner', User.IsActive)` loads fields of the record the parent points to. The first argument is a relationship name on the parent, and the fields that follow belong to that record (1 to 5, or an `Iterable<SObjectField>`). Read them through the parent, for example `((Account) parent).Owner.IsActive`.
- **Chaining.** Every `with` returns the same `ParentFields`, so parent and grandparent fields chain in one expression.
- **What is loaded.** The declared fields and the parent's `Id`. Reading any other field of the parent throws `System.SObjectException: SObject row was retrieved via SOQL without querying the requested field`.
- **One entry per lookup.** Two lookups to the same object are loaded separately, each under its own relationship name.

More on `TriggerHandler.ParentFields`: [Field Selection](/api/field-selection).

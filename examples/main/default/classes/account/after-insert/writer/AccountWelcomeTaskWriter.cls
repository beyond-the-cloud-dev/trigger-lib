public with sharing class AccountWelcomeTaskWriter implements AfterInsert.Writer, AfterInsert.ParentQuery, AfterInsert.ContinueOnError {
    public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterInsert() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Account.OwnerId => TriggerTypes.ParentFields.with(User.Name, User.Email) };
    }

    public Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record) {
        return record.startsWith(Account.Type, 'Customer');
    }

    public void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork) {
        Account newAccount = (Account) record.getNewSObject();
        User owner = (User) record.getNewParent(Account.OwnerId);

        unitOfWork.toInsert(
            new Task(
                WhatId = record.getId(),
                OwnerId = newAccount.OwnerId,
                Subject = 'Onboarding call - ' + newAccount.Name,
                Description = 'New customer assigned to ' + owner?.Name + ' (' + owner?.Email + '). Confirm the billing address and the primary contact.',
                ActivityDate = Date.today().addDays(3),
                Priority = 'High',
                Status = 'Not Started'
            )
        );
    }
}

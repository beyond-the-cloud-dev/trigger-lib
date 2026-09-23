public with sharing class AccountWelcomeTaskWriter implements AfterInsert.Writer, AfterInsert.ParentQuery, AfterInsert.ContinueOnError {
    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterInsert() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Account.OwnerId => TriggerHandler.ParentFields.with(User.Name, User.Email) };
    }

    public Boolean writeOnAfterInsertWhen(TriggerHandler.InsertRecord record) {
        return record.startsWith(Account.Type, 'Customer');
    }

    public void writeOnAfterInsert(TriggerHandler.InsertRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        Account accountRecord = (Account) record.getNewSObject();
        User owner = (User) record.getNewParent('Owner');

        unitOfWork.toInsert(
            new Task(
                WhatId = record.getId(),
                OwnerId = accountRecord.OwnerId,
                Subject = 'Onboarding call - ' + accountRecord.Name,
                Description = 'New customer assigned to ' + owner?.Name + ' (' + owner?.Email + '). Confirm the billing address and the primary contact.',
                ActivityDate = Date.today().addDays(3),
                Priority = 'High',
                Status = 'Not Started'
            )
        );
    }
}

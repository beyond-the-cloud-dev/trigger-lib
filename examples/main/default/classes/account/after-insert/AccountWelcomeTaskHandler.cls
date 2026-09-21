public with sharing class AccountWelcomeTaskHandler implements AfterInsert.Handler, AfterInsert.ParentQuery, AfterInsert.Finalizer, AfterInsert.ContinueOnError {
    private List<Task> onboardingTasks = new List<Task>();

    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterInsert() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Account.OwnerId => TriggerHandler.ParentFields.with(User.Name, User.Email) };
    }

    public Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record) {
        return record.startsWith(Account.Type, 'Customer');
    }

    public void onAfterInsert(TriggerHandler.InsertRecord record) {
        Account accountRecord = (Account) record.getNewSObject();
        User owner = (User) record.getNewRelated('Owner');

        this.onboardingTasks.add(
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

    public void finalizeAfterInsert() {
        insert this.onboardingTasks;
    }
}

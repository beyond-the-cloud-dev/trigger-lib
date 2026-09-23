public with sharing class OpportunityWinTaskWriter implements AfterUpdate.Writer, AfterUpdate.ParentQuery, AfterUpdate.ContinueOnError {
    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Opportunity.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
    }

    public Boolean writeOnAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChangedTo(Opportunity.StageName, 'Closed Won');
    }

    public void writeOnAfterUpdate(TriggerHandler.UpdateRecord record, TriggerHandler.UnitOfWork unitOfWork) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();
        Account parentAccount = (Account) record.getNewParent('Account');

        unitOfWork.toInsert(
            new Task(
                WhatId = record.getId(),
                OwnerId = newOpportunity.OwnerId,
                Subject = 'Onboarding kick-off: ' + (parentAccount?.Name ?? newOpportunity.Name),
                Description = 'Won on ' + Date.today().format() + '. Agree the implementation plan with the customer.',
                ActivityDate = Date.today().addDays(7),
                Priority = 'High',
                Status = 'Not Started'
            )
        );
    }
}

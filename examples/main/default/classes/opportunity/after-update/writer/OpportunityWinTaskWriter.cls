public with sharing class OpportunityWinTaskWriter implements AfterUpdate.Writer, AfterUpdate.ParentQuery, AfterUpdate.ContinueOnError {
    public Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterUpdate() {
        return new Map<SObjectField, TriggerTypes.ParentFields>{ Opportunity.AccountId => TriggerTypes.ParentFields.with(Account.Name) };
    }

    public Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isChangedTo(Opportunity.StageName, 'Closed Won');
    }

    public void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();
        Account account = (Account) record.getNewParent(Opportunity.AccountId);

        unitOfWork.toInsert(
            new Task(
                WhatId = record.getId(),
                OwnerId = newOpportunity.OwnerId,
                Subject = 'Onboarding kick-off: ' + (account?.Name ?? newOpportunity.Name),
                Description = 'Won on ' + Date.today().format() + '. Agree the implementation plan with the customer.',
                ActivityDate = Date.today().addDays(7),
                Priority = 'High',
                Status = 'Not Started'
            )
        );
    }
}

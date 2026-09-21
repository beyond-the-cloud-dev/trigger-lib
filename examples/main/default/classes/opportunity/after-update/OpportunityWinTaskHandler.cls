public with sharing class OpportunityWinTaskHandler implements AfterUpdate.Handler, AfterUpdate.ParentQuery, AfterUpdate.Finalizer, AfterUpdate.ContinueOnError {
    private List<Task> onboardingTasks = new List<Task>();

    public Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUpdate() {
        return new Map<SObjectField, TriggerHandler.ParentFields>{ Opportunity.AccountId => TriggerHandler.ParentFields.with(Account.Name) };
    }

    public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChangedTo(Opportunity.StageName, 'Closed Won');
    }

    public void onAfterUpdate(TriggerHandler.UpdateRecord record) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();
        Account parentAccount = (Account) record.getNewRelated('Account');

        this.onboardingTasks.add(
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

    public void finalizeAfterUpdate() {
        insert this.onboardingTasks;
    }
}

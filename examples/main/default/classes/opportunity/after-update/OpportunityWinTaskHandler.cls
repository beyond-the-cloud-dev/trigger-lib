public with sharing class OpportunityWinTaskHandler implements AfterUpdate.Handler, AfterUpdate.NewRecordEnrichment, AfterUpdate.Finalizer, AfterUpdate.ContinueOnError {
    private static final String CLOSED_WON = 'Closed Won';
    private static final Integer KICK_OFF_DUE_IN_DAYS = 7;

    private List<Task> onboardingTasks = new List<Task>();

    public Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterUpdate() {
        return new Map<SObjectField, TriggerHandler.FieldSelection>{ Opportunity.AccountId => TriggerHandler.FieldSelection.with(Account.Name) };
    }

    public Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChangedTo(Opportunity.StageName, CLOSED_WON);
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
                ActivityDate = Date.today().addDays(KICK_OFF_DUE_IN_DAYS),
                Priority = 'High',
                Status = 'Not Started'
            )
        );
    }

    public void finalizeAfterUpdate() {
        insert this.onboardingTasks;
    }
}

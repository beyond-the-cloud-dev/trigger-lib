public with sharing class OpportunityLargeDealValidator implements BeforeUpdate.Validator {
    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();

        return record.greaterThan(Opportunity.Amount, 100000) &&
            !new Set<String>{ 'Closed Won', 'Closed Lost' }.contains(newOpportunity.StageName) &&
            record.isBlank(Opportunity.NextStep);
    }

    public void addErrorOnBeforeUpdate(TriggerHandler.RejectableUpdateRecord record) {
        record.addError(Opportunity.NextStep, 'Open Opportunities above 100,000 must have a Next Step. Document the agreed action with the customer.');
    }
}

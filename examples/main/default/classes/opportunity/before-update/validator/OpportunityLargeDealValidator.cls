public with sharing class OpportunityLargeDealValidator implements BeforeUpdate.Validator {
    private static final Decimal LARGE_DEAL_AMOUNT = 100000;
    private static final Set<String> CLOSED_STAGES = new Set<String>{ 'Closed Won', 'Closed Lost' };

    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();

        return record.greaterThan(Opportunity.Amount, LARGE_DEAL_AMOUNT) && !CLOSED_STAGES.contains(newOpportunity.StageName) && record.isBlank(Opportunity.NextStep);
    }

    public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
        return 'Open Opportunities above ' + LARGE_DEAL_AMOUNT.format() + ' must have a Next Step. Document the agreed action with the customer.';
    }
}

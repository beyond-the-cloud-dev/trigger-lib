public with sharing class OpportunityForecastPopulator implements BeforeUpdate.Populator {
    private static final Decimal SMALL_DEAL_AMOUNT = 5000;
    private static final String OMITTED_CATEGORY = 'Omitted';
    private static final Set<String> CLOSED_STAGES = new Set<String>{ 'Closed Won', 'Closed Lost' };

    public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();

        return record.isAnyChanged(Opportunity.Amount, Opportunity.StageName) &&
            !CLOSED_STAGES.contains(newOpportunity.StageName) &&
            record.lessThan(Opportunity.Amount, SMALL_DEAL_AMOUNT);
    }

    public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
        record.put(Opportunity.ForecastCategoryName, OMITTED_CATEGORY);
    }
}

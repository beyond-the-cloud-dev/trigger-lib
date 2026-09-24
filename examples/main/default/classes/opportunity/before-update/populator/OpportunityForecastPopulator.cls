public with sharing class OpportunityForecastPopulator implements BeforeUpdate.Populator {
    public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();

        return record.isAnyChanged(Opportunity.Amount, Opportunity.StageName) &&
            !new Set<String>{ 'Closed Won', 'Closed Lost' }.contains(newOpportunity.StageName) &&
            record.lessThan(Opportunity.Amount, 5000);
    }

    public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
        record.put(Opportunity.ForecastCategoryName, 'Omitted');
    }
}

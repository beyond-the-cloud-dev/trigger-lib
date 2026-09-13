public with sharing class OpportunityClosingPopulator implements BeforeUpdate.Populator, BeforeUpdate.RecursionGuard {
    private static final Set<String> CLOSED_STAGES = new Set<String>{ 'Closed Won', 'Closed Lost' };

    public Integer maxRecursionDepthOnBeforeUpdate() {
        return 1;
    }

    public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();

        return record.isChanged(Opportunity.StageName) && CLOSED_STAGES.contains(newOpportunity.StageName);
    }

    public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();
        Opportunity oldOpportunity = (Opportunity) record.getOldSObject();

        record.put(Opportunity.NextStep, null);

        String closingNote = newOpportunity.StageName + ' by ' + UserInfo.getName() + ' on ' + Date.today().format() + ' (previous stage: ' + oldOpportunity.StageName + ')';

        record.put(Opportunity.Description, record.isBlank(Opportunity.Description) ? closingNote : newOpportunity.Description + '\n' + closingNote);
    }
}

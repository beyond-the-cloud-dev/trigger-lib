public with sharing class OpportunityProbabilityPopulator implements BeforeUpdate.Populator {
    private static final Map<String, Double> PROBABILITY_BY_STAGE = new Map<String, Double>{
        'Prospecting' => 10,
        'Qualification' => 20,
        'Needs Analysis' => 30,
        'Value Proposition' => 40,
        'Id. Decision Makers' => 50,
        'Perception Analysis' => 60,
        'Proposal/Price Quote' => 75,
        'Negotiation/Review' => 90,
        'Closed Won' => 100,
        'Closed Lost' => 0
    };

    public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();

        return record.isChanged(Opportunity.StageName) && PROBABILITY_BY_STAGE.containsKey(newOpportunity.StageName);
    }

    public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
        Opportunity newOpportunity = (Opportunity) record.getNewSObject();

        record.put(Opportunity.Probability, PROBABILITY_BY_STAGE.get(newOpportunity.StageName));
    }
}

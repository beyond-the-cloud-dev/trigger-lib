public with sharing class OpportunityCloseDatePopulator implements BeforeInsert.Populator {
    public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        return record.isNull(Opportunity.CloseDate);
    }

    public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
        record.put(Opportunity.CloseDate, this.endOfCurrentQuarter());
    }

    private Date endOfCurrentQuarter() {
        Date today = Date.today();
        Integer lastMonthOfQuarter = ((today.month() - 1) / 3 + 1) * 3;

        return Date.newInstance(today.year(), lastMonthOfQuarter, 1).addMonths(1).addDays(-1);
    }
}

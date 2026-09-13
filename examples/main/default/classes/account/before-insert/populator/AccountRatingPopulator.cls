public with sharing class AccountRatingPopulator implements BeforeInsert.Populator {
    private static final Decimal HOT_REVENUE_FLOOR = 5000000;
    private static final Decimal WARM_REVENUE_FLOOR = 500000;

    public Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record) {
        return record.isBlank(Account.Rating) && record.isNotNull(Account.AnnualRevenue);
    }

    public void populateOnBeforeInsert(TriggerHandler.InsertRecord record) {
        record.put(Account.Rating, this.ratingFor(record));
    }

    private String ratingFor(TriggerHandler.InsertRecord record) {
        if (record.greaterThanOrEqualTo(Account.AnnualRevenue, HOT_REVENUE_FLOOR)) {
            return 'Hot';
        }

        if (record.greaterThanOrEqualTo(Account.AnnualRevenue, WARM_REVENUE_FLOOR)) {
            return 'Warm';
        }

        return 'Cold';
    }
}

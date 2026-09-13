public with sharing class AccountRatingRefreshPopulator implements BeforeUpdate.Populator {
    private static final Decimal HOT_REVENUE_FLOOR = 5000000;
    private static final Decimal WARM_REVENUE_FLOOR = 500000;

    public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChanged(Account.AnnualRevenue) && record.isNotNull(Account.AnnualRevenue);
    }

    public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
        record.put(Account.Rating, this.ratingFor(record));
    }

    private String ratingFor(TriggerHandler.UpdateRecord record) {
        if (record.greaterThanOrEqualTo(Account.AnnualRevenue, HOT_REVENUE_FLOOR)) {
            return 'Hot';
        }

        if (record.greaterThanOrEqualTo(Account.AnnualRevenue, WARM_REVENUE_FLOOR)) {
            return 'Warm';
        }

        return 'Cold';
    }
}

public with sharing class AccountRatingRefreshPopulator implements BeforeUpdate.Populator {
    public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChanged(Account.AnnualRevenue) && record.isNotNull(Account.AnnualRevenue);
    }

    public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
        record.put(Account.Rating, this.ratingFor(record));
    }

    private String ratingFor(TriggerHandler.UpdateRecord record) {
        if (record.greaterThanOrEqualTo(Account.AnnualRevenue, 5000000)) {
            return 'Hot';
        }

        if (record.greaterThanOrEqualTo(Account.AnnualRevenue, 500000)) {
            return 'Warm';
        }

        return 'Cold';
    }
}

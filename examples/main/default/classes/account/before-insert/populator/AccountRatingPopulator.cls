public with sharing class AccountRatingPopulator implements BeforeInsert.Populator {
    public Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record) {
        return record.isBlank(Account.Rating) && record.isNotNull(Account.AnnualRevenue);
    }

    public void populateOnBeforeInsert(TriggerTypes.InsertRecord record) {
        record.put(Account.Rating, this.ratingFor(record));
    }

    private String ratingFor(TriggerTypes.InsertRecord record) {
        if (record.greaterThanOrEqualTo(Account.AnnualRevenue, 5000000)) {
            return 'Hot';
        }

        if (record.greaterThanOrEqualTo(Account.AnnualRevenue, 500000)) {
            return 'Warm';
        }

        return 'Cold';
    }
}

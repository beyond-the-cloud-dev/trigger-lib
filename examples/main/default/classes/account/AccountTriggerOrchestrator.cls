public with sharing class AccountTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.AfterInsert, TriggerOrchestrator.BeforeUpdate, TriggerOrchestrator.AfterUpdate {
    public List<BeforeInsert.Handler> beforeInsertHandlers() {
        return new List<BeforeInsert.Handler>{
            new AccountParentDefaultsPopulator(),
            new AccountRatingPopulator(),
            new AccountShippingAddressPopulator(),
            new AccountCustomerDataValidator(),
            new AccountParentTypeValidator()
        };
    }

    public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
        return new List<BeforeUpdate.Handler>{
            new AccountRatingRefreshPopulator(),
            new AccountShippingSyncPopulator(),
            new AccountTypeAuditPopulator(),
            new AccountDemotionValidator(),
            new AccountBillingCountryValidator(),
            new AccountParentMoveValidator()
        };
    }

    public List<AfterInsert.Handler> afterInsertHandlers() {
        return new List<AfterInsert.Handler>{ new AccountWelcomeTaskHandler() };
    }

    public List<AfterUpdate.Handler> afterUpdateHandlers() {
        return new List<AfterUpdate.Handler>{ new AccountAddressCascadeHandler(), new AccountOwnerTransferHandler() };
    }
}

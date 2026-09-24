public with sharing class AccountDemotionValidator implements BeforeUpdate.Validator {
    public Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        Account oldAccount = (Account) record.getOldSObject();

        return record.isChangedTo(Account.Type, 'Prospect') && oldAccount.Type?.startsWith('Customer') == true;
    }

    public void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record) {
        Account oldAccount = (Account) record.getOldSObject();

        record.addError(Account.Type, 'This account is already ' + oldAccount.Type + ' and cannot be moved back to Prospect. Close it as Lost instead.');
    }
}

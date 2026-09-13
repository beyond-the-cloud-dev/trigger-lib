public with sharing class AccountDemotionValidator implements BeforeUpdate.Validator {
    public Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        Account oldAccount = (Account) record.getOldSObject();

        return record.isChangedTo(Account.Type, 'Prospect') && oldAccount.Type?.startsWith('Customer') == true;
    }

    public String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record) {
        Account oldAccount = (Account) record.getOldSObject();

        return 'This account is already ' + oldAccount.Type + ' and cannot be moved back to Prospect. Close it as Lost instead.';
    }
}

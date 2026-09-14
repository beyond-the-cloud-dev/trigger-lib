public with sharing class AccountTypeAuditPopulator implements BeforeUpdate.Populator, BeforeUpdate.RecursionGuard {
    public Integer maxRecursionDepthOnBeforeUpdate() {
        return 1;
    }

    public Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record) {
        return record.isChanged(Account.Type);
    }

    public void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record) {
        Account accountRecord = (Account) record.getNewSObject();
        Account oldAccount = (Account) record.getOldSObject();

        String auditLine =
            Datetime.now().format('yyyy-MM-dd HH:mm') +
            ' - Type ' +
            (oldAccount.Type ?? 'none') +
            ' -> ' +
            (accountRecord.Type ?? 'none') +
            ' by ' +
            UserInfo.getName();

        record.put(Account.Description, this.stampedDescription(auditLine, accountRecord.Description));
    }

    private String stampedDescription(String auditLine, String description) {
        String stamped = String.isBlank(description) ? auditLine : auditLine + '\n' + description;

        return stamped.length() > 32000 ? stamped.left(32000) : stamped;
    }
}

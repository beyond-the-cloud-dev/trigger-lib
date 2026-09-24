public with sharing class AccountTypeAuditPopulator implements BeforeUpdate.Populator, BeforeUpdate.RecursionGuard {
    public Integer maxRunsPerRecordOnBeforeUpdate() {
        return 1;
    }

    public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        return record.isChanged(Account.Type);
    }

    public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
        Account newAccount = (Account) record.getNewSObject();
        Account oldAccount = (Account) record.getOldSObject();

        String auditLine =
            Datetime.now().format('yyyy-MM-dd HH:mm') +
            ' - Type ' +
            (oldAccount.Type ?? 'none') +
            ' -> ' +
            (newAccount.Type ?? 'none') +
            ' by ' +
            UserInfo.getName();

        record.put(Account.Description, this.stampedDescription(auditLine, newAccount.Description));
    }

    private String stampedDescription(String auditLine, String description) {
        String stamped = String.isBlank(description) ? auditLine : auditLine + '\n' + description;

        return stamped.length() > 32000 ? stamped.left(32000) : stamped;
    }
}

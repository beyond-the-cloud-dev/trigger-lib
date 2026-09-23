public with sharing class ContactTriggerOrchestrator implements TriggerOrchestrator.BeforeInsert, TriggerOrchestrator.BeforeUpdate, TriggerOrchestrator.AfterInsert {
    public List<BeforeInsert.Handler> beforeInsertHandlers() {
        return new List<BeforeInsert.Handler>{
            new ContactEmailNormalizationPopulator(),
            new ContactMailingAddressPopulator(),
            new ContactReachabilityValidator(),
            new ContactEmailFormatValidator(),
            new ContactBirthdateValidator()
        };
    }

    public List<BeforeUpdate.Handler> beforeUpdateHandlers() {
        return new List<BeforeUpdate.Handler>{
            new ContactTitleDepartmentPopulator(),
            new ContactAccountTransferPopulator(),
            new ContactEmailRemovalValidator(),
            new ContactDoNotCallValidator()
        };
    }

    public List<AfterInsert.Handler> afterInsertHandlers() {
        return new List<AfterInsert.Handler>{ new ContactOwnerAlignmentWriter(), new ContactFollowUpTaskWriter() };
    }
}

public class BeforeInsert {
    // main interfaces

    public interface Populator extends Handler {
        Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record);
        void populateOnBeforeInsert(TriggerHandler.InsertRecord record);
    }

    public interface Validator extends Handler {
        Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record);
        String beforeInsertValidationMessage(TriggerHandler.InsertRecord record);
    }

    // additional interfaces

    public interface NewRecordEnrichment {
        Map<SObjectField, TriggerHandler.ParentFields> newFieldsToEnrichOnBeforeInsert();
    }

    public interface Bypassable {
        Boolean bypassOnBeforeInsertWhen();
    }

    public interface Finalizer {
        void finalizeBeforeInsert();
    }

    public interface ContinueOnError {
    }

    // internal

    public interface Handler {
    }
}

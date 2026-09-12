public class BeforeInsert {
    // main interfaces

    public interface Populator extends Handler {
        Boolean populateOnBeforeInsertWhen(TriggerHandler.Record record);
        void populateOnBeforeInsert(TriggerHandler.Record record);
    }

    public interface Validator extends Handler {
        Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.Record record);
        String beforeInsertValidationMessage(TriggerHandler.Record record);
    }

    // additional interfaces

    public interface NewRecordEnrichment {
        Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnBeforeInsert();
    }

    public interface Bypassable {
        Boolean bypassOnBeforeInsertWhen();
    }

    public interface Finalizer {
        void finalizeBeforeInsert();
    }

    public interface ContinueOnError {}

    // internal

    public interface Handler {}
}

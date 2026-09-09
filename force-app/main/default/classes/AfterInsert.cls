public class AfterInsert {
    public interface Handler {
        Boolean qualifiesForAfterInsertWhen(TriggerHandler.Record record);
        void onAfterInsert(TriggerHandler.Record record);
    }

    public interface NewRecordEnrichment {
        Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterInsert();
    }

    public interface Bypassable {
        Boolean bypassOnAfterInsertWhen();
    }

    public interface Finalizer {
        void finalizeAfterInsert();
    }

    public interface ContinueOnError {}
}

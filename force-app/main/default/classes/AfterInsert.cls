public class AfterInsert {
    public interface Handler {
        Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record);
        void onAfterInsert(TriggerHandler.InsertRecord record);
    }

    public interface NewRecordEnrichment {
        Map<SObjectField, TriggerHandler.ParentFields> newFieldsToEnrichOnAfterInsert();
    }

    public interface Bypassable {
        Boolean bypassOnAfterInsertWhen();
    }

    public interface Finalizer {
        void finalizeAfterInsert();
    }

    public interface ContinueOnError {
    }
}

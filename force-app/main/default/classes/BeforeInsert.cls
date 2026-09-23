public class BeforeInsert {
    // Main interfaces - pick one

    public interface Populator extends Handler {
        Boolean populateOnBeforeInsertWhen(TriggerHandler.InsertRecord record);
        void populateOnBeforeInsert(TriggerHandler.InsertRecord record);
    }

    public interface Validator extends Handler {
        Boolean errorShouldBeAttachedOnBeforeInsertWhen(TriggerHandler.InsertRecord record);
        void addErrorOnBeforeInsert(TriggerHandler.RejectableInsertRecord record);
    }

    // Additional interfaces - pick as many as you need

    public interface ParentQuery {
        Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeInsert();
    }

    public interface RelatedQuery {
        Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerHandler.InsertRecords records);
        String keyOf(SObject record);
    }

    public interface Bypassable {
        Boolean bypassOnBeforeInsertWhen();
    }

    public interface Finalizer {
        void finalizeBeforeInsert(TriggerHandler.InsertRecords records);
    }

    public interface ContinueOnError {
    }

    // For internal use only

    public interface Handler {
    }
}

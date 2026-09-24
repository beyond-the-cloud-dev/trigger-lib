public class BeforeInsert {
    // Roles - pick one

    public interface Populator extends Handler {
        Boolean populateOnBeforeInsertWhen(TriggerTypes.InsertRecord record);
        void populateOnBeforeInsert(TriggerTypes.InsertRecord record);
    }

    public interface Validator extends Handler {
        Boolean addErrorOnBeforeInsertWhen(TriggerTypes.InsertRecord record);
        void addErrorOnBeforeInsert(TriggerTypes.RejectableInsertRecord record);
    }

    // Add-ons - pick as many as you need

    public interface ParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeInsert();
    }

    public interface RelatedQuery {
        Map<String, BeforeInsert.RecordsProvider> queryRelatedOnBeforeInsert();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerTypes.InsertRecords records);
        String keyOf(SObject row);
    }

    public interface Bypassable {
        Boolean bypassOnBeforeInsertWhen();
    }

    public interface Finalizer {
        void finalizeOnBeforeInsert(TriggerTypes.InsertRecords records);
    }

    public interface ContinueOnError {
    }

    // Marker

    public interface Handler {
    }
}

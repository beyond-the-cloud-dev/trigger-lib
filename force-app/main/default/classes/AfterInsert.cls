public class AfterInsert {
    public interface Handler {
        Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record);
        void onAfterInsert(TriggerHandler.InsertRecord record);
    }

    public interface ParentQuery {
        Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterInsert();
    }

    public interface RelatedQuery {
        Map<String, AfterInsert.RecordsProvider> queryRelatedOnAfterInsert();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerHandler.InsertRecords records);
        String keyOf(SObject record);
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

public class BeforeDelete {
    // Main interfaces - pick one

    public interface Handler {
        Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record);
        void onBeforeDelete(TriggerHandler.DeleteRecord record);
    }

    // Additional interfaces - pick as many as you need

    public interface PriorParentQuery {
        Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeDelete();
    }

    public interface RelatedQuery {
        Map<String, BeforeDelete.RecordsProvider> queryRelatedOnBeforeDelete();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerHandler.DeleteRecords records);
        String keyOf(SObject record);
    }

    public interface Bypassable {
        Boolean bypassOnBeforeDeleteWhen();
    }

    public interface Finalizer {
        void finalizeBeforeDelete(TriggerHandler.DeleteRecords records);
    }

    public interface ContinueOnError {
    }
}

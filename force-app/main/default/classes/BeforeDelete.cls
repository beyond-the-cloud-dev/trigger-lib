public class BeforeDelete {
    public interface Handler {
        Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record);
        void onBeforeDelete(TriggerHandler.DeleteRecord record);
    }

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
        void finalizeBeforeDelete();
    }

    public interface ContinueOnError {
    }
}

public class AfterUndelete {
    public interface Handler {
        Boolean qualifiesForAfterUndeleteWhen(TriggerHandler.UndeleteRecord record);
        void onAfterUndelete(TriggerHandler.UndeleteRecord record);
    }

    public interface ParentQuery {
        Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUndelete();
    }

    public interface RelatedQuery {
        Map<String, AfterUndelete.RecordsProvider> queryRelatedOnAfterUndelete();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerHandler.UndeleteRecords records);
        String keyOf(SObject record);
    }

    public interface Bypassable {
        Boolean bypassOnAfterUndeleteWhen();
    }

    public interface Finalizer {
        void finalizeAfterUndelete();
    }

    public interface ContinueOnError {
    }
}

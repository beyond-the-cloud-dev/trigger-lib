public class AfterUpdate {
    public interface Handler {
        Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record);
        void onAfterUpdate(TriggerHandler.UpdateRecord record);
    }

    public interface ParentQuery {
        Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUpdate();
    }

    public interface PriorParentQuery {
        Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnAfterUpdate();
    }

    public interface RelatedQuery {
        Map<String, AfterUpdate.RecordsProvider> queryRelatedOnAfterUpdate();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerHandler.UpdateRecords records);
        String keyOf(SObject record);
    }

    public interface Bypassable {
        Boolean bypassOnAfterUpdateWhen();
    }

    public interface RecursionGuard {
        Integer maxRecursionDepthOnAfterUpdate();
    }

    public interface Finalizer {
        void finalizeAfterUpdate();
    }

    public interface ContinueOnError {
    }
}

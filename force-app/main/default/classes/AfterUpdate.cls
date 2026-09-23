public class AfterUpdate {
    // Main interfaces - pick one

    public interface Writer extends Handler {
        Boolean writeOnAfterUpdateWhen(TriggerHandler.UpdateRecord record);
        void writeOnAfterUpdate(TriggerHandler.UpdateRecord record, TriggerHandler.UnitOfWork unitOfWork);
    }

    public interface Dispatcher extends Handler {
        Boolean dispatchOnAfterUpdateWhen(TriggerHandler.UpdateRecord record);
        void dispatchOnAfterUpdate(TriggerHandler.UpdateRecords records);
    }

    // Additional interfaces - pick as many as you need

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

    public interface OwnUnitOfWork {
        DML.Committable ownUnitOfWorkOnAfterUpdate();
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

    // For internal use only

    public interface Handler {
    }
}

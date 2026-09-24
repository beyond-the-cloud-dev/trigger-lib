public class AfterUpdate {
    // Roles - pick one

    public interface Writer extends Handler {
        Boolean writeOnAfterUpdateWhen(TriggerTypes.UpdateRecord record);
        void writeOnAfterUpdate(TriggerTypes.UpdateRecord record, TriggerTypes.UnitOfWork unitOfWork);
    }

    public interface Dispatcher extends Handler {
        Boolean dispatchOnAfterUpdateWhen(TriggerTypes.UpdateRecord record);
        void dispatchOnAfterUpdate(TriggerTypes.UpdateRecords records);
    }

    // Add-ons - pick as many as you need

    public interface ParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterUpdate();
    }

    public interface PriorParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnAfterUpdate();
    }

    public interface RelatedQuery {
        Map<String, AfterUpdate.RecordsProvider> queryRelatedOnAfterUpdate();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerTypes.UpdateRecords records);
        String keyOf(SObject row);
    }

    public interface OwnUnitOfWork {
        DML.Committable ownUnitOfWorkOnAfterUpdate();
    }

    public interface Bypassable {
        Boolean bypassOnAfterUpdateWhen();
    }

    public interface RecursionGuard {
        Integer maxRunsPerRecordOnAfterUpdate();
    }

    public interface Finalizer {
        void finalizeOnAfterUpdate(TriggerTypes.UpdateRecords records);
    }

    public interface ContinueOnError {
    }

    // Marker

    public interface Handler {
    }
}

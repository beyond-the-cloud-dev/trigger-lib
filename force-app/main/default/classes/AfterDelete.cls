public class AfterDelete {
    // Roles - pick one

    public interface Writer extends Handler {
        Boolean writeOnAfterDeleteWhen(TriggerTypes.DeleteRecord record);
        void writeOnAfterDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork);
    }

    public interface Dispatcher extends Handler {
        Boolean dispatchOnAfterDeleteWhen(TriggerTypes.DeleteRecord record);
        void dispatchOnAfterDelete(TriggerTypes.DeleteRecords records);
    }

    // Add-ons - pick as many as you need

    public interface PriorParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnAfterDelete();
    }

    public interface RelatedQuery {
        Map<String, AfterDelete.RecordsProvider> queryRelatedOnAfterDelete();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerTypes.DeleteRecords records);
        String keyOf(SObject row);
    }

    public interface OwnUnitOfWork {
        DML.Committable ownUnitOfWorkOnAfterDelete();
    }

    public interface Bypassable {
        Boolean bypassOnAfterDeleteWhen();
    }

    public interface Finalizer {
        void finalizeOnAfterDelete(TriggerTypes.DeleteRecords records);
    }

    public interface ContinueOnError {
    }

    // Marker

    public interface Handler {
    }
}

public class AfterDelete {
    public interface Writer extends Handler {
        Boolean writeOnAfterDeleteWhen(TriggerHandler.DeleteRecord record);
        void writeOnAfterDelete(TriggerHandler.DeleteRecord record, TriggerHandler.UnitOfWork unitOfWork);
    }

    public interface Dispatcher extends Handler {
        Boolean dispatchOnAfterDeleteWhen(TriggerHandler.DeleteRecord record);
        void dispatchOnAfterDelete(TriggerHandler.DeleteRecords records);
    }

    public interface PriorParentQuery {
        Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterDelete();
    }

    public interface RelatedQuery {
        Map<String, AfterDelete.RecordsProvider> queryRelatedOnAfterDelete();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerHandler.DeleteRecords records);
        String keyOf(SObject record);
    }

    public interface OwnUnitOfWork {
        DML.Committable ownUnitOfWorkOnAfterDelete();
    }

    public interface Bypassable {
        Boolean bypassOnAfterDeleteWhen();
    }

    public interface Finalizer {
        void finalizeAfterDelete();
    }

    public interface ContinueOnError {
    }

    public interface Handler {
    }
}

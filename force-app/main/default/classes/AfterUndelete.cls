public class AfterUndelete {
    // Main interfaces - pick one

    public interface Writer extends Handler {
        Boolean writeOnAfterUndeleteWhen(TriggerHandler.UndeleteRecord record);
        void writeOnAfterUndelete(TriggerHandler.UndeleteRecord record, TriggerHandler.UnitOfWork unitOfWork);
    }

    public interface Dispatcher extends Handler {
        Boolean dispatchOnAfterUndeleteWhen(TriggerHandler.UndeleteRecord record);
        void dispatchOnAfterUndelete(TriggerHandler.UndeleteRecords records);
    }

    // Additional interfaces - pick as many as you need

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

    public interface OwnUnitOfWork {
        DML.Committable ownUnitOfWorkOnAfterUndelete();
    }

    public interface Bypassable {
        Boolean bypassOnAfterUndeleteWhen();
    }

    public interface Finalizer {
        void finalizeAfterUndelete();
    }

    public interface ContinueOnError {
    }

    // For internal use only

    public interface Handler {
    }
}

public class AfterInsert {
    public interface Writer extends Handler {
        Boolean writeOnAfterInsertWhen(TriggerHandler.InsertRecord record);
        void writeOnAfterInsert(TriggerHandler.InsertRecord record, TriggerHandler.UnitOfWork unitOfWork);
    }

    public interface Dispatcher extends Handler {
        Boolean dispatchOnAfterInsertWhen(TriggerHandler.InsertRecord record);
        void dispatchOnAfterInsert(TriggerHandler.InsertRecords records);
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

    public interface OwnUnitOfWork {
        DML.Committable ownUnitOfWorkOnAfterInsert();
    }

    public interface Bypassable {
        Boolean bypassOnAfterInsertWhen();
    }

    public interface Finalizer {
        void finalizeAfterInsert();
    }

    public interface ContinueOnError {
    }

    public interface Handler {
    }
}

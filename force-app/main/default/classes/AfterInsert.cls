public class AfterInsert {
    // Roles - pick one

    public interface Writer extends Handler {
        Boolean writeOnAfterInsertWhen(TriggerTypes.InsertRecord record);
        void writeOnAfterInsert(TriggerTypes.InsertRecord record, TriggerTypes.UnitOfWork unitOfWork);
    }

    public interface Dispatcher extends Handler {
        Boolean dispatchOnAfterInsertWhen(TriggerTypes.InsertRecord record);
        void dispatchOnAfterInsert(TriggerTypes.InsertRecords records);
    }

    // Add-ons - pick as many as you need

    public interface ParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterInsert();
    }

    public interface RelatedQuery {
        Map<String, AfterInsert.RecordsProvider> queryRelatedOnAfterInsert();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerTypes.InsertRecords records);
        String keyOf(SObject row);
    }

    public interface OwnUnitOfWork {
        DML.Committable ownUnitOfWorkOnAfterInsert();
    }

    public interface Bypassable {
        Boolean bypassOnAfterInsertWhen();
    }

    public interface Finalizer {
        void finalizeOnAfterInsert(TriggerTypes.InsertRecords records);
    }

    public interface ContinueOnError {
    }

    // Marker

    public interface Handler {
    }
}

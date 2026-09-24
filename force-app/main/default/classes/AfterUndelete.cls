public class AfterUndelete {
    // Roles - pick one

    public interface Writer extends Handler {
        Boolean writeOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record);
        void writeOnAfterUndelete(TriggerTypes.UndeleteRecord record, TriggerTypes.UnitOfWork unitOfWork);
    }

    public interface Dispatcher extends Handler {
        Boolean dispatchOnAfterUndeleteWhen(TriggerTypes.UndeleteRecord record);
        void dispatchOnAfterUndelete(TriggerTypes.UndeleteRecords records);
    }

    // Add-ons - pick as many as you need

    public interface ParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnAfterUndelete();
    }

    public interface RelatedQuery {
        Map<String, AfterUndelete.RecordsProvider> queryRelatedOnAfterUndelete();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerTypes.UndeleteRecords records);
        String keyOf(SObject row);
    }

    public interface OwnUnitOfWork {
        DML.Committable ownUnitOfWorkOnAfterUndelete();
    }

    public interface Bypassable {
        Boolean bypassOnAfterUndeleteWhen();
    }

    public interface Finalizer {
        void finalizeOnAfterUndelete(TriggerTypes.UndeleteRecords records);
    }

    public interface ContinueOnError {
    }

    // Marker

    public interface Handler {
    }
}

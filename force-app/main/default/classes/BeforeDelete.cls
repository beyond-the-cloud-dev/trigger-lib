public class BeforeDelete {
    // Roles - pick one

    public interface Validator extends Handler {
        Boolean addErrorOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record);
        void addErrorOnBeforeDelete(TriggerTypes.RejectableDeleteRecord record);
    }

    public interface Writer extends Handler {
        Boolean writeOnBeforeDeleteWhen(TriggerTypes.DeleteRecord record);
        void writeOnBeforeDelete(TriggerTypes.DeleteRecord record, TriggerTypes.UnitOfWork unitOfWork);
    }

    // Add-ons - pick as many as you need

    public interface PriorParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnBeforeDelete();
    }

    public interface RelatedQuery {
        Map<String, BeforeDelete.RecordsProvider> queryRelatedOnBeforeDelete();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerTypes.DeleteRecords records);
        String keyOf(SObject row);
    }

    public interface OwnUnitOfWork {
        DML.Committable ownUnitOfWorkOnBeforeDelete();
    }

    public interface Bypassable {
        Boolean bypassOnBeforeDeleteWhen();
    }

    public interface Finalizer {
        void finalizeOnBeforeDelete(TriggerTypes.DeleteRecords records);
    }

    public interface ContinueOnError {
    }

    // Marker

    public interface Handler {
    }
}

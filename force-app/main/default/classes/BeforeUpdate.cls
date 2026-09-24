public class BeforeUpdate {
    // Roles - pick one

    public interface Populator extends Handler {
        Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record);
        void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record);
    }

    public interface Validator extends Handler {
        Boolean addErrorOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record);
        void addErrorOnBeforeUpdate(TriggerTypes.RejectableUpdateRecord record);
    }

    // Add-ons - pick as many as you need

    public interface ParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryParentsOnBeforeUpdate();
    }

    public interface PriorParentQuery {
        Map<SObjectField, TriggerTypes.ParentFields> queryPriorParentsOnBeforeUpdate();
    }

    public interface RelatedQuery {
        Map<String, BeforeUpdate.RecordsProvider> queryRelatedOnBeforeUpdate();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerTypes.UpdateRecords records);
        String keyOf(SObject row);
    }

    public interface Bypassable {
        Boolean bypassOnBeforeUpdateWhen();
    }

    public interface RecursionGuard {
        Integer maxRunsPerRecordOnBeforeUpdate();
    }

    public interface Finalizer {
        void finalizeOnBeforeUpdate(TriggerTypes.UpdateRecords records);
    }

    public interface ContinueOnError {
    }

    // Marker

    public interface Handler {
    }
}

public class BeforeUpdate {
    // Main interfaces - pick one

    public interface Populator extends Handler {
        Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record);
        void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record);
    }

    public interface Validator extends Handler {
        Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record);
        String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record);
    }

    // Additional interfaces - pick as many as you need

    public interface ParentQuery {
        Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeUpdate();
    }

    public interface PriorParentQuery {
        Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnBeforeUpdate();
    }

    public interface RelatedQuery {
        Map<String, BeforeUpdate.RecordsProvider> queryRelatedOnBeforeUpdate();
    }

    public interface RecordsProvider {
        List<SObject> query(TriggerHandler.UpdateRecords records);
        String keyOf(SObject record);
    }

    public interface Bypassable {
        Boolean bypassOnBeforeUpdateWhen();
    }

    public interface RecursionGuard {
        Integer maxRecursionDepthOnBeforeUpdate();
    }

    public interface Finalizer {
        void finalizeBeforeUpdate(TriggerHandler.UpdateRecords records);
    }

    public interface ContinueOnError {
    }

    // For internal use only

    public interface Handler {
    }
}

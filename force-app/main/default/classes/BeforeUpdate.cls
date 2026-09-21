public class BeforeUpdate {
    // main interfaces - use one main interface per handler class

    public interface Populator extends Handler {
        Boolean populateOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record);
        void populateOnBeforeUpdate(TriggerHandler.UpdateRecord record);
    }

    public interface Validator extends Handler {
        Boolean errorShouldBeAttachedOnBeforeUpdateWhen(TriggerHandler.UpdateRecord record);
        String beforeUpdateValidationMessage(TriggerHandler.UpdateRecord record);
    }

    // additional interfaces - use as needed

    public interface ParentQuery {
        Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnBeforeUpdate();
    }

    public interface PriorParentQuery {
        Map<SObjectField, TriggerHandler.ParentFields> queryPriorParentsOnBeforeUpdate();
    }

    public interface Bypassable {
        Boolean bypassOnBeforeUpdateWhen();
    }

    public interface RecursionGuard {
        Integer maxRecursionDepthOnBeforeUpdate();
    }

    public interface Finalizer {
        void finalizeBeforeUpdate();
    }

    public interface ContinueOnError {
    }

    // internal

    public interface Handler {
    }
}

public class AfterUpdate {
    public interface Handler {
        Boolean qualifiesForAfterUpdateWhen(TriggerHandler.UpdateRecord record);
        void onAfterUpdate(TriggerHandler.UpdateRecord record);
    }

    public interface NewRecordEnrichment {
        Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterUpdate();
    }

    public interface OldRecordEnrichment {
        Map<SObjectField, TriggerHandler.FieldSelection> oldFieldsToEnrichOnAfterUpdate();
    }

    public interface Bypassable {
        Boolean bypassOnAfterUpdateWhen();
    }

    public interface RecursionGuard {
        Integer maxRecursionDepthOnAfterUpdate();
    }

    public interface Finalizer {
        void finalizeAfterUpdate();
    }

    public interface ContinueOnError {}
}

public class AfterUpdate {
    public interface Handler {
        Boolean qualifiesForAfterUpdateWhen(TriggerHandler.Record record);
        void onAfterUpdate(TriggerHandler.Record record);
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

public class AfterDelete {
    public interface Handler {
        Boolean qualifiesForAfterDeleteWhen(TriggerHandler.Record record);
        void onAfterDelete(TriggerHandler.Record record);
    }

    public interface OldRecordEnrichment {
        Map<SObjectField, TriggerHandler.FieldSelection> oldFieldsToEnrichOnAfterDelete();
    }

    public interface Bypassable {
        Boolean bypassOnAfterDeleteWhen();
    }

    public interface Finalizer {
        void finalizeAfterDelete();
    }

    public interface ContinueOnError {}
}

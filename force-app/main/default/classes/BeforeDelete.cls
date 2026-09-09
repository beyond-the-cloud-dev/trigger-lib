public class BeforeDelete {
    public interface Handler {
        Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.Record record);
        void onBeforeDelete(TriggerHandler.Record record);
    }

    public interface OldRecordEnrichment {
        Map<SObjectField, TriggerHandler.FieldSelection> oldFieldsToEnrichOnBeforeDelete();
    }

    public interface Bypassable {
        Boolean bypassOnBeforeDeleteWhen();
    }

    public interface Finalizer {
        void finalizeBeforeDelete();
    }

    public interface ContinueOnError {}
}

public class BeforeDelete {
    public interface Handler {
        Boolean qualifiesForBeforeDeleteWhen(TriggerHandler.DeleteRecord record);
        void onBeforeDelete(TriggerHandler.DeleteRecord record);
    }

    public interface OldRecordEnrichment {
        Map<SObjectField, TriggerHandler.ParentFields> oldFieldsToEnrichOnBeforeDelete();
    }

    public interface Bypassable {
        Boolean bypassOnBeforeDeleteWhen();
    }

    public interface Finalizer {
        void finalizeBeforeDelete();
    }

    public interface ContinueOnError {
    }
}

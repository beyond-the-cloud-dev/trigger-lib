public class BeforeUndelete {
    public interface Handler {
        Boolean qualifiesForBeforeUndeleteWhen(TriggerHandler.UndeleteRecord record);
        void onBeforeUndelete(TriggerHandler.UndeleteRecord record);
    }

    public interface NewRecordEnrichment {
        Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnBeforeUndelete();
    }

    public interface Bypassable {
        Boolean bypassOnBeforeUndeleteWhen();
    }

    public interface Finalizer {
        void finalizeBeforeUndelete();
    }

    public interface ContinueOnError {}
}

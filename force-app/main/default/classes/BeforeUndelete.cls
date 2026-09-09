public class BeforeUndelete {
    public interface Handler {
        Boolean qualifiesForBeforeUndeleteWhen(TriggerHandler.Record record);
        void onBeforeUndelete(TriggerHandler.Record record);
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

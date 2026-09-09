public class BeforeInsert {
    public interface Handler {
        Boolean qualifiesForBeforeInsertWhen(TriggerHandler.Record record);
        void onBeforeInsert(TriggerHandler.Record record);
    }

    public interface NewRecordEnrichment {
        Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnBeforeInsert();
    }

    public interface Bypassable {
        Boolean bypassOnBeforeInsertWhen();
    }

    public interface Finalizer {
        void finalizeBeforeInsert();
    }

    public interface AllowDmls {}
    public interface ContinueOnError {}
}

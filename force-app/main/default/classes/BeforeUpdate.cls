public class BeforeUpdate {
    public interface Handler {
        Boolean qualifiesForBeforeUpdateWhen(TriggerHandler.Record record);
        void onBeforeUpdate(TriggerHandler.Record record);
    }

    public interface NewRecordEnrichment {
        Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnBeforeUpdate();
    }

    public interface OldRecordEnrichment {
        Map<SObjectField, TriggerHandler.FieldSelection> oldFieldsToEnrichOnBeforeUpdate();
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

    public interface AllowDmls {}

    public interface ContinueOnError {}
}

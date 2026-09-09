public class AfterUndelete {
    public interface Handler {
        Boolean qualifiesForAfterUndeleteWhen(TriggerHandler.Record record);
        void onAfterUndelete(TriggerHandler.Record record);
    }

    public interface NewRecordEnrichment {
        Map<SObjectField, TriggerHandler.FieldSelection> newFieldsToEnrichOnAfterUndelete();
    }

    public interface Bypassable {
        Boolean bypassOnAfterUndeleteWhen();
    }

    public interface Finalizer {
        void finalizeAfterUndelete();
    }

    public interface ContinueOnError {}
}

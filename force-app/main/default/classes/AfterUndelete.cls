public class AfterUndelete {
    public interface Handler {
        Boolean qualifiesForAfterUndeleteWhen(TriggerHandler.UndeleteRecord record);
        void onAfterUndelete(TriggerHandler.UndeleteRecord record);
    }

    public interface NewRecordEnrichment {
        Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterUndelete();
    }

    public interface Bypassable {
        Boolean bypassOnAfterUndeleteWhen();
    }

    public interface Finalizer {
        void finalizeAfterUndelete();
    }

    public interface ContinueOnError {
    }
}

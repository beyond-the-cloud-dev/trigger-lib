public class AfterDelete {
    public interface Handler {
        Boolean qualifiesForAfterDeleteWhen(TriggerHandler.DeleteRecord record);
        void onAfterDelete(TriggerHandler.DeleteRecord record);
    }

    public interface PriorParentQuery {
        Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterDelete();
    }

    public interface Bypassable {
        Boolean bypassOnAfterDeleteWhen();
    }

    public interface Finalizer {
        void finalizeAfterDelete();
    }

    public interface ContinueOnError {
    }
}

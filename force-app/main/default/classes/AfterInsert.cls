public class AfterInsert {
    public interface Handler {
        Boolean qualifiesForAfterInsertWhen(TriggerHandler.InsertRecord record);
        void onAfterInsert(TriggerHandler.InsertRecord record);
    }

    public interface ParentQuery {
        Map<SObjectField, TriggerHandler.ParentFields> queryParentsOnAfterInsert();
    }

    public interface Bypassable {
        Boolean bypassOnAfterInsertWhen();
    }

    public interface Finalizer {
        void finalizeAfterInsert();
    }

    public interface ContinueOnError {
    }
}

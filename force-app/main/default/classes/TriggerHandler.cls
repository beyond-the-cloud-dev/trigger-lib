public with sharing class TriggerHandler {
    public interface BeforeInsert { 
        Boolean isQualifiedBeforeInsert();
        void beforeInsert(List<SObject> newRecords); 
    }

    public interface AfterInsert {
        Boolean isQualifiedAfterInsert();
        void afterInsert(List<SObject> newRecords);
    }

    public interface BeforeUpdate {
        Boolean isQualifiedBeforeUpdate();
        void beforeUpdate(List<SObject> newRecords, List<SObject> oldRecords);
    }

    public interface AfterUpdate {
        Boolean isQualifiedAfterUpdate();
        void afterUpdate(List<SObject> newRecords, List<SObject> oldRecords);
    }

    public interface BeforeDelete {
        Boolean isQualifiedBeforeDelete();
        void beforeDelete(List<SObject> oldRecords);
    }

    public interface AfterDelete {
        Boolean isQualifiedAfterDelete();
        void afterDelete(List<SObject> oldRecords);
    }

    public interface BeforeUndelete {
        Boolean isQualifiedBeforeUndelete();
        void beforeUndelete(List<SObject> newRecords);
    }

    public interface AfterUndelete {
        Boolean isQualifiedAfterUndelete();
        void afterUndelete(List<SObject> newRecords);
    }

    public interface Record {
        Boolean equals(SObjectField field, Object value);
        Boolean doesNotEqual(SObjectField field, Object value); // notEquals  
    }
}
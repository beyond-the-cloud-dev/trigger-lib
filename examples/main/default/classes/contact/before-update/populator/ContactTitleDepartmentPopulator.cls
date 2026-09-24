public with sharing class ContactTitleDepartmentPopulator implements BeforeUpdate.Populator {
    private static final Map<String, String> DEPARTMENT_BY_TITLE = new Map<String, String>{
        'ceo' => 'Executive',
        'chief executive officer' => 'Executive',
        'coo' => 'Operations',
        'chief operating officer' => 'Operations',
        'cfo' => 'Finance',
        'chief financial officer' => 'Finance',
        'controller' => 'Finance',
        'cto' => 'Technology',
        'chief technology officer' => 'Technology',
        'vp of sales' => 'Sales',
        'sales manager' => 'Sales',
        'account executive' => 'Sales',
        'office manager' => 'Administration'
    };

    public Boolean populateOnBeforeUpdateWhen(TriggerTypes.UpdateRecord record) {
        if (!record.isChanged(Contact.Title) || record.isBlank(Contact.Title)) {
            return false;
        }

        Contact newContact = (Contact) record.getNewSObject();

        return ContactTitleDepartmentPopulator.DEPARTMENT_BY_TITLE.containsKey(newContact.Title.trim().toLowerCase());
    }

    public void populateOnBeforeUpdate(TriggerTypes.UpdateRecord record) {
        Contact newContact = (Contact) record.getNewSObject();

        record.put(Contact.Department, ContactTitleDepartmentPopulator.DEPARTMENT_BY_TITLE.get(newContact.Title.trim().toLowerCase()));
    }
}

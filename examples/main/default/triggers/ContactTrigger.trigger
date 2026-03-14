trigger ContactTrigger on Contact(before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    ContactTriggerOrchestrator.run();

    TriggerOrchestrator.run(new ContactTriggerOrchestrator());

    TriggerOrchestrator.run();
}
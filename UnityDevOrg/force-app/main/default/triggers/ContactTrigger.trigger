//added after insert and after update context : Gourav
trigger ContactTrigger on Contact (before insert, after insert, after update) {
    new ContactTriggerHandler().run();
}
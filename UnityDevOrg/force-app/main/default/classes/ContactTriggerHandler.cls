/**
 * @File Name          : ContactTriggerHandler.cls
 * @Description        : 
 * @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Group              : 
 * @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
 * @Last Modified On   : 5/6/2020, 8:53:44 am
 * @Modification Log   : 
 * Ver       Date            Author                 Modification
 * 1.0    5/6/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public class ContactTriggerHandler extends TriggerHandler{
    private List<Contact> newContactList;
    private Map<Id, Contact> oldContactMap;
    private final static String COMMA_SEPARATOR = ',';
	private Set<String> objectsTypeToByPassList;    
    
    public ContactTriggerHandler() {
        newContactList = (List<Contact>) Trigger.new;
        oldContactMap = (Map<Id, Contact>) Trigger.oldMap;
        if(String.isNotBlank(GlobalBypassProcessesSettings__c.getInstance().TriggerObjectsBypass__c))
        {
        	objectsTypeToByPassList =  new Set<String>(GlobalBypassProcessesSettings__c.getInstance().TriggerObjectsBypass__c.split(COMMA_SEPARATOR));             
        }
    }
    
    protected override void beforeInsert() {
        for(Contact contact : newContactList){
            //if GUID field is not blank do not update the field
            if(String.isBlank(contact.Guid__c)){
                contact.Guid__c = GuidUtilityClass.newGuid(); //Generate UUID v4 to use in integration
            }
        }
    } 

    protected override void afterInsert() {
        //Retrieve additional data to see if the Account is already synced with ERP
        List<Contact> queryContactList = ContactTriggerHelper.getContactDetails(newContactList);
        //For all Contacts with an Account synced with ERP -> update SendToERP field to true. This will trigger the AfterUpdate and send out the ContactChangeDataEvent
       	ContactTriggerHelper.updateSendAndResendToERP(queryContactList);  
    }
    
    protected override void afterUpdate() {
        List<Contact> contactList = new List<Contact>();
        //Retrieve additional data to see if any relevant data has been changed as well as if the Contact is already synced with ERP
        List<Contact> queryContactList = ContactTriggerHelper.getContactDetails(newContactList);
        for(Contact contact : queryContactList){
            //field that is part of the interface is updated on Contact
            if(contact.SendToERP__c &&
               (contact.Email != oldContactMap.get(contact.Id).Email || contact.Fax != oldContactMap.get(contact.Id).Fax ||
                contact.FirstName != oldContactMap.get(contact.Id).FirstName || contact.Inactive__c != oldContactMap.get(contact.Id).Inactive__c ||
                contact.Title != oldContactMap.get(contact.Id).Title || contact.MiddleName != oldContactMap.get(contact.Id).MiddleName ||
                contact.LastName != oldContactMap.get(contact.Id).LastName || contact.MobilePhone != oldContactMap.get(contact.Id).MobilePhone ||
                contact.Phone != oldContactMap.get(contact.Id).Phone || contact.OwnerId != oldContactMap.get(contact.Id).OwnerId ||
                contact.SendToERP__c != oldContactMap.get(contact.Id).SendToERP__c || contact.ResendToERP__c)){
                    contactList.add(contact);
                }
        }
        //Only trigger platform event if ContactChangDateEvent object is not bypassesd
        if(objectsTypeToByPassList == null || !objectsTypeToByPassList.contains('ContactChangeDataEvent__e')){
        	ContactTriggerHelper.fireContactChangeDataEvt(contactList);
        	ContactTriggerHelper.updateSendAndResendToERP(contactList);             
        }       
    }
}
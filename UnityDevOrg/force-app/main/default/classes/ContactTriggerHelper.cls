/**
* @File Name          : ContactTriggerHelper.cls
* @Description        : 
* @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
* @Group              : 
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 5/6/2020, 9:06:26 am
* @Modification Log   : 
* Ver       Date            Author      		    Modification
* 1.0    5/6/2020   ChangeMeIn@UserSettingsUnder.SFDoc     Initial Version
**/
public without sharing class ContactTriggerHelper {
    
    public static void updateSendAndResendToERP(List<Contact> contactList){
        for(Contact contact : contactList){
            if(!contact.SendToERP__c || contact.ResendToERP__c){
                contact.ResendToERP__c = false;
                contact.SendToERP__c = true;
            }
        }

        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult[] srList = Database.update(contactList, dml);

        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully updated contact. Contact ID: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Contact fields that affected this error: ' + err.getFields());
                }
            }
        }
    }
    
    public static void fireContactChangeDataEvt(List<Contact> contactList){
        List<ContactChangeDataEvent__e> contactChangeDataEventList = new List<ContactChangeDataEvent__e>();
        //Build the Contact Change Data Events
        for(Contact contact : contactList){
            ContactChangeDataEvent__e contactChangeDataEvent = new ContactChangeDataEvent__e(AccountGuid__c = contact.Account.Guid__c,
                                                                                             AccountId__c = contact.AccountId,
                                                                                             AccountRecordType__c = contact.TF_AccountRecordType__c,
                                                                                             CompanyCode__c = contact.Account.Company__r.CompanyCode__c,
                                                                                             Email__c = contact.Email,
                                                                                             ERPNumber__c = contact.ERPContactNumber__c,
                                                                                             Fax__c = contact.Fax,
                                                                                             FirstName__c = contact.FirstName,
                                                                                             Guid__c = contact.Guid__c,
                                                                                             Id__c = contact.Id,
                                                                                             Inactive__c = contact.Inactive__c,
                                                                                             JobTitle__c = contact.Title,
                                                                                             LastName__c = contact.LastName,
                                                                                             MiddleName__c = contact.MiddleName,
                                                                                             MobilePhone__c = contact.MobilePhone,
                                                                                             Phone__c = contact.Phone,
                                                                                             SalespersonCode__c = contact.Owner.SalespersonCode__c);
            contactChangeDataEventList.add(contactChangeDataEvent);
        }
        //fire platform event
        if(!contactChangeDataEventList.isEmpty()){
            try{
                EventBus.publish(contactChangeDataEventList);
                system.debug('Event published');
            }
            catch(Exception ex){
                system.debug('Event publish exception');
            }
        }
    }
    
    public static List<Contact> getContactDetails(List<Contact> contactList){
        //Retrieve all the data needed to check for relevant updates. 
        //Only those contacts will be returned which have an Account that is synced with ERP
        List<Contact> contactDetailList = [Select Account.Guid__c, AccountId, TF_AccountRecordType__c, 
                                           Account.Company__r.CompanyCode__c, Email, ERPContactNumber__c, Fax, FirstName,Guid__c, 
                                           Id, Account.AccountNumber, Inactive__c, Title, LastName, MiddleName, MobilePhone, 
                                           Phone, Owner.SalespersonCode__c, ResendToERP__c, SendToERP__c from Contact 
                                           where Id IN :contactList and Account.AccountNumber != null];
        return contactDetailList;
    }
}
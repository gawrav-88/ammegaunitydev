/*------------------------------------------------------------------------------------------------------------------------  
Author:        Salesforce Services  
Company:       Salesforce   
Description:   Test class for the Account Trigger Handler
Inputs:        None 
Test Class:    ContactTriggerHandlerTest     
------------------------------------------------------------------------------------------------------------------------*/
@isTest(SeeAllData=false)
public with sharing class ContactTriggerHandlerTest {
    
    @testSetup static void setup() {
        test.startTest();
        //Create the custom setting GlobalBypassProcessesSettings__c
        GlobalBypassProcessesSettings__c globalBypass = new GlobalBypassProcessesSettings__c();
        globalBypass.RunAssignmentsRules__c = true;
        globalBypass.RunFlows__c = true;
        globalBypass.RunProcessBuilder__c = true;
        globalBypass.RunTriggers__c = true;
        globalBypass.RunValidationRules__c = true;
        globalBypass.RunWorkflowsRules__c = true;
        globalBypass.TriggerObjectsBypass__c = 'true';
        try{
            insert globalBypass;
        }catch(Exception e){
            System.debug('Error while inserting custom setting GlobalBypassProcessesSettings__c in AccountTriggerHandlerTest: '+e.getMessage());
        }
        //Account
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('StrategicAccount').getRecordTypeId();
        Id accSubmittedProspectRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('SubmittedProspect').getRecordTypeId();
        //Account account = (Account) TestFactory.createSObject(new Account(), true);
        Account[] accountListNew = (Account[])TestFactory.createSObjectList(new Account(), 2);
        for(Account acc1 : accountListNew){
            acc1.BillingCity = 'Toronto';
            acc1.BillingCountry = 'Canada';
            acc1.BillingStreet = 'Station Street';
            acc1.BillingPostalCode = 'M5J';
        }
        accountListNew[0].RecordTypeId = accRecordTypeId;
        accountListNew[1].RecordTypeId = accSubmittedProspectRecordTypeId;
        /*Account account = (Account) TestFactory.createSObject(new Account());
        account.BillingCity = 'Toronto';
        account.BillingCountry = 'Canada';
        account.BillingStreet = 'Station Street';
        account.BillingPostalCode = 'M5J';
        account.RecordTypeId = accRecordTypeId;
        //added accountNumber to test SendToERP functionality: Gourav
        account.AccountNumber = 'Account1234567890';*/
        try{
            insert accountListNew;
        }catch(Exception e){
            System.debug('Error while inserting Account in ContactTriggerHandlerTest.validGuidAssigned(): '+e.getMessage());
        }
        //Contacts
        Contact contactMaster = (Contact) TestFactory.createSObject(new Contact(AccountID = accountListNew[0].Id));
        List<Contact> contactListNew = new List<Contact>();
        for(Integer i = 0; i < 200; i++) {
            Contact contactClone = contactMaster.clone();
            contactListNew.add(contactClone);
        }
        
        Contact contactERPTest = (Contact) TestFactory.createSObject(new Contact(AccountID = accountListNew[1].Id));
        for(Integer i = 0; i < 50; i++) {
            Contact contactClone1 = contactERPTest.clone();
            contactListNew.add(contactClone1);
        }
        
        //Ignore duplicate rules
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true; 
        
        Database.SaveResult[] srList = Database.insert(contactListNew, dml);
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors               
                for(Database.Error err : sr.getErrors()) {                  
                    System.debug('The following error has occurred : '+err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                }
            }
        }
        test.stopTest();
    }
    
    private static testmethod void validGuidAssigned() {
        //Pattern of valid Guid
        Pattern p = Pattern.compile('[\\w]{8}-[\\w]{4}-4[\\w]{3}-[89ab][\\w]{3}-[\\w]{12}');

        //Retrieve Contacts just created
        List<Contact> contactList = [SELECT Guid__c FROM Contact /*WHERE Id in :contactListNew*/];
		system.debug('contactList.size()-->'+contactList.size());
        //Check all accounts have been created                                                         
        System.assert(contactList.size() == 250, 'Not all created contacts in query result');

        //Check valid Guids have been assigned for each account                                                          
        for(Contact contact: contactList) {
            Matcher m = p.matcher(contact.Guid__c);
            System.assert(m.matches() == true);
            System.debug(contact.Guid__c);
        }
    }
    
    private static testmethod void afterUpdateOfAccountTest(){
        test.startTest();
        List<Account> accList = [Select id, RecordTypeId, AccountNumber from Account where RecordType.DeveloperName = 'SubmittedProspect'];
        system.debug('accList-->'+accList.size()+' details-->'+accList);
        for(Account acc : accList){
            //updating accountNumber so that contact is sent to ERP
            acc.AccountNumber = 'Account1234567890';
        }
         //Ignore duplicate rules
        Database.DMLOptions dml1 = new Database.DMLOptions();
        dml1.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult[] srList = Database.update(accList, dml1);
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors               
                for(Database.Error err : sr.getErrors()) {                  
                    System.debug('The following error has occurred : '+err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                }
            }
        }
        
        
        List<Contact> createdContactList = [Select Account.Guid__c, AccountId, TF_AccountRecordType__c, 
                                           Account.Company__r.CompanyCode__c, Email, ERPContactNumber__c, Fax, FirstName,Guid__c, 
                                           Id, Account.AccountNumber, Inactive__c, Title, LastName, MiddleName, MobilePhone, 
                                           Phone, Owner.SalespersonCode__c, ResendToERP__c, SendToERP__c from Contact where AccountId in :accList];
        system.debug('createdContactList-->'+createdContactList.size()+' Contact Details-->'+createdContactList);
        for(Contact cont : createdContactList){
            //contact sendToERP should be true as account number has value in it
            system.assertEquals(cont.SendToERP__c, true);
            system.assertEquals(cont.ResendToERP__c, false);
            //updating ResendToERP in contact, this should trigger the event
            cont.ResendToERP__c = true;
        }
        
        //Ignore duplicate rules
        Database.DMLOptions dml2 = new Database.DMLOptions();
        dml2.DuplicateRuleHeader.AllowSave = true;
        Database.SaveResult[] srList1 = Database.update(createdContactList, dml2);
        for (Database.SaveResult sr : srList1) {
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors               
                for(Database.Error err : sr.getErrors()) {                  
                    System.debug('The following error has occurred : '+err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                }
            }
        }
        
        List<Contact> updatedContactList = [Select Account.Guid__c, AccountId, TF_AccountRecordType__c, 
                                           Account.Company__r.CompanyCode__c, Email, ERPContactNumber__c, Fax, FirstName,Guid__c, 
                                           Id, Account.AccountNumber, Inactive__c, Title, LastName, MiddleName, MobilePhone, 
                                           Phone, Owner.SalespersonCode__c, ResendToERP__c, SendToERP__c from Contact where AccountId in :accList];
        
        for(Contact co : updatedContactList){
            system.debug('co.ResendToERP__c-->'+co.ResendToERP__c);
            system.assertEquals(co.ResendToERP__c, false);
        }
        
        Contact conta = new Contact(AccountId = accList[0].id,
                                   LastName = 'Test Create',
                                   Email = 'Test@invalidtest.com',
                                   Fax = '123456789',
                                   FirstName = 'Some Test');
        
        try{
            insert conta;
            system.debug('Contact insert successfull');
        }catch(Exception ex){
            system.debug('Exception in inserting contact-->'+ex.getMessage());
        }
        
        Contact contact11 = [Select AccountId, Email, Fax, FirstName,Guid__c, 
                             Id, Inactive__c, Title, LastName, MiddleName, MobilePhone, 
                             Phone, ResendToERP__c, SendToERP__c from Contact where Id = :conta.id];
        system.assertEquals(true, contact11.SendToERP__c);
        
        test.stopTest();
    }
}
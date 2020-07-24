/*------------------------------------------------------------------------------------------------------------------------	
Author:        Salesforce Services	
Company:       Salesforce	
Description:   Test class for the Account Trigger Handler
Inputs:        None	
Test Class:    AccountTriggerHandlerTest	 
------------------------------------------------------------------------------------------------------------------------*/
@isTest(SeeAllData=false)
public class AccountTriggerHandlerTest { 
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
        //Create Accounts
        Account[] accountListNew = (Account[])TestFactory.createSObjectList(new Account(), 200);
        List<Account> topParentAccountToInsertList = new List<Account>();
        List<Account> accountToInsertList = new List<Account>();
        List<Account> accountToInsertList1 = new List<Account>();
        List<Account> accountToInsertList2 = new List<Account>();
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('StrategicAccount').getRecordTypeId();
        system.debug('accRecordTypeId-->'+accRecordTypeId);
        
        //adding billing address details to staisfy the 'ShippingAddressFilledUponAccountCreation' validation rule
        for(Integer i = 0; i <= 24; i++){
            accountListNew[i].BillingCity = 'Toronto';
            accountListNew[i].BillingCountry = 'Canada';
            accountListNew[i].BillingStreet = 'Station Street'+i;
            accountListNew[i].BillingPostalCode = 'M5J'+i;
            accountListNew[i].RecordTypeId = accRecordTypeId;
            topParentAccountToInsertList.add(accountListNew[i]);
        }
        for(Integer i = 25; i <= 49; i++){
            accountListNew[i].BillingCity = 'Toronto';
            accountListNew[i].BillingCountry = 'Canada';
            accountListNew[i].BillingStreet = 'Station Street'+i;
            accountListNew[i].BillingPostalCode = 'M5J'+i;
            topParentAccountToInsertList.add(accountListNew[i]);
        }
        //insert topParentAccountToInsertList;  
        Database.SaveResult[] srList = Database.insert(topParentAccountToInsertList, false);
        
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors               
                for(Database.Error err : sr.getErrors()) {                  
                    System.debug('The following error has occurred : '+err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                }
            }
        }
        for(Integer i = 50; i <= 99; i++){
            accountListNew[i].BillingCity = 'Amsterdam';
            accountListNew[i].BillingCountry = 'Netherlands';
            accountListNew[i].BillingStreet = 'Amstelveenseweg'+i;
            accountListNew[i].BillingPostalCode = '1081KL'+i;
            accountListNew[i].ParentId = topParentAccountToInsertList[i-50].id;
            accountToInsertList.add(accountListNew[i]);
        }
        //insert accountToInsertList;  
        Database.SaveResult[] srList1 = Database.insert(accountToInsertList, false);
        
        for (Database.SaveResult sr : srList1) {
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors               
                for(Database.Error err : sr.getErrors()) {                  
                    System.debug('The following error has occurred : '+err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                }
            }
        }
        
        for(Integer i = 100; i <= 149; i++){
            accountListNew[i].BillingCity = 'Starkville';
            accountListNew[i].BillingCountry = 'United States';
            accountListNew[i].BillingStreet = 'Station Lane'+i;
            accountListNew[i].BillingPostalCode = '39759'+i;
            accountListNew[i].ParentId = accountToInsertList[i-100].id;
            accountToInsertList1.add(accountListNew[i]);
        }
        //insert accountToInsertList1;  
        Database.SaveResult[] srList2 = Database.insert(accountToInsertList1, false);
        
        for (Database.SaveResult sr : srList2) {
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors              
                for(Database.Error err : sr.getErrors()) {                  
                    System.debug('The following error has occurred : '+err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                }
            }
        }
        
        for(Integer i = 150; i <= 199; i++){
            accountListNew[i].BillingCity = 'Utrecht';
            accountListNew[i].BillingCountry = 'Netherlands';
            accountListNew[i].BillingStreet = 'Kees van Bohemenhof'+i;
            accountListNew[i].BillingPostalCode = '3544MC'+i;
            accountListNew[i].ParentId = accountToInsertList[i-150].id;
            accountToInsertList2.add(accountListNew[i]);
        }
        
        //insert accountListNew;  
        Database.SaveResult[] srList3 = Database.insert(accountToInsertList2, false);
        
        for (Database.SaveResult sr : srList3) {
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
        
        //Retrieve Accounts just created
        List<Account> accountList = [SELECT Guid__c, ParentId, TopParent__c, IsTopParentStrategicAccount__c, IsStrategicAccount__c FROM Account /*WHERE Id in :accountListNew*/];
        //Check all accounts have been created                                                         
        System.assert(accountList.size() == 200, 'Not all created accounts in query result');
        System.debug(accountList.size());
        //Check valid Guids have been assigned for each account                                                          
        for(Account account: accountList) {
            Matcher m = p.matcher(account.Guid__c);
            System.assert(m.matches() == true);
        }
    }
    private static testmethod void beforeUpdateTest() {
        List<Id> strategicTopParentAccountIDsList = new List<Id>();
        List<Id> nonStrategicTopParentAccountIdsList = new List<Id>();
        List<Account> childAccountsList = new List<Account>();
        
        //Retrieve Accounts just created
        List<Account> accountList = [SELECT Id, ParentId, Parent.IsStrategicAccount__c, TopParent__c, IsTopParentStrategicAccount__c, IsStrategicAccount__c, SendToERP__c FROM Account ];
        system.assertEquals(accountList.size(), 200);
        for(Account acc : accountList){
            if(acc.IsStrategicAccount__c && acc.ParentId == null){
                strategicTopParentAccountIDsList.add(acc.Id);
            }else if(!acc.IsStrategicAccount__c && acc.ParentId == null){
                nonStrategicTopParentAccountIdsList.add(acc.Id);
            }else{
                childAccountsList.add(acc);
            }
        }
        
        system.assertEquals(strategicTopParentAccountIDsList.size(), 25);
        system.assertEquals(nonStrategicTopParentAccountIdsList.size(), 25);
        
        List<Account> accToUpdateList = new List<Account>();
        test.startTest();
        //change strategic parent accounts to non-strategic parent accounts
        accToUpdateList = [Select Id, ParentId, Parent.IsStrategicAccount__c, SendToERP__c, ResendToERP__c from Account where ParentId != null and Parent.IsStrategicAccount__c = true];
        
        system.assertEquals(accToUpdateList.size(), 25);
        for(Integer i = 0; i < 25; i++){
            //system.debug('accToUpdateList[i].SendToERP__c-->'+accToUpdateList[i].SendToERP__c);
            accToUpdateList[i].ParentId = nonStrategicTopParentAccountIdsList[i];
        }
        Database.SaveResult[] srList = Database.update(accToUpdateList, false);
        //update the 25 accounts from strategic parents to non-strategic parents
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors              
                for(Database.Error err : sr.getErrors()) {                  
                    System.debug('The following error has occurred : '+err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                }
            }
        }
        /*Assert that the list of child accounts with strategic parent accounts is 0
		*as the functionality trickles down to all levels of child account*/
        List<Account> updatedAccountList = [SELECT Id, ParentId, TopParent__c, IsTopParentStrategicAccount__c, IsStrategicAccount__c, SendToERP__c, ResendToERP__c FROM Account WHERE ParentId != null and IsTopParentStrategicAccount__c = true];
        system.assertEquals(0,updatedAccountList.size());        
        //clear the list for reuse
        accToUpdateList.clear();
        
        //Change non-strategic parent accounts to strategic parent accounts
        accToUpdateList = [Select Id, ParentId, Parent.IsStrategicAccount__c, Parent.ParentId, SendToERP__c, ResendToERP__c from Account where ParentId != null and Parent.IsStrategicAccount__c = false and Parent.ParentId = null];
        
        system.assertEquals(accToUpdateList.size(), 50);
        if(accToUpdateList.size() > 0){
            for(Integer i = 0; i < 25; i++){
                accToUpdateList[i].ParentId = strategicTopParentAccountIDsList[i];
            }
        }
        
        
        Database.SaveResult[] saveResultList = Database.update(accToUpdateList, false);
        //update the 25 accounts from strategic parents to non-strategic parents
        for (Database.SaveResult sr : saveResultList) {
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors               
                for(Database.Error err : sr.getErrors()) {                  
                    System.debug('The following error has occurred : '+err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                }
            }
        }
        
        /*Assert that the list of child accounts with strategic parent accounts is 75(3 levels of 25 accounts each)
		*as the functionality trickles down to all levels of child account*/
        List<Account> updatedAccountNewList = [SELECT Id, ParentId, TopParent__c, IsTopParentStrategicAccount__c, IsStrategicAccount__c, SendToERP__c, ResendToERP__c, RecordType.Name FROM Account WHERE ParentId != null and IsTopParentStrategicAccount__c = true];
        system.assert(updatedAccountNewList.size() == 75,'Not all child account is updated with strategic parent');
        test.stopTest();
    }
    
    private static testmethod void afterUpdateTest(){
        List<Account> accList = new List<Account>();
        test.startTest();
        //Query the accounts
        for(Account acc : [Select id, Name, RecordTypeId, SendToERP__c, ResendToERP__c from Account where RecordType.DeveloperName = 'Prospect' limit 50]){
            acc.SendToERP__c = true;
            //acc.ResendToERP__c = true;
            accList.add(acc);
        }
        Database.SaveResult[] saveResultList = Database.update(accList, false);
        //update the accounts 
        for (Database.SaveResult sr : saveResultList) {
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors               
                for(Database.Error err : sr.getErrors()) {                  
                    System.debug('The following error has occurred : '+err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                }
            }
        }
        List<Account> updatedAccList = [Select id, Name, RecordTypeId, SendToERP__c, ResendToERP__c from Account where RecordType.DeveloperName = 'SubmittedProspect' and SendToERP__c=true];
        system.debug('accList size-->'+updatedAccList.size());
        system.assertEquals(50, updatedAccList.size());
        for(Account acc11 : updatedAccList){
            system.assertEquals(acc11.ResendToERP__c, false);
            acc11.ResendToERP__c = true;
        }
        Database.SaveResult[] saveResultList1 = Database.update(updatedAccList, false);
        //update the accounts 
        for (Database.SaveResult sr : saveResultList1) {
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors               
                for(Database.Error err : sr.getErrors()) {                  
                    System.debug('The following error has occurred : '+err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                }
            }
        }
        for(Account acc12 : [Select id, Name, RecordTypeId, SendToERP__c, ResendToERP__c from Account where id in :updatedAccList]){
            system.assertEquals(acc12.ResendToERP__c, false);
        }
        test.stopTest();
    }
}
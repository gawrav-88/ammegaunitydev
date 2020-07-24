/*------------------------------------------------------------------------------------------------------------------------	
Author:        	Gourav	
Company:       	Salesforce	
Description:   	Test class for the ExternalDocumentRenderController
                As the functionality is not applicable for mass action
                the test class is not bulkified and we created bare minimum records for testing
Inputs:        	None	 
------------------------------------------------------------------------------------------------------------------------*/
@isTest(SeeAllData=false)
public class ExternalDocumentRenderControllerTest { 
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
        //Create Company
        Company__c testCompany = new Company__c(Name = 'AB Test INC (CA)',
                                                CompanyCode__c = 'CAOC01',
                                                CurrencyIsoCode = 'CAD',
                                                DebtCollector__c = 'test@test.com',
                                                NamedCredentialsPDFCallout__c = 'testpdf',
                                                BaseURLOrderViewer__c = 'http://test:1234/test',
                                                BaseURLQuoteViewer__c = 'http://test:1234/test',
                                                BaseDocumentViewerURL__c = '',
                                                BaseDocumentUploadURL__c = '');
        
        try{
            insert testCompany;
            system.debug('Company inserted successfully');
        }catch(Exception e){
            system.debug('Exception in inserting company-->'+e.getMessage());
        }
        //Create Accounts
        Account[] accountListNew = (Account[])TestFactory.createSObjectList(new Account(), 2);
        
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
        system.debug('accRecordTypeId-->'+accRecordTypeId);
        
        //adding billing address details to staisfy the 'ShippingAddressFilledUponAccountCreation' validation rule
        for(Integer i=0; i<accountListNew.size(); i++){
            accountListNew[i].BillingCity = 'Toronto';
            accountListNew[i].BillingCountry = 'Canada';
            accountListNew[i].BillingStreet = 'Station Street'+i;
            accountListNew[i].BillingPostalCode = 'M5J'+i;
            accountListNew[i].RecordTypeId = accRecordTypeId;
            accountListNew[i].Company__c = testCompany.id;
        }
        
        //insert accountListNew;  
        Database.SaveResult[] srList = Database.insert(accountListNew, false);
        system.debug('Inserted Accounts-->'+accountListNew);
        
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors               
                for(Database.Error err : sr.getErrors()) {                  
                    System.debug('The following error has occurred : '+err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                }
            }
        }
        
        //create orders : Orders are created seperately and not in 'for' loop because ShowDocumentLink__c 
        //				  should be true for one and false for the other
        List<Order__c> testOrderList = new List<Order__c>();
        Order__c testOrder1 = new Order__c(Name = 'TestOrder 0',
                                           CurrencyISOCode = 'EUR',
                                           ShowDocumentLink__c = true,
                                           Account__c = accountListNew[0].id);
        testOrderList.add(testOrder1);
        
        Order__c testOrder2 = new Order__c(Name = 'TestOrder 1',
                                           CurrencyISOCode = 'EUR',
                                           ShowDocumentLink__c = false,
                                           Account__c = accountListNew[1].id);
        testOrderList.add(testOrder2);
        
        //insert testOrderList;  
        Database.SaveResult[] srOrderList = Database.insert(testOrderList, false);
        system.debug('Inserted Orders-->'+testOrderList);
        
        for (Database.SaveResult sr : srOrderList) {
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors               
                for(Database.Error err : sr.getErrors()) {                  
                    System.debug('The following error has occurred : '+err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                }
            }
        }
        
        //create quote
        List<Quote__c> testQuoteList = new List<Quote__c>();
        for(Integer k = 0; k<2; k++){
            Quote__c testQuote = new Quote__c(Name = 'TestQuote '+k,
                                              Type__c = 'Sales',
                                              ShowDocumentLink__c = true,
                                              Account__c = accountListNew[k].id);
            testQuoteList.add(testQuote);
        }
        
        //insert testQuoteList;  
        Database.SaveResult[] srQuoteList = Database.insert(testQuoteList, false);
        system.debug('Inserted Quotes-->'+testQuoteList);
        
        for (Database.SaveResult sr : srQuoteList) {
            if (!sr.isSuccess()) {
                // Operation failed, so get all errors               
                for(Database.Error err : sr.getErrors()) {                  
                    System.debug('The following error has occurred : '+err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                }
            }
        }
        
        //create file for quote
        String documentReference = 'GeneratedDocument-TestQuote 1';
        ContentVersion cv = new ContentVersion(
            ContentLocation = 'S',
            FirstPublishLocationId = testQuoteList[1].id, // Set the relation to the parent record
            VersionData = blob.toPdf('This is a test string'),
            Title = documentReference,
            PathOnClient = documentReference + '.pdf' // Hardcoded pdf as for now we only handle pdf with this document generation service
        );
        try{
            insert cv;
            system.debug('ContentVersion inserted successfully');
        }catch(Exception e){
            system.debug('Error in insertig contentversion-->'+e.getMessage());
        }
        test.stopTest();        
    }
    
    private static testmethod void getOrderDocumentPositiveTest() {
        
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new HTTPFilePositiveMockCallout());
        test.startTest();
        Id returnedId;
        Set<Id> contentDocumentIdSet = new Set<Id>();
        List<Order__c> insertedTestOrderList = [Select id from Order__c where Account__r.Name = 'TestFactory Account 0'];
        List<ContentDocumentLink> existingDocumentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :insertedTestOrderList[0].id];
        for(ContentDocumentLink documentLink : existingDocumentLinks){
            contentDocumentIdSet.add(documentLink.ContentDocumentId);
        }
        List<ContentDocument> existingDocumentsList = [SELECT Id, Title FROM ContentDocument WHERE Id IN :contentDocumentIdSet];
        //Assert that there are no exosting documents associated to the record
        system.assertEquals(existingDocumentsList.size(), 0);
        if(insertedTestOrderList.size() > 0){
            returnedId =  ExternalDocumentRenderController.getDocumentId(insertedTestOrderList[0].id);
        }
        List<ContentDocumentLink> existingDocumentLinksAfterRun = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :insertedTestOrderList[0].id];
        contentDocumentIdSet.clear();
        for(ContentDocumentLink documentLink1 : existingDocumentLinksAfterRun){
            contentDocumentIdSet.add(documentLink1.ContentDocumentId);
        }
        List<ContentDocument> existingDocumentsListAfterRun = [SELECT Id, Title FROM ContentDocument WHERE Id IN :contentDocumentIdSet];
        system.assertEquals(existingDocumentsListAfterRun.size(), 1);
        system.assertEquals(returnedId, existingDocumentLinksAfterRun[0].ContentDocumentId);
        test.stopTest();
        
    }
    
    private static testmethod void getQuoteDocumentPositiveTest() {
        
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new HTTPFilePositiveMockCallout());
        test.startTest();
        Set<Id> contentDocumentIdSet = new Set<Id>();
        Id returnedId;
        List<Quote__c> insertedTestQuoteList = [Select id from Quote__c where Account__r.Name = 'TestFactory Account 0'];
        List<ContentDocumentLink> existingDocumentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :insertedTestQuoteList[0].id];
        for(ContentDocumentLink documentLink : existingDocumentLinks){
            contentDocumentIdSet.add(documentLink.ContentDocumentId);
        }
        List<ContentDocument> existingDocumentsList = [SELECT Id, Title FROM ContentDocument WHERE Id IN :contentDocumentIdSet];
        //Assert that there are no exosting documents associated to the record
        system.assertEquals(existingDocumentsList.size(), 0);
        system.debug('Inserted quote-->'+insertedTestQuoteList);
        if(insertedTestQuoteList.size() > 0){
            returnedId=ExternalDocumentRenderController.getDocumentId(insertedTestQuoteList[0].id);
        }
        List<ContentDocumentLink> existingDocumentLinksAfterRun = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :insertedTestQuoteList[0].id];
        contentDocumentIdSet.clear();
        for(ContentDocumentLink documentLink : existingDocumentLinksAfterRun){
            contentDocumentIdSet.add(documentLink.ContentDocumentId);
        }
        List<ContentDocument> existingDocumentsListAfterRun = [SELECT Id, Title FROM ContentDocument WHERE Id IN :contentDocumentIdSet];
        //Assert file is created
        system.assertEquals(existingDocumentsListAfterRun.size(), 1);
        system.assertEquals(returnedId, existingDocumentLinksAfterRun[0].ContentDocumentId);
        test.stopTest();
        
    }
    
    private static testmethod void getQuoteDocumentPositiveWithFileTest() {
        
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new HTTPFilePositiveMockCallout());
        test.startTest();
        Set<Id> contentDocumentIdSet = new Set<Id>();
        List<Quote__c> insertedTestQuoteList = [Select id from Quote__c where Account__r.Name = 'TestFactory Account 1'];
        List<ContentDocumentLink> existingDocumentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :insertedTestQuoteList[0].id];
        for(ContentDocumentLink documentLink : existingDocumentLinks){
            contentDocumentIdSet.add(documentLink.ContentDocumentId);
        }
        List<ContentDocument> existingDocumentsList = [SELECT Id, Title FROM ContentDocument WHERE Id IN :contentDocumentIdSet];
        //Assert that there are no existing documents associated to the record
        system.assertEquals(existingDocumentsList.size(), 1);
        if(insertedTestQuoteList.size() > 0){
            ExternalDocumentRenderController.getDocumentId(insertedTestQuoteList[0].id);
        }
        List<ContentDocumentLink> existingDocumentLinksAfterRun = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :insertedTestQuoteList[0].id];
        contentDocumentIdSet.clear();
        for(ContentDocumentLink documentLink1 : existingDocumentLinksAfterRun){
            ContentDocumentIdSet.add(documentLink1.ContentDocumentId);
        }
        List<ContentDocument> existingDocumentsListAfterRun = [SELECT Id, Title FROM ContentDocument WHERE Id IN :contentDocumentIdSet];
        system.debug('ContentDocumentIdSet-->'+ContentDocumentIdSet);
        system.assertEquals(existingDocumentsListAfterRun.size(), 1);
        test.stopTest();
        
    }
    
    private static testmethod void getOrderDocumentNegativeTest() {
        Exception unexpectedException;
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new HTTPFileNegativeMockCallout());
        test.startTest();
        List<Order__c> insertedTestOrderList = [Select id from Order__c where Account__r.Name = 'TestFactory Account 0'];
        system.debug('Inserted order-->'+insertedTestOrderList);
        if(insertedTestOrderList.size() > 0){
            try{
                ExternalDocumentRenderController.getDocumentId(insertedTestOrderList[0].id);
            }catch(Exception aex){
                unexpectedException=aex;
            }
            system.debug('unexpectedException :'+unexpectedException);
            system.assertEquals(AuraHandledException.class.getName(), unexpectedException.getTypeName(), 'AuraHandledException is expected');
        }
        test.stopTest();
    }
    
    private static testmethod void unimplementedObjectTest() {
        Exception idMismatchException;
        test.startTest();
        List<Account> createdAccountList = [Select Id from Account];
        if(createdAccountList.size() > 0){
            try{
                ExternalDocumentRenderController.getDocumentId(createdAccountList[0].id);
            }catch(Exception aex){
                idMismatchException=aex;
            }
            system.assertEquals(AuraHandledException.class.getName(), idMismatchException.getTypeName(), 'AuraHandledException is expected');
        }
        test.stopTest();
    }
    //testing callout exceptions
    private static testmethod void getOrderDocumentPosStatusNegBodyTest() {
        Exception unexpectedException;
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new HTTPPosStatusMockWithNegBodyCallout());
        test.startTest();
        List<Order__c> insertedTestOrderList = [Select id from Order__c where Account__r.Name = 'TestFactory Account 0'];
        system.debug('Inserted order-->'+insertedTestOrderList);
        if(insertedTestOrderList.size() > 0){
            try{
                ExternalDocumentRenderController.getDocumentId(insertedTestOrderList[0].id);
            }catch(Exception aex){
                unexpectedException=aex;
            }
            system.debug('unexpectedException :'+unexpectedException);
            system.assertEquals(AuraHandledException.class.getName(), unexpectedException.getTypeName(), 'AuraHandledException is expected');
        }
        test.stopTest();
    }
    //testing ShowDocumentLink__c functionality
    private static testmethod void getOrderDocumentWithoutPermissionTest() {
        Exception unexpectedException;
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new HTTPFilePositiveMockCallout());
        test.startTest();
        List<Order__c> insertedTestOrderList = [Select id,ShowDocumentLink__c from Order__c where Name = 'TestOrder 1'];
        system.debug('Inserted order-->'+insertedTestOrderList);
        if(insertedTestOrderList.size() > 0){
            try{
                ExternalDocumentRenderController.getDocumentId(insertedTestOrderList[0].id);
            }catch(Exception aex){
                unexpectedException=aex;
            }
            system.debug('unexpectedException :'+unexpectedException);
            system.assertEquals(AuraHandledException.class.getName(), unexpectedException.getTypeName(), 'AuraHandledException is expected');
        }
        test.stopTest();
    }
}
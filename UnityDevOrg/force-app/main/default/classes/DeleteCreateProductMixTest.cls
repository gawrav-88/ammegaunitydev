/*------------------------------------------------------------------------------------------------------------------------	
Author:        	Gourav	
Company:       	Salesforce	
Description:   	Test class for the DeleteCreateProductMix
                As the functionality is not applicable for mass action
                the test class is not bulkified and we created bare minimum records for testing
Inputs:        	None	
Test Class:    	DeleteCreateProductMixTest	 
------------------------------------------------------------------------------------------------------------------------*/
@isTest(SeeAllData=false)
public class DeleteCreateProductMixTest {
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
        //Create Company with ProductMixCategory populated
        List<Company__c> companyListToCreate = new List<Company__c>();
        Company__c testCompany1 = new Company__c(Name = 'AB Test INC (CA)',
                                                CompanyCode__c = 'CAOC01',
                                                CurrencyIsoCode = 'CAD',
                                                DebtCollector__c = 'test@test.com',
                                                NamedCredentialsPDFCallout__c = 'testpdf',
                                                BaseURLOrderViewer__c = 'http://test:1234/test',
                                                BaseURLQuoteViewer__c = 'http://test:1234/test',
                                                BaseDocumentViewerURL__c = '',
                                                BaseDocumentUploadURL__c = '',
                                               	ProductMixCategory__c = 'A');
        
        companyListToCreate.add(testCompany1);
        
        //Create Company without ProductMixCategory populated
        Company__c testCompany2 = new Company__c(Name = 'AB Test INC (CAJ)',
                                                CompanyCode__c = 'CAOC02',
                                                CurrencyIsoCode = 'CAD',
                                                DebtCollector__c = 'test@test.com',
                                                NamedCredentialsPDFCallout__c = 'testpdf',
                                                BaseURLOrderViewer__c = 'http://test:1234/test',
                                                BaseURLQuoteViewer__c = 'http://test:1234/test',
                                                BaseDocumentViewerURL__c = '',
                                                BaseDocumentUploadURL__c = '',
                                               	ProductMixCategory__c = null);
        
        companyListToCreate.add(testCompany2);
        try{
            insert companyListToCreate;
            system.debug('Company inserted successfully');
        }catch(Exception e){
            system.debug('Exception in inserting company-->'+e.getMessage());
        }
        //Create Accounts
        Account[] accountListNew = (Account[])TestFactory.createSObjectList(new Account(), 2);
        
        Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();
        system.debug('accRecordTypeId-->'+accRecordTypeId);
        
        //adding billing address details to staisfy the 'ShippingAddressFilledUponAccountCreation' validation rule
        for(Integer i=0; i<accountListNew.size(); i++){
            accountListNew[i].BillingCity = 'Toronto';
            accountListNew[i].BillingCountry = 'Canada';
            accountListNew[i].BillingStreet = 'Station Street'+i;
            accountListNew[i].BillingPostalCode = 'M5J'+i;
            accountListNew[i].RecordTypeId = accRecordTypeId;
            accountListNew[i].Company__c = testCompany1.id;
            accountListNew[i].CurrencyIsoCode = 'EUR';
            accountListNew[i].PrimaryIndustry__c = '100000';
            
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
        
        //create Product mix and associate them with one of the created accounts
        List<Productmix__c> prodMixList = new List<Productmix__c>();    
        Productmix__c newProductMix1 = new Productmix__c(Account__c = accountListNew[1].id,
                                                        MainProductGroup__c = 'MB',
                                                        CurrencyISOCode = accountListNew[1].CurrencyIsoCode,
                                                        Percentage__c = 20);
        prodMixList.add(newProductMix1);
        
        Productmix__c newProductMix2 = new Productmix__c(Account__c = accountListNew[1].id,
                                                        MainProductGroup__c = 'TD',
                                                        CurrencyISOCode = accountListNew[1].CurrencyIsoCode,
                                                        Percentage__c = 60);
        prodMixList.add(newProductMix2);
        
        Productmix__c newProductMix3 = new Productmix__c(Account__c = accountListNew[1].id,
                                                        MainProductGroup__c = 'OTH',
                                                        CurrencyISOCode = accountListNew[1].CurrencyIsoCode,
                                                        Percentage__c = 20);
        prodMixList.add(newProductMix3);
        
        
        //insert prodMixList;  
        Database.SaveResult[] srProdMixList = Database.insert(prodMixList, false);
        
        for (Database.SaveResult sr : srProdMixList) {
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
    
    private static testmethod void accInsertWithoutProdMixTest() {
        test.startTest();
        List<Account> accountList = [SELECT Id, Name, Company__r.ProductMixCategory__c, PrimaryIndustry__c, CurrencyIsoCode FROM Account WHERE Name = 'TestFactory Account 0'];
        //List<Productmix__c> insertedProdMixList = [Select Id, Account__c, MainProductGroup__c, Amount__c, CurrencyISOCode, Percentage__c from Productmix__c where Account__c = :accountList[0].Id];
        List<Productmix__c> insertedProdMixList = [Select MainProductGroup__c, Amount__c, CurrencyISOCode, Percentage__c from Productmix__c where Account__c = :accountList[0].Id];
        
        /* to check count of product mix records
         * List<ProductMixProductGroup__mdt> prodMixInd = [Select id, MainProductGroup__c, Percentage__c from ProductMixProductGroup__mdt
         * 													where ProductMixIndustry__r.ProductMixCategory__c = 'A' and ProductMixIndustry__r.Industry__c = '100000'];
         * 											OR
         * 
         */ List<ProductMixIndustry__mdt> prodMixInd = [Select id, ProductMixCategory__c, Industry__c, 
                                            (Select id, MainProductGroup__c, Percentage__c from Product_Mix_Product_Group__r) 
                                            from ProductMixIndustry__mdt where ProductMixCategory__c='A' and Industry__c = '100000'];
          	String ind = '100000';
            map<String, List<ProductMixProductGroup__mdt>> indProdMixGrpMap = new map<String, List<ProductMixProductGroup__mdt>>();
            for(ProductMixIndustry__mdt prdMix : prodMixInd){
                
                indProdMixGrpMap.put(prdMix.Industry__c, prdMix.Product_Mix_Product_Group__r);
            }
            system.debug('1.-->'+indProdMixGrpMap.get(accountList[0].PrimaryIndustry__c).size());
            system.debug('2.-->'+indProdMixGrpMap.get(ind));
         	system.assertEquals(insertedProdMixList.size(), indProdMixGrpMap.get(accountList[0].PrimaryIndustry__c).size());
         
        
        //Assert that 3 productmix records were created when account was inserted
        //List<ProductMixProductGroup__mdt> prodMixInd = [Select id, MainProductGroup__c, Percentage__c from ProductMixProductGroup__mdt
         													//where ProductMixIndustry__r.ProductMixCategory__c = 'A' and ProductMixIndustry__r.Industry__c = '100000'];
        //system.assertEquals(insertedProdMixList.size(), 3);
        system.debug('prodMixInd-->'+prodMixInd.size());
        //system.assertEquals(insertedProdMixList.size(), prodMixInd.size());
        system.assertEquals(accountList[0].CurrencyIsoCode, insertedProdMixList[0].CurrencyIsoCode);
        test.stopTest();        
    }
    
    private static testmethod void accUpdateWithProdMixTest() {
        test.startTest();
        List<Account> accountList = [SELECT Id, Name, Company__r.ProductMixCategory__c, PrimaryIndustry__c, CurrencyIsoCode FROM Account WHERE Name = 'TestFactory Account 1'];
        //check the existing product mix records when account was inserted
        List<Productmix__c> existingProdMixList = [Select Id, Account__c, MainProductGroup__c, Amount__c, CurrencyISOCode, Percentage__c from Productmix__c where Account__c = :accountList[0].Id];       
        system.assertEquals(100, existingProdMixList[0].Percentage__c+existingProdMixList[1].Percentage__c+existingProdMixList[2].Percentage__c);
        //update account's company so exiting product mixes will be deleted and new will be created
        accountList[0].PrimaryIndustry__c = '130000';
        try{
            update accountList[0];
        }catch(Exception e){
            system.debug('Exception in account update : '+e.getMessage());
        }
        List<Productmix__c> insertedProdMixList = [Select Id, Account__c, MainProductGroup__c, Amount__c, CurrencyISOCode, Percentage__c from Productmix__c where Account__c = :accountList[0].Id];
        //Assert 3 different Product mix records are created after the update
        List<ProductMixIndustry__mdt> prodMixInd = [Select id, ProductMixCategory__c, Industry__c, 
                                            (Select id, MainProductGroup__c, Percentage__c from Product_Mix_Product_Group__r) 
                                            from ProductMixIndustry__mdt where ProductMixCategory__c='A' and Industry__c = '130000'];
          	String ind = '130000';
            map<String, List<ProductMixProductGroup__mdt>> indProdMixGrpMap = new map<String, List<ProductMixProductGroup__mdt>>();
            for(ProductMixIndustry__mdt prdMix : prodMixInd){
                
                indProdMixGrpMap.put(prdMix.Industry__c, prdMix.Product_Mix_Product_Group__r);
            }
            system.debug('1.-->'+indProdMixGrpMap.get(accountList[0].PrimaryIndustry__c).size());
            system.debug('2.-->'+indProdMixGrpMap.get(ind));
         	system.assertEquals(insertedProdMixList.size(), indProdMixGrpMap.get(accountList[0].PrimaryIndustry__c).size());
        //system.assertEquals(insertedProdMixList.size(), 3);
        system.assertEquals(100, insertedProdMixList[0].Percentage__c+insertedProdMixList[1].Percentage__c+insertedProdMixList[2].Percentage__c);
        test.stopTest();        
    }
    
    private static testmethod void accUpdateCompanyChangeTest() {
        test.startTest();
        Company__c newCompany = [Select Id, Name, ProductMixCategory__c from Company__c where ProductMixCategory__c = '' limit 1];
        List<Account> accountList = [SELECT Id, Name, Company__r.ProductMixCategory__c, Company__r.name, PrimaryIndustry__c, CurrencyIsoCode FROM Account WHERE Name = 'TestFactory Account 1'];
        //check number of existing product mixes
        List<Productmix__c> existingProdMixList = [Select Id, Account__c, MainProductGroup__c, Amount__c, CurrencyISOCode, Percentage__c from Productmix__c where Account__c = :accountList[0].Id];
        //assert count of existing product mixes is 6(3 created when Account was created and 3 inserted by test setup)
        system.assertEquals(existingProdMixList.size(), 6);
            
        //update account with company which doesn't have productMixCategory filled
        accountList[0].Company__c = newCompany.id;
        accountList[0].BillingCity = 'Vancouver';
        accountList[0].BillingCountry = 'Canada';
        accountList[0].BillingStreet = 'Station Street'+10;
        accountList[0].BillingPostalCode = 'M5J'+09;
        accountList[0].PrimaryIndustry__c = '130000';
        try{
            update accountList[0];
            system.debug('Account update successful');
        }catch(Exception e){
            system.debug('Exception in account update : '+e.getMessage());
        }
        List<Account> updatedAccountList = [SELECT Id, Name, Company__r.ProductMixCategory__c, Company__r.name, PrimaryIndustry__c, CurrencyIsoCode FROM Account WHERE Name = 'TestFactory Account 1'];
        //check number of product mixes after account update
        List<Productmix__c> insertedProdMixList = [Select Id, Account__c, MainProductGroup__c, Amount__c, CurrencyISOCode, Percentage__c from Productmix__c where Account__c = :accountList[0].Id];
        //assert number of product mixes is 0 as compant for the corresponding account does not have productMixCategory filled
        system.assertEquals(insertedProdMixList.size(), 0);
        test.stopTest();        
    }
}
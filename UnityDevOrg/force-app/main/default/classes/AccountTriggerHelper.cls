/**
* @File Name          : ContactTriggerHelper.cls
* @Description        : 
* @Author             : ChangeMeIn@UserSettingsUnder.SFDoc
* @Group              : 
* @Last Modified By   : ChangeMeIn@UserSettingsUnder.SFDoc
* @Last Modified On   : 9/6/2020, 10:06:26 am
* @Modification Log   : 
* Ver       Date            Author                  Modification
* 1.0    11/12/2019   Vincent Van Keulen            Initial Version
* 1.1    9/6/2020     Gourav                        Modified version for firing events
**/
public without sharing class AccountTriggerHelper {
    
    public static Map<Id,Account> getTopParentAccountInfo(List<Account> accounts) {
        Set<Id> accountIds = new Set<Id>();

        //Build list of account ids to query
        for(Account account : accounts){
            if( account.ParentId != null && Trigger.isBefore && Trigger.isInsert ){
                accountIds.add(account.ParentId); //Before Insert we can go up to the parent and retrieve the needed Top Parent info from there
            } else if ( account.TopParent__c != account.TF_TopParent__c ){
                accountIds.add(account.TF_TopParent__c); //Before Update we can immediately retrieve the info from the Top Parent itself
            } 
        }        

        //Return the attributes needed of the collected Parent accounts as a Map
        return new Map<Id,Account>([SELECT Id, TopParent__c, IsTopParentStrategicAccount__c, IsStrategicAccount__c FROM Account WHERE Id in:accountIds]);      
    } 
    
    //Start Fire accountChangeDataEvent : Gourav
    public static void fireAccountChangeDataEvt(List<Account> newAccountList){
        List<Account> accountList = new List<Account>();
        List<AccountChangeDataEvent__e> acctChangeDataEvtList = new List<AccountChangeDataEvent__e>();
        for(Account account : newAccountList){
            //Create a platform event for each account updated and publish
            AccountChangeDataEvent__e acctChgEvt = new AccountChangeDataEvent__e(AccountRecordType__c = account.TF_AccountRecordType__c,
                                                                                 BillingCity__c = account.BillingCity,
                                                                                 BillingCountryCode__c = account.BillingCountryCode,
                                                                                 BillingStateCode__c = account.BillingStateCode,
                                                                                 BillingStreet__c = account.BillingStreet,
                                                                                 BillingPostalCode__c = account.BillingPostalCode,
                                                                                 BranchCode__c = account.Branch__r.BranchCode__c,
                                                                                 CommunicationLanguage__c = account.CommunicationLanguage__c,
                                                                                 CompanyCode__c = account.Company__r.CompanyCode__c,
                                                                                 CompanyCurrencyIsoCode__c = account.Company__r.IntegrationDefaultCurrency__c,
                                                                                 CurrencyIsoCode__c = account.CurrencyIsoCode,
                                                                                 Email__c = account.Email__c,
                                                                                 ERPNumber__c = account.AccountNumber,
                                                                                 Fax__c = account.Fax,
                                                                                 Guid__c = account.Guid__c,
                                                                                 Id__c = account.Id,
                                                                                 Inactive__c = account.Inactive__c,
                                                                                 InsideSalespersonCode__c = account.InsideSales__r.SalespersonCode__c,
                                                                                 InsideSalespersonCodeERPField1__c = account.InsideSales__r.AdditionalERPCodeField1__c,
                                                                                 MainClassification__c = account.MainClassification__c,
                                                                                 Name__c = account.Name,
                                                                                 Phone__c = account.Phone,
                                                                                 PrimaryContactEmail__c = account.PrimaryContact__r.Email,
                                                                                 PrimaryContactERPNumber__c = account.PrimaryContact__r.ERPContactNumber__c,
                                                                                 PrimaryContactFax__c = account.PrimaryContact__r.Fax,
                                                                                 PrimaryContactFirstName__c = account.PrimaryContact__r.FirstName,
                                                                                 PrimaryContactGuid__c = account.PrimaryContact__r.Guid__c,
                                                                                 PrimaryContactId__c = account.PrimaryContact__c,
                                                                                 PrimaryContactInactive__c = account.PrimaryContact__r.Inactive__c,
                                                                                 PrimaryContactJobTitle__c = account.PrimaryContact__r.Title,
                                                                                 PrimaryContactLastName__c = account.PrimaryContact__r.LastName,
                                                                                 PrimaryContactMiddleName__c = account.PrimaryContact__r.MiddleName,
                                                                                 PrimaryContactMobilePhone__c = account.PrimaryContact__r.MobilePhone,
                                                                                 PrimaryContactPhone__c = account.PrimaryContact__r.Phone,
                                                                                 PrimaryContactSalespersonCode__c = account.PrimaryContact__r.Owner.SalespersonCode__c,
                                                                                 PrimaryContactSalespersonCodeERPField1__c = account.PrimaryContact__r.Owner.AdditionalERPCodeField1__c,
                                                                                 PrimarySegment__c = account.PrimarySegment__c,
                                                                                 RealizedRevenueClassification__c = account.RealizedRevenueClassification__c,
                                                                                 SalespersonCode__c = account.Owner.SalespersonCode__c,
                                                                                 SalespersonCodeERPFIeld1__c = account.Owner.AdditionalERPCodeField1__c,
                                                                                 SubType__c = account.SubType__c,
                                                                                 Type__c = account.Type,
                                                                                 Website__c = account.Website);
            acctChangeDataEvtList.add(acctChgEvt);
                                                                         
            if(account.ResendToERP__c || account.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId()){
                if (account.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId()){
                    account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('SubmittedProspect').getRecordTypeId();
                }
                account.ResendToERP__c = false;
                accountList.add(account);
            }
        }
        //fire platform event
        if(!acctChangeDataEvtList.isEmpty()){
            try{
                EventBus.publish(acctChangeDataEvtList);
                system.debug('Event published');
            }
            catch(Exception ex){
                system.debug('Event publish exception');
            }
        }
        //If there are account with ResendToERP as true, make them false
        if(!accountList.isEmpty()){
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.AllowSave = true;
            Database.SaveResult[] srList = Database.update(accountList, dml);
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    //System.debug('Successfully updated account. Account ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Account fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
    }
    //End Fire accountChangeDataEvent and update ResendToERP: Gourav
    
    public static void updateChildAccounts(Map<Id,Account> oldAccountMap, Map<Id,Account> newAccountMap){
        Set<Id> updatedAccountsWithTopParent = new Set<Id>();
        List<Account> childAccountsToUpdate = new List<Account>();

        //If the Top Parent of the Account has changed, trickle down the changes to its childs
        for(Account oldAccount : oldAccountMap.values()){
            if ( oldAccount.TopParent__c != newAccountMap.get(oldAccount.Id).TopParent__c ){
                updatedAccountsWithTopParent.add(oldAccount.Id);
            }
        }

        //Trickle down the Top Parent change, retrieve all Child Accounts and update them
        for(Account parentAccount : [SELECT Id, (SELECT Id FROM ChildAccounts) FROM Account WHERE Id in :updatedAccountsWithTopParent]){
            for(Account childAccount : parentAccount.ChildAccounts){
                childAccount.TopParent__c = newAccountMap.get(parentAccount.Id).TopParent__c;
                childAccount.IsTopParentStrategicAccount__c = newAccountMap.get(parentAccount.Id).IsTopParentStrategicAccount__c;
                childAccountsToUpdate.add(childAccount);
            }
        }
        update childAccountsToUpdate;        
    }  
    
    public static List<Account> getAccountDetails(List<Account> accountList){
        List<Account> accountDetailList = [Select SendToERP__c, ResendToERP__c, RecordTypeId, BillingCity, BillingCountryCode, BillingStateCode, BillingStreet, 
                                           BillingPostalCode, Branch__r.BranchCode__c, CommunicationLanguage__c, TF_AccountRecordType__c,
                                           Company__r.CompanyCode__c, Company__r.IntegrationDefaultCurrency__c, CurrencyIsoCode, 
                                           Email__c, AccountNumber, Fax, Guid__c, Id, Inactive__c,    
                                           InsideSales__r.SalespersonCode__c, InsideSales__r.AdditionalERPCodeField1__c, 
                                           MainClassification__c, Name, Phone, PrimaryContact__r.Email, 
                                           PrimaryContact__r.ERPContactNumber__c, PrimaryContact__r.Fax, 
                                           PrimaryContact__r.FirstName, PrimaryContact__r.Guid__c, PrimaryContact__c, 
                                           PrimaryContact__r.Inactive__c, PrimaryContact__r.Title, PrimaryContact__r.LastName, 
                                           PrimaryContact__r.MiddleName, PrimaryContact__r.MobilePhone, PrimaryContact__r.Phone, 
                                           PrimaryContact__r.Owner.SalespersonCode__c, 
                                           PrimaryContact__r.Owner.AdditionalERPCodeField1__c, PrimarySegment__c, 
                                           RealizedRevenueClassification__c, Owner.SalespersonCode__c, 
                                           Owner.AdditionalERPCodeField1__c, SubType__c, Type, Website from Account where Id IN :accountList];
        return accountDetailList;
    }
}
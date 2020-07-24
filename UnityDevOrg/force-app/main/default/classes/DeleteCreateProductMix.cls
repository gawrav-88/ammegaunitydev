/*------------------------------------------------------------------------------------------------------------------------	
Author:        Gourav	
Company:       Salesforce	
Description:   This class deletes existing product mix for an account and creates new product mix records based on 
               ProductMixProductGroup__mdt metadata type
               Use this Invocable class in conjunction with account process builder. 
               Criteria: OR(NOT(ISNEW() ), ISCHANGED([Account].PrimaryIndustry__c ), 
						 ISCHANGED([Account].CurrencyIsoCode ), ISCHANGED([Account].Company__c ) ) 
               If Criteria is met, the Action Group should invoke the 'Delete and Create Product Mix for Industry Change'
Inputs:        Collection of Account ids	
Test Class:    DeleteCreateProductMixTest	 
---------------------------------------------------------------------------------------------------------------------------*/
global without sharing class DeleteCreateProductMix {
    @InvocableMethod(label='Delete and Create Product Mix for Industry Change')
    global static void DeleteCreateProdMix(List<ID> acctIdList) { 
        //Create a savepoint at the start
		Savepoint sp = Database.setSavepoint();
        //Get list of Product mixes for the account
        List<ProductMix__c> prodMixList = [Select Id from ProductMix__c where Account__c IN :acctIdList];
        // Delete the ProductMix__c records if available
        if(!prodMixList.isEmpty()){
            try{
                delete prodMixList;
            }catch(Exception e){
                throw new DMLException('Unable to delete existing ProductMix records');
            }
        }
        //Create the new ProductMix records as per custom metadata
        List<Account> acctList = [Select Id, CurrencyIsoCode, PrimaryIndustry__c, Company__r.ProductMixCategory__c, Company__c from Account where Id IN :acctIdList];
        List<ProductMix__c> toInsertProductMixList = new List<ProductMix__c>();

        List<ProductMixProductGroup__mdt> productGroupList = [Select MasterLabel, MainProductGroup__c, Percentage__c, ProductMixIndustry__r.Masterlabel, 
                                                              ProductMixIndustry__r.Industry__c, ProductMixIndustry__r.ProductMixCategory__c 
                                                              from ProductMixProductGroup__mdt];
        for(Account acc : acctList){
            //User Story#000497: Create ProductMix records if Account's company has ProductMixCategory populated
            if(!productGroupList.isEmpty() && String.isNotBlank(acc.Company__r.ProductMixCategory__c)){
                for(ProductMixProductGroup__mdt prodMT : productGroupList){
                    if(String.isNotBlank(acc.PrimaryIndustry__c) && 
                       acc.PrimaryIndustry__c == prodMT.ProductMixIndustry__r.Industry__c && 
                       acc.Company__r.ProductMixCategory__c == prodMT.ProductMixIndustry__r.ProductMixCategory__c){
                           Productmix__c newProductMix = new Productmix__c(Account__c = acc.id,
                                                                           MainProductGroup__c = prodMT.MainProductGroup__c,
                                                                           CurrencyISOCode = acc.CurrencyIsoCode,
                                                                           Percentage__c = prodMT.Percentage__c);
                           toInsertProductMixList.add(newProductMix);
                       }
                }
            }else{return;}
        }
        if(!toInsertProductMixList.isEmpty()){
            //Insert new ProductMix records
            try{
                insert toInsertProductMixList;
            }catch(Exception dmlExec){
                Database.rollback(sp);
                throw new DMLException('Unable to create new ProductMix records');
            }
        }
    }
}
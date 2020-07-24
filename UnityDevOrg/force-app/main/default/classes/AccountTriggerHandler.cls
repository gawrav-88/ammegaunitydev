public class AccountTriggerHandler extends TriggerHandler{
    private List<Account> newAccountList;
    private Map<Id,Account> oldAccountMap;
    private Map<Id,Account> newAccountMap;
    private final static String COMMA_SEPARATOR = ',';
	private Set<String> objectsTypeToByPassList;    
    
    public AccountTriggerHandler() {
        newAccountList = (List<Account>) Trigger.new;
        oldAccountMap = (Map<Id, Account>) Trigger.oldMap;
        newAccountMap = (Map<Id, Account>) Trigger.newMap;
        if(String.isNotBlank(GlobalBypassProcessesSettings__c.getInstance().TriggerObjectsBypass__c))
        {
        	objectsTypeToByPassList =  new Set<String>(GlobalBypassProcessesSettings__c.getInstance().TriggerObjectsBypass__c.split(COMMA_SEPARATOR));             
        }        
    }
    
    protected override void beforeInsert() {
        //Retrieve Parent Account Info
        Map<Id,Account> parentAccountMap = AccountTriggerHelper.getTopParentAccountInfo(newAccountList);

        for(Account account : newAccountList){
            //if GUID field is not blank do not update the field
            if(String.isBlank(account.Guid__c)){
                //Generate UUID v4 to use in integration
                account.Guid__c = GuidUtilityClass.newGuid();
            }
             

            //Set the Top Parent to the Top Parent of the Parent 
            //or to the Parent itself if the Parent does not have a Top Parent
            if( parentAccountMap.containsKey(account.ParentId)){
                account.TopParent__c = ( parentAccountMap.get(account.ParentId).TopParent__c != null ) ? parentAccountMap.get(account.ParentId).TopParent__c : parentAccountMap.get(account.ParentId).Id;
                account.IsTopParentStrategicAccount__c = ( parentAccountMap.get(account.ParentId).TopParent__c != null ) ? parentAccountMap.get(account.ParentId).IsTopParentStrategicAccount__c : parentAccountMap.get(account.ParentId).IsStrategicAccount__c;
            }
        }
    }
    protected override void beforeUpdate() {
        //Retrieve Top Parent Account Info
        Map<Id,Account> topParentAccountMap = AccountTriggerHelper.getTopParentAccountInfo(newAccountList);        

        for(Account account : newAccountList){
            //If needed update the Top Parent Lookup
            if( account.TopParent__c != account.TF_TopParent__c ){
                account.TopParent__c = account.TF_TopParent__c;
                if( topParentAccountMap.containsKey(account.TF_TopParent__c) ) {
                    account.IsTopParentStrategicAccount__c = topParentAccountMap.get(account.TF_TopParent__c).IsStrategicAccount__c;
                } else {
                    account.IsTopParentStrategicAccount__c = false;
                }
            }
        }
    }

    protected override void afterUpdate(){
        List<Account> accountList = new List<Account>();
        
        //Only trigger platform event if AccountChangDateEvent object is not bypassesd
        if(objectsTypeToByPassList == null || !objectsTypeToByPassList.contains('AccountChangeDataEvent__e')){        
            //Queried Account to get values of Primary Contact
            for(Account account:AccountTriggerHelper.getAccountDetails(newAccountList)){
                if(account.SendToERP__c && (account.SendToERP__c != oldAccountMap.get(account.id).SendToERP__c ||
                   account.RealizedRevenueClassification__c != oldAccountMap.get(account.id).RealizedRevenueClassification__c ||
                   account.Branch__c != oldAccountMap.get(account.id).Branch__c ||
                   account.Inactive__c != oldAccountMap.get(account.id).Inactive__c ||
                   account.InsideSales__c != oldAccountMap.get(account.id).InsideSales__c ||
                   account.PrimaryContact__c != oldAccountMap.get(account.id).PrimaryContact__c ||
                   account.PrimarySegment__c != oldAccountMap.get(account.id).PrimarySegment__c ||
                   account.OwnerId != oldAccountMap.get(account.id).OwnerId ||
                   account.Type != oldAccountMap.get(account.id).Type ||
                   account.SubType__c != oldAccountMap.get(account.id).SubType__c ||
                   account.MainClassification__c != oldAccountMap.get(account.id).MainClassification__c ||
                   account.ResendToERP__c )){
                   	accountList.add(account);
            	}
            }
            
            AccountTriggerHelper.fireAccountChangeDataEvt(accountList);
        }
        
        //Update Top Parent changes to the Child Accounts
        AccountTriggerHelper.updateChildAccounts(oldAccountMap, newAccountMap);
    }
}
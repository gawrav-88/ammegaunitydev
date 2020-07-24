public class FireAccountEventClass {
    @AuraEnabled
    public static string insertData(String strFromCSV)
    {
        String returnresponse ='';
        //List<Account> AccoutnListtoInsert = new List<Account>();
        List<Account> AccountListToInsert = new List<Account>();
        
        List<AccountChangeDataEvent__e> accChngDataEvtList = new List<AccountChangeDataEvent__e>();
        
        system.debug('@@@ strFromCSV -->' + strFromCSV);
        List<fieldWrapper> evtList = (List<fieldWrapper>) JSON.deserialize(strFromCSV, List<fieldWrapper>.class);
        system.debug('@@@ evtList -->' + evtList);
        system.debug('@@@ evtList Size -->' + evtList.size());
        for(fieldWrapper wrapper: evtList){
            AccountChangeDataEvent__e accChEvt = new AccountChangeDataEvent__e();
            
            accChEvt.AccountRecordType__c = wrapper.AccountRecordType;
            accChEvt.BillingCity__c = wrapper.BillingCity;
            accChEvt.BillingCountryCode__c = wrapper.BillingCountryCode;
            accChEvt.BillingStateCode__c = wrapper.BillingStateCode;
            accChEvt.BillingStreet__c = wrapper.BillingStreet;
            accChEvt.BillingPostalCode__c = wrapper.BillingPostalCode;
            accChEvt.BranchCode__c = wrapper.BranchCode;
            accChEvt.CommunicationLanguage__c = wrapper.CommunicationLanguage;
            accChEvt.CompanyCode__c = wrapper.CompanyCode;
            accChEvt.CompanyCurrencyIsoCode__c = wrapper.CompanyCurrencyIsoCode;
            accChEvt.CurrencyIsoCode__c = wrapper.CurrencyIsoCode;
            accChEvt.Email__c = wrapper.Email;
            accChEvt.ERPNumber__c = wrapper.ERPNumber;
            accChEvt.Fax__c = wrapper.Fax;
            accChEvt.Guid__c = wrapper.Guid;
            accChEvt.Id__c = wrapper.Id;
            accChEvt.Inactive__c = wrapper.Inactive;
            accChEvt.InsideSalespersonCode__c = wrapper.InsideSalespersonCode;
            accChEvt.MainClassification__c = wrapper.MainClassification;
            accChEvt.Name__c = wrapper.Name;
            accChEvt.Phone__c = wrapper.Phone;
            accChEvt.PrimaryContactEmail__c = wrapper.PrimaryContactEmail;
            accChEvt.PrimaryContactERPNumber__c = wrapper.PrimaryContactERPNumber;
            accChEvt.PrimaryContactFax__c = wrapper.PrimaryContactFax;
            accChEvt.PrimaryContactFirstName__c = wrapper.PrimaryContactFirstName;
            accChEvt.PrimaryContactGuid__c = wrapper.PrimaryContactGuid;
            accChEvt.PrimaryContactId__c = wrapper.PrimaryContactId;
            accChEvt.PrimaryContactInactive__c = wrapper.PrimaryContactInactive;
            accChEvt.PrimaryContactJobTitle__c = wrapper.PrimaryContactJobTitle;
            accChEvt.PrimaryContactLastName__c = wrapper.PrimaryContactLastName;
            accChEvt.PrimaryContactMiddleName__c = wrapper.PrimaryContactMiddleName;
            accChEvt.PrimaryContactMobilePhone__c = wrapper.PrimaryContactMobilePhone;
            accChEvt.PrimaryContactPhone__c = wrapper.PrimaryContactPhone;
            accChEvt.PrimaryContactSalespersonCode__c = wrapper.PrimaryContactSalespersonCode;
            accChEvt.PrimarySegment__c = wrapper.PrimarySegment;
            accChEvt.RealizedRevenueClassification__c = wrapper.RealizedRevenueClassification;
            accChEvt.SalespersonCode__c = wrapper.SalespersonCode;
            accChEvt.SubType__c = wrapper.SubType;
            accChEvt.Type__c = wrapper.Type;
            accChEvt.Website__c = wrapper.Website;
            accChngDataEvtList.add(accChEvt);
            
        }
        if(!accChngDataEvtList.isEmpty()){
            try{
                EventBus.publish(accChngDataEvtList);
                returnresponse = 'SUCCESS';
                system.debug('Event published');
            }
            catch(Exception ex){
                returnresponse = 'ERROR';
                system.debug('Event publish exception');
            }
        }
        return returnresponse;
    }
    
    public class fieldWrapper {
        public String AccountRecordType;
        public String BillingCity;
        public String BillingCountryCode;
        public String BillingStateCode;
        public String BillingStreet;
        public String BillingPostalCode;
        public String BranchCode;
        public String CommunicationLanguage;
        public String CompanyCode;
        public String CompanyCurrencyIsoCode;
        public String CurrencyIsoCode;
        public String Email;
        public String ERPNumber;
        public String Fax;
        public String Guid;
        public String Id;
        public Boolean Inactive;
        public String InsideSalespersonCode;
        public String MainClassification;
        public String Name;
        public String Phone;
        public String PrimaryContactEmail;
        public String PrimaryContactERPNumber;
        public String PrimaryContactFax;
        public String PrimaryContactFirstName;
        public String PrimaryContactGuid;
        public String PrimaryContactId;
        public Boolean PrimaryContactInactive;
        public String PrimaryContactJobTitle;
        public String PrimaryContactLastName;
        public String PrimaryContactMiddleName;
        public String PrimaryContactMobilePhone;
        public String PrimaryContactPhone;
        public String PrimaryContactSalespersonCode;
        public String PrimarySegment;
        public String RealizedRevenueClassification;
        public String SalespersonCode;
        public String SubType;
        public String Type;
        public String Website;
    } 
}
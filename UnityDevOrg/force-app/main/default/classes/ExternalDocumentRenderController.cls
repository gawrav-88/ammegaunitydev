/*------------------------------------------------------------------------------------------------------------------------	
Author:        Salesforce Services	
Company:       Salesforce	
Description:   This class retrieves a document from an external service. It uses information stored on the company to call the 
correct external service. It also utilizes named credentials to handle the authentication of the callout.
Inputs:        RecordId 
Test Class:    GuidUtilityClassTest	 
------------------------------------------------------------------------------------------------------------------------*/	
public without sharing class ExternalDocumentRenderController {
    
    public class ObjectInformation{
        public String name;
        public String endpoint;
        public Boolean showDocument;
    }
    
    @AuraEnabled
    public static Id getDocumentId(Id currentRecordId){
        Blob binaryData;
        //Create a new file
        ObjectInformation objInfo = getObjectInformation(currentRecordId); // Get information to call document service
        if(objInfo.showDocument){
            binaryData = retrieveDocument(objInfo.endpoint); // Retrieve document from external service
        }else{//if ShowDocumentLink__c is not checked, the pdf will not be visible
            throw new AuraHandledException('No document available. Please try again later or contact your administrator');
        }
        
        String documentReference = 'GeneratedDocument-' + objInfo.name; // Construct the name of the document
        
        ContentVersion cv = new ContentVersion(
            ContentLocation = 'S',
            FirstPublishLocationId = currentRecordId, // Set the relation to the parent record
            VersionData = binaryData,
            Title = documentReference,
            PathOnClient = documentReference + '.pdf' // Hardcoded pdf as for now we only handle pdf with this document generation service
        );
        
        /* first clean up before inserting file */
        
        /* Although we could use document versions,
/* for the initial version of this class we opted 
/* for deleting the file and creating a new one to keep things simple */
        
        
        // Find possible existing files for this record
        List<ContentDocumentLink> existingDocumentLinks = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :currentRecordId];
        // Delete all generated files (match on Title)
        Set<Id> existingDocumentIds = new Set<Id>();
        for (ContentDocumentLink documentLink : existingDocumentLinks) {
            existingDocumentIds.add(documentLink.ContentDocumentId);
        }
        List<ContentDocument> existingDocuments = [SELECT Id FROM ContentDocument WHERE Id IN :existingDocumentIds AND Title =  :documentReference];
        System.debug(existingDocuments);
        delete existingDocuments;
        
        /* now insert file */
        insert cv;
        System.debug(cv);
        return [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1].ContentDocumentId;
    }
    
    private static Blob retrieveDocument(String endPoint){
        // HTTP Callout
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod('GET');
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        system.debug('res.getStatusCode()-->'+res.getStatusCode());
        
        if (res.getStatusCode() == 200) { //only return content if call is succesfull
            system.debug('res.getBody()-->'+res.getBody());
            if(res.getBody().startsWithIgnoreCase('Error:') || res.getBody().contains('Not successful')){
                throw new AuraHandledException('No document retrieved. Contact your administrator');
            }
            return res.getBodyAsBlob();
        } else {
            throw new AuraHandledException('No document retrieved. HTTP status = ' + res.getStatusCode() + res.getStatus() );
        }
    }
    
    private static ObjectInformation getObjectInformation(Id currentRecordId){
        Schema.SObjectType objectType = currentRecordId.getSobjectType();
        
        // Based on the documenttype retrieve the information needed to call the external service
        Switch on objectType.getDescribe().getName(){
            when 'Quote__c'{
                Quote__c quote = [SELECT Name,
                                  Account__r.Company__r.BaseURLQuoteViewer__c, 
                                  Account__r.Company__r.NamedCredentialsPDFCallout__c,
                                  ShowDocumentLink__c 
                                  FROM Quote__c
                                  WHERE Id = :currentRecordId];
                String endPoint = 'callout:' + quote.Account__r.Company__r.NamedCredentialsPDFCallout__c + '/' + quote.Account__r.Company__r.BaseURLQuoteViewer__c;
                ObjectInformation objInfo = new ObjectInformation();
                objInfo.name = quote.Name; 
                objInfo.endpoint = endPoint.replace('{1}', quote.Name);
                objInfo.showDocument = quote.ShowDocumentLink__c;
                return objInfo;                         
            }
            when 'Order__c'{
                Order__c order = [SELECT Name,
                                  Account__r.Company__r.BaseURLOrderViewer__c, 
                                  Account__r.Company__r.NamedCredentialsPDFCallout__c,
                                  ShowDocumentLink__c 
                                  FROM Order__c
                                  WHERE Id = :currentRecordId];
                String endPoint = 'callout:' + order.Account__r.Company__r.NamedCredentialsPDFCallout__c + '/' + order.Account__r.Company__r.BaseURLOrderViewer__c;
                ObjectInformation objInfo = new ObjectInformation();
                objInfo.name = order.Name;
                objInfo.endpoint = endPoint.replace('{1}', order.Name);
                objInfo.showDocument = order.ShowDocumentLink__c;
                return objInfo;                                               
            }
            when else{
                throw new AuraHandledException('PDF rendering not implemented for objectype ' + objectType.getDescribe().getName());
            }
        }
    }
}
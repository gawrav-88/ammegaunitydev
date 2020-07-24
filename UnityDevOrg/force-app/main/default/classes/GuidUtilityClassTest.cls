/*------------------------------------------------------------------------------------------------------------------------  
Author:        Salesforce Services  
Company:       Salesforce   
Description:   Test class for the Guid Utility class to test the validity of the Guids against UUID v4 spec
Inputs:        None 
Test Class:    GuidUtilityClassTest  
------------------------------------------------------------------------------------------------------------------------*/
@isTest
public with sharing class GuidUtilityClassTest {
    private static testmethod void guidIsV4() {
      //Pattern of valid Guid    
      Pattern p = Pattern.compile('[\\w]{8}-[\\w]{4}-4[\\w]{3}-[89ab][\\w]{3}-[\\w]{12}');

      //Check that valid Guids are created by newGuid()
      for(Integer x = 0; x < 100; x++) {
        Matcher m = p.matcher(GuidUtilityClass.newGuid());
        System.assert(m.matches() == true);
      }
    }
}
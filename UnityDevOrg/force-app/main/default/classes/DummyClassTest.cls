/*------------------------------------------------------------------------------------------------------------------------	
Author        : Salesforce Services	
Company       : Salesforce	
Description   : Test class for DummyClass
Inputs        : None	
History       : 
------------------------------------------------------------------------------------------------------------------------*/	
@isTest
public class DummyClassTest {
	@isTest
	public static void TestDummyMethod () {
		DummyClass.DummyMethod();
		system.assert(true);
	}
}
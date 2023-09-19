/**
* My BDD Test
*/
component extends="coldbox.system.testing.BaseTestCase"{

/*********************************** LIFE CYCLE Methods ***********************************/
this.unloadColdbox=false;
	// executes before all suites+specs in the run() method
	function beforeAll(){
		super.beforeAll();
	}

	// executes after all suites+specs in the run() method
	//function afterAll(){

	//}

/*********************************** BDD SUITES ***********************************/

	function run( testResults, testBox ){
		// all your suites go here.
		describe( "The createSignatureUtil function should...", function(){
			beforeEach(function(){
				testObj = getInstance("AmazonS3@s3sdk");
			});
			it( "If V2 is submitted, return SV2Util", function(){
				testme = testObj.createSignatureUtil("V2");
				expect(testme).tobeInstanceOf("Sv2Util");
			});
			it( "If V4 is submitted, return SV2Util", function(){
				testme = testObj.createSignatureUtil("V4");
				expect(testme).tobeInstanceOf("Sv4Util");
			});
		});
	}
}


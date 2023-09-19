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
		describe( "The setAuth function should...", function(){
			beforeEach(function(){
				accessKey = mockData($num=1,$type="words:1")[1];
				secretKey = mockData($num=1,$type="words:1")[1];

				testObj = getInstance("AmazonS3@s3sdk");
			});
			it( "Set the accessKey submitted", function(){
				testme = testObj.setAuth(accessKey, secretKey);
				expect(testme.getAccessKey()).tobe(accessKey);
			});
			it( "Set the secretKey submitted", function(){
				testme = testObj.setAuth(accessKey, secretKey);
				expect(testme.getSecretKey()).tobe(secretKey);
			});
		});
	}
}


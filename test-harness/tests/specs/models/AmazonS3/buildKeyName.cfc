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
		describe( "The buildKeyName function should...", function(){
			beforeEach(function(){
				uri = mockData($num=1,$type="words:1")[1];
				bucketName = mockData($num=1,$type="words:1")[1];

				testObj = getInstance("AmazonS3@s3sdk");
			});
			it( "If the urlStyle is path and a bucket is submitted, return bucket\uri", function(){
				testObj.setUrlStyle("path");
				testme = testObj.buildKeyName(uri,bucketName);
				expect(testme).tobe("#bucketName#/#uri#");
			});
			it( "If the urlStyle is path and a bucket is not submitted, return uri", function(){
				testObj.setUrlStyle("path");
				testme = testObj.buildKeyName(uri);
					expect(testme).tobe(uri);
			});
			it( "If the urlStyle is path and the bucket is an empty string, return uri", function(){
				testObj.setUrlStyle("path");
				testme = testObj.buildKeyName(uri,"");
					expect(testme).tobe(uri);
			});
			it( "If the urlStyle is virtual, return uri", function(){
				testObj.setUrlStyle("virtual");
				testme = testObj.buildKeyName(uri,bucketname);
					expect(testme).tobe(uri);
			});
		});
	}
}


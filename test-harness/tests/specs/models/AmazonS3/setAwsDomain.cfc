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
		describe( "The setAWSDomain function should...", function(){
			beforeEach(function(){
				domain = mockData($num=1,$type="words:1")[1];

				testObj = createMock(object=getInstance("AmazonS3@s3sdk"));
				testObj.$(method="buildUrlEndpoint", returns=testObj);
			});
			it( "Set the domain submitted", function(){
				testme = testObj.setAwsDomain(domain);
				expect(testme.getAwsDomain()).tobe(domain);
			});
			it( "call buildUrlEndpoint 1x", function(){
				testme = testObj.setAwsDomain(domain);
				expect(testObj.$count("buildUrlEndpoint")).tobe(1);
			});
		});
	}
}


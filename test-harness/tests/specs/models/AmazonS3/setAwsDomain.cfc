/**
 * My BDD Test
 */
component extends="coldbox.system.testing.BaseTestCase" {

	/*********************************** LIFE CYCLE Methods ***********************************/
	this.unloadColdbox = false;
	// executes before all suites+specs in the run() method
	function beforeAll(){
		super.beforeAll();
	}

	// executes after all suites+specs in the run() method
	// function afterAll(){

	// }

	/*********************************** BDD SUITES ***********************************/

	function run( testResults, testBox ){
		// all your suites go here.
		describe( "The setAWSDomain function should...", function(){
			beforeEach( function(){
				domain = mockData( $num = 1, $type = "words:1" )[ 1 ];

				testObj = new s3sdk.models.AmazonS3(
					accessKey              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					secretKey              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					awsRegion              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					awsDomain              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					ssl                    = true,
					defaultBucketName      = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					defaultObjectOwnership = mockdata( $num = 1, $type = "words:1" )[ 1 ]
				);
				prepareMock( testObj );
				testObj.$( method = "buildUrlEndpoint", returns = testObj );
			} );
			it( "Set the domain submitted", function(){
				testme = testObj.setAwsDomain( domain );
				expect( testme.getAwsDomain() ).tobe( domain );
			} );
			it( "call buildUrlEndpoint 1x", function(){
				testme = testObj.setAwsDomain( domain );
				expect( testObj.$count( "buildUrlEndpoint" ) ).tobe( 1 );
			} );
		} );
	}

}


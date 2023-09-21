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
		describe( "The createSignatureUtil function should...", function(){
			beforeEach( function(){
				testObj = new s3sdk.models.AmazonS3(
					accessKey              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					secretKey              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					awsRegion              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					awsDomain              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					ssl                    = true,
					defaultBucketName      = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					defaultObjectOwnership = mockdata( $num = 1, $type = "words:1" )[ 1 ]
				);
			} );
			it( "If V2 is submitted, return SV2Util", function(){
				testme = testObj.createSignatureUtil( "V2" );
				expect( testme ).tobeInstanceOf( "Sv2Util" );
			} );
			it( "If V4 is submitted, return SV2Util", function(){
				testme = testObj.createSignatureUtil( "V4" );
				expect( testme ).tobeInstanceOf( "Sv4Util" );
			} );
		} );
	}

}


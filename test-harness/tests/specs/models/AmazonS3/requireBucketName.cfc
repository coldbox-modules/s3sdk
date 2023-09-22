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

	/*********************************** BDD SUITES ***********************************/

	function run( testResults, testBox ){
		// all your suites go here.
		describe( "The setAwsRegion function should...", function(){
			beforeEach( function(){
				bucketName = mockdata( $num = 1, $type = "words:1" )[ 1 ];
				testObj    = testObj = new s3sdk.models.AmazonS3(
					accessKey              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					secretKey              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					awsRegion              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					awsDomain              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					ssl                    = true,
					defaultBucketName      = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					defaultObjectOwnership = mockdata( $num = 1, $type = "words:1" )[ 1 ]
				);
				makePublic(
					testObj,
					"requireBucketName",
					"requireBucketNamePublic"
				);
			} );
			it( "If a bucketname is submitted, do nothing", function(){
				testme = testObj.requireBucketNamePublic( bucketName );
				expect( isNull( testme ) ).tobeTrue();
			} );
			it( "If a bucketname is blank, throw an application error", function(){
				expect( function(){
					testObj.requireBucketNamePublic( "" );
				} ).toThrow( "application" );
			} );
			it( "If a bucketname is null, throw an application error", function(){
				expect( function(){
					testObj.requireBucketNamePublic();
				} ).toThrow( "application" );
			} );
		} );
	}

}


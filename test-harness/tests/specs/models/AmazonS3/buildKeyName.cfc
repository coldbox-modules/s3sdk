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
		describe( "The buildKeyName function should...", function(){
			beforeEach( function(){
				uri                = mockData( $num = 1, $type = "words:1" )[ 1 ];
				bucketName         = mockData( $num = 1, $type = "words:1" )[ 1 ];
				var moduleSettings = getWirebox().getInstance( "box:moduleSettings:s3sdk" );

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
			it( "If the urlStyle is path and a bucket is submitted, return bucket\uri", function(){
				testObj.setUrlStyle( "path" );
				testme = testObj.buildKeyName( uri, bucketName );
				expect( testme ).tobe( "#bucketName#/#uri#" );
			} );
			it( "If the urlStyle is path and a bucket is not submitted, return uri", function(){
				testObj.setUrlStyle( "path" );
				testme = testObj.buildKeyName( uri );
				expect( testme ).tobe( uri );
			} );
			it( "If the urlStyle is path and the bucket is an empty string, return uri", function(){
				testObj.setUrlStyle( "path" );
				testme = testObj.buildKeyName( uri, "" );
				expect( testme ).tobe( uri );
			} );
			it( "If the urlStyle is virtual, return uri", function(){
				testObj.setUrlStyle( "virtual" );
				testme = testObj.buildKeyName( uri, bucketname );
				expect( testme ).tobe( uri );
			} );
		} );
	}

}


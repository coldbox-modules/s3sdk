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
		describe( "The buildUrlEndpoint function should ...", function(){
			beforeEach( function(){
				domain     = mockData( $num = 1, $type = "words:1" )[ 1 ];
				region     = mockData( $num = 1, $type = "words:1" )[ 1 ];
				bucketName = mockData( $num = 1, $type = "words:1" )[ 1 ];
				keyName    = mockData( $num = 1, $type = "words:1" )[ 1 ];
				testObj    = new s3sdk.models.AmazonS3(
					accessKey              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					secretKey              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					awsRegion              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					awsDomain              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					ssl                    = true,
					defaultBucketName      = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					defaultObjectOwnership = mockdata( $num = 1, $type = "words:1" )[ 1 ]
				);
				testObj.setAwsRegion( region );
			} );
			it( "If the urlStyle is path - the default - , build according to https://s3.region-code.amazonaws.com/bucket-name/key-name", function(){
				testObj.setUrlStyle( "path" );
				testObj.setawsDomain( "amazonaws.com" );
				var testme = testObj.buildUrlEndpoint( bucketName );
				expect( testme.getURLEndpointHostname() ).tobe( "s3.#region#.amazonaws.com" );
				expect( testme.getURLEndpoint() ).tobe( "https://s3.#region#.amazonaws.com" );
			} );
			it( "If the urlStyle is path and the domain is not amazonaws.com, do not include s3", function(){
				testObj.setUrlStyle( "path" );
				testObj.setawsDomain( domain );
				var testme = testObj.buildUrlEndpoint( bucketName );
				expect( testme.getURLEndpointHostname() ).tobe( "#region#.#domain#" );
				expect( testme.getURLEndpoint() ).tobe( "https://#region#.#domain#" );
			} );
			it( "If the urlStyle is path and the region is empty, do not include it", function(){
				testObj.setUrlStyle( "path" );
				testObj.setawsDomain( "amazonaws.com" );
				testObj.setawsRegion( "" );
				var testme = testObj.buildUrlEndpoint( bucketName );
				expect( testme.getURLEndpointHostname() ).tobe( "s3.amazonaws.com" );
				expect( testme.getURLEndpoint() ).tobe( "https://s3.amazonaws.com" );
			} );
			it( "If the urlStyle is virtual and the domain has amazonaws.com, build according to https://bucket-name.s3.region-code.amazonaws.com/key-name", function(){
				testObj.setUrlStyle( "virtual" );
				testObj.setawsDomain( "amazonaws.com" );
				var testme = testObj.buildUrlEndpoint( bucketName );
				expect( testme.getURLEndpointHostname() ).tobe( "#bucketName#.s3.#region#.amazonaws.com" );
				expect( testme.getURLEndpoint() ).tobe( "https://#bucketName#.s3.#region#.amazonaws.com" );
			} );
			it( "If the urlStyle is virtual and the domain has amazonaws.com, but a bucket name is not submitted, do not include it", function(){
				testObj.setUrlStyle( "virtual" );
				testObj.setawsDomain( "amazonaws.com" );
				var testme = testObj.buildUrlEndpoint();
				expect( testme.getURLEndpointHostname() ).tobe( "s3.#region#.amazonaws.com" );
				expect( testme.getURLEndpoint() ).tobe( "https://s3.#region#.amazonaws.com" );
			} );
			it( "If the urlStyle is virtual and the domain has amazonaws.com, but a region is not set, do not include it", function(){
				testObj.setUrlStyle( "virtual" );
				testObj.setawsDomain( "amazonaws.com" );
				testObj.setawsRegion( "" );
				var testme = testObj.buildUrlEndpoint( bucketName );
				expect( testme.getURLEndpointHostname() ).tobe( "#bucketName#.s3.amazonaws.com" );
				expect( testme.getURLEndpoint() ).tobe( "https://#bucketName#.s3.amazonaws.com" );
			} );
			it( "If the urlStyle is virtual and the domain does not have amazonaws.com, do not alter the domain name", function(){
				testObj.setUrlStyle( "virtual" );
				testObj.setawsDomain( "mydomain.com" );
				testObj.setawsRegion( "" );
				var testme = testObj.buildUrlEndpoint( bucketName );
					expect( testme.getURLEndpointHostname() ).tobe( "mydomain.com" );
					expect( testme.getURLEndpoint() ).tobe( "https://mydomain.com" );
			} );
			it( "If the urlStyle is path  and the domain does not have amazonaws.com, do not alter the domain name", function(){
				testObj.setUrlStyle( "virtual" );
				testObj.setawsDomain( "mydomain.com" );
				testObj.setawsRegion( "" );
				var testme = testObj.buildUrlEndpoint( bucketName );
					expect( testme.getURLEndpointHostname() ).tobe( "mydomain.com" );
					expect( testme.getURLEndpoint() ).tobe( "https://mydomain.com" );
			} );
			it( "It should return an instance of AmazonS3", function(){
				testObj.setUrlStyle( "path" );
				testObj.setawsDomain( "amazonaws.com" );
				var testme = testObj.buildUrlEndpoint( bucketName );
				expect( testme ).tobeInstanceOf( "AmazonS3" );
			} );
		} );
	}

}


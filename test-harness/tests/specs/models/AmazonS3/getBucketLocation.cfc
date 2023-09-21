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
		describe( "The setAwsRegion function should...", function(){
			beforeEach( function(){
				accessKey  = mockData( $num = 1, $type = "words:1" )[ 1 ];
				secretKey  = mockData( $num = 1, $type = "words:1" )[ 1 ];
				bucketName = mockData( $num = 1, $type = "words:1" )[ 1 ];

				testObj = testObj = new s3sdk.models.AmazonS3(
					accessKey              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					secretKey              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					awsRegion              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					awsDomain              = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					ssl                    = true,
					defaultBucketName      = mockdata( $num = 1, $type = "words:1" )[ 1 ],
					defaultObjectOwnership = mockdata( $num = 1, $type = "words:1" )[ 1 ]
				);
				prepareMock( testObj );
				testObj.setAccessKey( accessKey );
				testObj.setSecretKey( secretKey );
				testObj.$( method = "requireBucketName" );
				testObj.$( method = "s3Request", returns = createResponse() );
			} );
			it( "Should call requireBucketName 1x ", function(){
				testme = testObj.getBucketLocation( bucketName );
				expect( testObj.$count( "requireBucketName" ) ).tobe( 1 );
			} );
			it( "Should call s3Request 1x ", function(){
				testme = testObj.getBucketLocation( bucketName );
				expect( testObj.$count( "s3Request" ) ).tobe( 1 );
			} );
			it( "If an error is returned from s3Request, it should throw an error with the message from s3 as the error message ", function(){
				var message = mockdata( $num = 1, $type = "words:10" )[ 1 ];
				testObj.$( method = "s3Request", returns = createResponse( error = true, message = message ) );
				expect( function(){
					testObj.getBucketLocation( bucketName );
				} ).tothrow( type = "application", message = message );
			} );
		} );
	}

	function createResponse(
		required boolean error = false,
		string location        = "",
		message                = ""
	){
		return {
			"response" : xmlParse( "<?xml version=""1.0"" encoding=""UTF-8"" standalone=""no""?>
			<LocationConstraint xmlns=""http://s3.amazonaws.com/doc/2006-03-01/"">#arguments.location#</LocationConstraint>" ),
			"message"        : arguments.message,
			"error"          : arguments.error,
			"responseheader" : {
				"Date"              : "Tue, 19 Sep 2023 16:09:11 GMT",
				"Server"            : "AmazonS3",
				"Transfer-Encoding" : "chunked",
				"x-amz-id-2"        : "8CxOH41yj+NlQLaKGmgFGRpImXai9QnR+nNT5biih8eeYBWSZ1R65tUW1C6uw9eTvj5435wzWPg=",
				"x-amz-request-id"  : "263PWVHD32Y7P5Q9",
				"status_code"       : 200,
				"Content-Type"      : "application/xml",
				"explanation"       : "OK"
			}
		};
	}

}


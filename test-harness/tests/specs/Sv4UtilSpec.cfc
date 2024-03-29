component extends="coldbox.system.testing.BaseTestCase" {

	function beforeAll(){
		variables.sv4 = new s3sdk.models.Sv4Util();

		variables.awsSigV4TestSuiteConfig = {
			// The following four are derived from the "credential scope" listed in the
			// SigV4 Test Suite docs at
			// https://docs.aws.amazon.com/general/latest/gr/signature-v4-test-suite.html
			accessKey   : "AKIDEXAMPLE",
			dateStamp   : "20150830",
			regionName  : "us-east-1",
			serviceName : "service",
			// This is derived from the files in the SigV4 Test Suite.
			amzDate     : "20150830T123600Z",
			// This comes straight from the SigV4 Test Suite docs.
			secretKey   : "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY"
		};
	}

	function run(){
		describe( "SigV4 utilities", function(){
			describe( "get-presigned-url", function(){
				it( "generateSignatureData", function(){
					// The following are example data from
					// https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html
					config = {
						accessKey   : "AKIAIOSFODNN7EXAMPLE",
						dateStamp   : "20130524",
						regionName  : "us-east-1",
						serviceName : "s3",
						amzDate     : "20130524T000000Z",
						secretKey   : "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
					};
					var testData = fixtureData( "get-presigned-url" );

					var sigData = sv4.generateSignatureData(
						requestMethod      = testData.method,
						hostName           = testData.host,
						requestURI         = testData.uri,
						requestBody        = "",
						requestHeaders     = testData.headers,
						requestParams      = testData.urlParams,
						accessKey          = config.accessKey,
						secretKey          = config.secretKey,
						regionName         = config.regionName,
						serviceName        = config.serviceName,
						amzDate            = config.amzDate,
						dateStamp          = config.dateStamp,
						presignDownloadURL = true
					);

					expect( sigData.canonicalRequest ).toBe( testData.canonicalRequest );
					expect( sigData.stringToSign ).toBe( testData.stringToSign );
					expect( sigData.authorizationHeader ).toBe( testData.authHeader );
				} );
			} );

			describe( "adapted AWS SigV4 test suite tests", function(){
				it( "signs get-vanilla-query-unreserved", function(){
					var config   = variables.awsSigV4TestSuiteConfig;
					var testData = fixtureData( "get-vanilla-query-unreserved-s3" );
					expectCorrectSignature( config, testData );
				} );

				it( "signs post-header-key-sort", function(){
					var config   = variables.awsSigV4TestSuiteConfig;
					var testData = fixtureData( "post-header-key-sort-s3" );
					expectCorrectSignature( config, testData );
				} );

				it( "signs post-vanilla-query", function(){
					var config   = variables.awsSigV4TestSuiteConfig;
					var testData = fixtureData( "post-vanilla-query-s3" );
					expectCorrectSignature( config, testData );
				} );
			} );
		} );
	}

	private function expectCorrectSignature( required struct config, required struct testData ){
		var sigData = sv4.generateSignatureData(
			requestMethod  = testData.method,
			hostName       = testData.host,
			requestURI     = testData.uri,
			requestBody    = "",
			requestHeaders = testData.headers,
			requestParams  = testData.urlParams,
			accessKey      = config.accessKey,
			secretKey      = config.secretKey,
			regionName     = config.regionName,
			serviceName    = config.serviceName,
			amzDate        = config.amzDate,
			dateStamp      = config.dateStamp
		);

		expect( sigData.canonicalRequest ).toBe( testData.canonicalRequest );
		expect( sigData.stringToSign ).toBe( testData.stringToSign );
		expect( sigData.authorizationHeader ).toBe( testData.authHeader );
	}

	private function fixtureData( required string folderName ){
		var folderPath = expandPath( "/tests/fixtures/#folderName#" );
		var data       = {
			request          : fileRead( "#folderPath#/#folderName#.req" ).replace( chr( 13 ), "", "all" ),
			canonicalRequest : fileRead( "#folderPath#/#folderName#.creq" ).replace( chr( 13 ), "", "all" ),
			stringToSign     : fileRead( "#folderPath#/#folderName#.sts" ).replace( chr( 13 ), "", "all" ),
			authHeader       : fileRead( "#folderPath#/#folderName#.authz" ).replace( chr( 13 ), "", "all" )
		};
		data.method    = data.request.listToArray( " " )[ 1 ];
		data.host      = data.request.listToArray( chr( 10 ) )[ 2 ].listToArray( ":" )[ 2 ];
		data.uri       = data.request.listToArray( " " )[ 2 ].reReplace( "\?.*$", "" );
		data.headers   = headersFromRequestFile( data.request );
		data.urlParams = urlParamsFromRequestFile( data.request );
		return data;
	}

	// TODO: Handle multi-line headers
	private function headersFromRequestFile( file ){
		var lines                  = file.listToArray( chr( 10 ) );
		var lineNumberAfterHeaders = lines.find( "" );
		if ( !lineNumberAfterHeaders ) {
			lineNumberAfterHeaders = lines.len();
		}
		var headers = lines.slice( 2, lineNumberAfterHeaders - 1 );
		return headers.reduce( function( memo, el ){
			var colonPos     = el.find( ":" );
			var name         = el.left( colonPos - 1 );
			var value        = el.right( el.len() - colonPos );
			memo[ "#name#" ] = value;
			return memo;
		}, {} );
	}

	private function urlParamsFromRequestFile( file ){
		var uri    = file.listToArray( " " )[ 2 ];
		var params = {};
		if ( !uri.find( "?" ) ) {
			return params;
		}
		var queryString = uri.listToArray( "?" )[ 2 ];
		return queryString
			.listToArray( "&" )
			.reduce( function( memo, el ){
				var eqPos        = el.find( "=" );
				var name         = el.left( eqPos - 1 );
				var value        = el.right( el.len() - eqPos );
				memo[ "#name#" ] = value;
				return memo;
			}, params );
	}

}

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
		describe( "By default the init function should...", function(){
			beforeEach( function(){
				accessKey = mockData( $num = 1, $type = "words:1" )[ 1 ];
				secretKey = mockData( $num = 1, $type = "words:1" )[ 1 ];

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
				testObj.$( method = "createSignatureUtil" );
			} );
			it( "Have the accessKey set", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getAccessKey() ).tobe( accessKey );
			} );
			it( "Have the secretKey set", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getSecretKey() ).tobe( secretKey );
			} );
			it( "Have the awsDomain set to amazonaws.com", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getawsDomain() ).tobe( "amazonaws.com" );
			} );
			it( "Have the awsRegion set to awsRegion.com", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getawsRegion() ).tobe( "us-east-1" );
			} );
			it( "Have the encryptionCharset set to UTF-8", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getencryptionCharset() ).tobe( "UTF-8" );
			} );
			it( "Have the ssl set to true", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getssl() ).tobeTrue();
			} );
			it( "Have the defaultTimeOut set to 300", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getdefaultTimeOut() ).tobe( 300 );
			} );
			it( "Have the defaultDelimiter set to /", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getdefaultDelimiter() ).tobe( "/" );
			} );
			it( "Have the defaultBucketName set to blank string", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getdefaultBucketName().len() ).tobe( 0 );
			} );
			it( "Have the defaultCacheControl set to no-store, no-cache, must-revalidate", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getdefaultCacheControl() ).tobe( "no-store, no-cache, must-revalidate" );
			} );
			it( "Have the defaultStorageClass set to no-store, no-cache, must-revalidate", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getdefaultStorageClass() ).tobe( "STANDARD" );
			} );
			it( "Have the defaultACL set to public-read", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getdefaultACL() ).tobe( "public-read" );
			} );
			it( "Have the throwOnRequestError set to true", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getthrowOnRequestError() ).tobeTrue();
			} );
			it( "Have the retriesOnError set to 3", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getretriesOnError() ).tobe( 3 );
			} );
			it( "Have the autoContentType set to false", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getautoContentType() ).tobeFalse();
			} );
			it( "Have the autoMD5 set to an empty string since the signature type defaults to V4", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getautoMD5().len() ).tobe( 0 );
			} );
			it( "Have the serviceName set to s3", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getserviceName() ).tobe( "s3" );
			} );
			it( "Have the defaultEncryptionAlgorithm set to an empty string", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getdefaultEncryptionAlgorithm().len() ).toBe( 0 );
			} );
			it( "Have the defaultEncryptionKey set to an empty string", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getdefaultEncryptionKey().len() ).tobe( 0 );
			} );
			it( "Have the multiPartByteThreshold set to 5242880", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getmultiPartByteThreshold() ).tobe( 5242880 );
			} );
			it( "Have the defaultObjectOwnership set to ObjectWriter", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getdefaultObjectOwnership() ).tobe( "ObjectWriter" );
			} );
			it( "Have the defaultBlockPublicAcls set to False", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getdefaultBlockPublicAcls() ).tobeFalse();
			} );
			it( "Have the defaultIgnorePublicAcls set to False", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getdefaultIgnorePublicAcls() ).tobeFalse();
			} );
			it( "Have the defaultBlockPublicPolicy set to False", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getdefaultBlockPublicPolicy() ).tobeFalse();
			} );
			it( "Have the defaultRestrictPublicBuckets set to False", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getdefaultRestrictPublicBuckets() ).tobeFalse();
			} );
			it( "Have the urlStyle set to path", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.geturlStyle() ).tobe( "path" );
			} );
			it( "Have the ssl set to true", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getSSL() ).tobeTrue();
			} );
			it( "Have the mimeTypes set", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testme.getMimeTypes() ).tobeTypeOf( "struct" );

				var mimeTypes       = returnMimeTypes();
				var targetMimeTypes = testme.getMimeTypes();
				expect( mimeTypes.keyArray().len() ).tobe( targetMimeTypes.keyArray().len() );
				mimeTypes.each( function( item ){
					expect( targetMimeTypes ).toHaveKey( item );
					expect( targetMimeTypes[ item ] ).tobe(
						mimeTypes[ item ],
						"#mimeTypes[ item ]# was the wrong value in "
					);
				} );
				targetMimeTypes.each( function( item ){
					expect( mimeTypes ).toHaveKey( item );
					expect( mimeTypes[ item ] ).tobe(
						targetMimeTypes[ item ],
						"#targetMimeTypes[ item ]# changed - update test reference "
					);
				} );
			} );



			it( "If the signature type is V2, Have the autoMD5 set to auto", function(){
				testme = testObj.init(
					accessKey     = accessKey,
					secretKey     = secretKey,
					signatureType = "V2"
				);
				expect( testme.getautoMD5() ).tobe( "auto" );
			} );
			it( "If arguments.autoMD5 is true , Have the autoMD5 set to auto", function(){
				testme = testObj.init(
					accessKey = accessKey,
					secretKey = secretKey,
					autoMD5   = true
				);
				expect( testme.getautoMD5() ).tobe( "auto" );
			} );
			it( "Should call createSignatureUtil 1x passing in the submitted signatureType", function(){
				testme = testObj.init( accessKey = accessKey, secretKey = secretKey );
				expect( testObj.$count( "createSignatureUtil" ) ).tobe( 1 );
				expect( testObj._mockCallLoggers ).toHaveKey( "createSignatureUtil" );
				expect( testObj._mockCallLoggers.createSignatureUtil.len() ).tobe( 1 );
				// expect(testObj._mockCallLoggers.createSignatureUtil[1].len()).tobe(1);
				expect( testObj._mockCallLoggers.createSignatureUtil[ 1 ][ 1 ] ).tobe( "v4" );
			} );
		} );
	}

	function returnMimeTypes(){
		return {
			htm   : "text/html",
			html  : "text/html",
			js    : "application/x-javascript",
			txt   : "text/plain",
			xml   : "text/xml",
			rss   : "application/rss+xml",
			css   : "text/css",
			gz    : "application/x-gzip",
			gif   : "image/gif",
			jpe   : "image/jpeg",
			jpeg  : "image/jpeg",
			jpg   : "image/jpeg",
			png   : "image/png",
			swf   : "application/x-shockwave-flash",
			ico   : "image/x-icon",
			flv   : "video/x-flv",
			doc   : "application/msword",
			xls   : "application/vnd.ms-excel",
			pdf   : "application/pdf",
			htc   : "text/x-component",
			svg   : "image/svg+xml",
			eot   : "application/vnd.ms-fontobject",
			ttf   : "font/ttf",
			otf   : "font/opentype",
			woff  : "application/font-woff",
			woff2 : "font/woff2"
		};
	}

}


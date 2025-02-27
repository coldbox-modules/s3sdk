component extends="coldbox.system.testing.BaseTestCase" {

	this.loadColdbox   = true;
	this.unloadColdbox = false;

	function beforeAll(){
		super.beforeAll();

		prepTmpFolder();

		var moduleSettings = getWirebox().getInstance( "box:moduleSettings:s3sdk" );

		variables.testBucket = moduleSettings.defaultBucketName;

		variables.s3 = new s3sdk.models.AmazonS3(
			accessKey              = moduleSettings.accessKey,
			secretKey              = moduleSettings.secretKey,
			awsRegion              = moduleSettings.awsRegion,
			awsDomain              = moduleSettings.awsDomain,
			ssl                    = moduleSettings.ssl,
			defaultBucketName      = moduleSettings.defaultBucketName,
			defaultObjectOwnership = moduleSettings.defaultObjectOwnership,
			urlStyle               = "path"
		);

		getWirebox().autowire( s3 );
		prepareMock( s3 );
		s3.$property( propertyName = "log", mock = createLogStub() );

		s3.putBucket( testBucket );
	}

	private function prepTmpFolder(){
		var targetPath = expandPath( "/tests/tmp" );

		if ( !directoryExists( targetPath ) ) {
			directoryCreate( targetPath );
		}

		if ( fileExists( targetPath & "/example.txt" ) ) {
			fileDelete( targetPath & "/example.txt" );
		}
	}

	private function isOldACF(){
		var isLucee = structKeyExists( server, "lucee" );
		return !isLucee and listFind( "11,2016", listFirst( server.coldfusion.productVersion ) );
	}

	function run(){
		describe( "Amazon S3 SDK", function(){
			describe( "objects", function(){
				afterEach( function( currentSpec ){
					// Add any test fixtures here that you create below
					s3.deleteObject( testBucket, "example.txt" );
					s3.deleteObject( testBucket, "example-2.txt" );
					s3.deleteObject( testBucket, "testFolder/example.txt" );
					s3.deleteObject( testBucket, "testFolder/" );
					s3.deleteObject( testBucket, "emptyFolder/" );
					s3.deleteObject( testBucket, "big_file.txt" );
					s3.deleteObject( testBucket, "exam%20p   le (fo%2Fo)+,!@##$%^&*()_+~ ;:.txt" );

					// Avoid these on cf11,2016 because their http sucks!
					if ( !isOldACF() ) {
						s3.deleteObject( testBucket, "Word Doc Tests.txt" );
					}
					var contents = s3.getBucket( testBucket );
					s3.setDefaultBucketName( "" );
				} );

				it( "can store a new object", function(){
					s3.putObject(
						bucketName  = testBucket,
						uri         = "example.txt",
						data        = "Hello, world!",
						contentType = "auto"
					);
					var md = s3.getObjectInfo( testBucket, "example.txt" );
					debug( md );
					expect( md ).notToBeEmpty();
					expect( md[ "Content-Type" ] ).toBe( "text/plain" );
				} );

				it( "can store a new object from file", function(){
					var filePath = expandPath( "/tests/tmp/example.txt" );
					fileWrite( filePath, "file contents" );
					sleepIfNIO();
					s3.putObjectFile(
						bucketName  = testBucket,
						uri         = "example.txt",
						filepath    = filePath,
						contentType = "auto"
					);
					var md = s3.getObjectInfo( testBucket, "example.txt" );

					expect( md ).notToBeEmpty();
					expect( md[ "Content-Type" ] ).toBe( "text/plain" );
				} );

				it( "can perform a multi-part upload on a file over 5MB", function(){
					var testFile = expandPath( "/tests/tmp/big_file.txt" );
					var fileSize = round( s3.getMultiPartByteThreshold() * 1.2 )
					fileWrite(
						testFile,
						repeatString( randRange( 0, 9 ), fileSize ),
						"utf-8"
					);
					sleepIfNIO();
					var uploadFileName = "big_file.txt";
					var resp           = s3.putObjectFile(
						bucketName  = testBucket,
						uri         = uploadFileName,
						filepath    = testFile,
						contentType = "auto"
					);
					expect( resp.contains( "multipart" ) ).toBeTrue();
					var md = s3.getObjectInfo( testBucket, uploadFileName );

					expect( md ).notToBeEmpty();
					expect( md[ "Content-Length" ] ).toBe( fileSize );
					expect( md[ "Content-Type" ] ).toBe( "text/plain" );

					// Download the uploaded file
					s3.downloadObject(
						testBucket,
						"big_file.txt",
						expandPath( "/tests/tmp/big_file2.txt" )
					);
					sleepIfNIO();
					// And confirm a hash of both file contents still matches
					expect( hash( fileRead( expandPath( "/tests/tmp/big_file2.txt" ) ) ) ).toBe(
						hash( fileRead( expandPath( "/tests/tmp/big_file.txt" ) ) )
					)
				} );

				it(
					title = "can store a new object with spaces in the name",
					skip  = isOldACF(),
					body  = function(){
						s3.putObject(
							testBucket,
							"Word Doc Tests.txt",
							"Hello, space world!"
						);
						var md = s3.getObjectInfo( testBucket, "Word Doc Tests.txt" );

						expect( md ).notToBeEmpty();
					}
				);

				it( "can store a new object with special chars in name", function(){
					s3.putObject(
						testBucket,
						"exam%20p   le (fo%2Fo)+,!@##$%^&*()_+~ ;:.txt",
						"Hello, world!"
					);
					var md = s3.getObjectInfo( testBucket, "example.txt" );
					debug( md );
					expect( md ).notToBeEmpty();
				} );

				it( "can list all objects", function(){
					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					s3.putObject(
						testBucket,
						"testFolder/example.txt",
						"Hello, world!"
					);
					var bucketContents = s3.getBucket( bucketName = testBucket, delimiter = "/" );
					expect( bucketContents ).toBeArray();
					expect( bucketContents ).toHaveLength( 2 );
					for ( var item in bucketContents ) {
						if ( item.key == "testFolder" ) {
							expect( item.isDirectory ).toBeTrue();
						} else {
							expect( item.isDirectory ).toBeFalse();
						}
					}
				} );

				it( "can list with prefix", function(){
					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					s3.putObject(
						testBucket,
						"testFolder/example.txt",
						"Hello, world!"
					);

					var bucketContents = s3.getBucket( testBucket, "example.txt" );
					expect( bucketContents ).toBeArray();
					expect( bucketContents ).toHaveLength( 1 );

					var bucketContents = s3.getBucket(
						bucketName = testBucket,
						prefix     = "testFolder/",
						delimiter  = "/"
					);

					expect( bucketContents ).toBeArray();
					expect( bucketContents ).toHaveLength( 1 );
					expect( bucketContents[ 1 ].isDirectory ).toBeFalse();

					s3.putObject( testBucket, "emptyFolder/", "" );
					var bucketContents = s3.getBucket(
						bucketName = testBucket,
						prefix     = "emptyFolder/",
						delimiter  = "/"
					);

					expect( bucketContents ).toBeArray();
					expect( bucketContents ).toHaveLength( 1 );
					expect( bucketContents[ 1 ].isDirectory ).toBeTrue();
				} );

				it( "can list with and without delimter", function(){
					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					s3.putObject(
						testBucket,
						"testFolder/example.txt",
						"Hello, world!"
					);

					// With no delimiter, there is no concept of folders, so all keys just show up and everything is a "file"
					var bucketContents = s3.getBucket( bucketName = testBucket, delimiter = "" );
					expect( bucketContents ).toBeArray();
					expect( bucketContents ).toHaveLength( 2 );

					bucketContents.each( function( item ){
						expect( item.isDirectory ).toBeFalse();
					} );

					// With a delimiter of "/", we only get the top level items and "testFolder" shows as a directory
					var bucketContents = s3.getBucket( bucketName = testBucket, delimiter = "/" );
					expect( bucketContents ).toBeArray();
					expect( bucketContents ).toHaveLength( 2 );

					bucketContents.each( function( item ){
						if ( item.key == "testFolder" ) {
							expect( item.isDirectory ).toBeTrue();
						} else {
							expect( item.isDirectory ).toBeFalse();
						}
					} );
				} );

				it( "can check if an object exists", function(){
					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					s3.putObject( testBucket, "emptyFolder/", "" );
					s3.putObject(
						testBucket,
						"testFolder/example.txt",
						"Hello, world!"
					);

					var existsCheck = s3.objectExists( testBucket, "example.txt" );
					expect( existsCheck ).toBeTrue();

					var existsCheck = s3.objectExists( testBucket, "notHere.txt" );
					expect( existsCheck ).toBeFalse();

					var existsCheck = s3.objectExists( testBucket, "emptyFolder/" );
					expect( existsCheck ).toBeTrue();

					var existsCheck = s3.objectExists( testBucket, "testFolder/example.txt" );
					expect( existsCheck ).toBeTrue();

					if ( !isOldACF() ) {
						var existsCheck = s3.objectExists( testBucket, "Word Doc Tests.docx" );
						expect( existsCheck ).toBeFalse();
					}
				} );

				it( "can delete an object from a bucket", function(){
					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					s3.deleteObject( testBucket, "example.txt" );
					var bucketContents = s3.getBucket( testBucket );
					expect( bucketContents ).toBeArray();
					expect( bucketContents ).toHaveLength( 0 );
				} );

				it( "can copy an object", function(){
					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					var bucketContents = s3.getBucket( testBucket );
					expect( bucketContents[ 1 ].key ).toBe( "example.txt" );

					s3.copyObject(
						testBucket,
						"example.txt",
						testBucket,
						"example-2.txt"
					);

					var bucketContents = s3.getBucket( testBucket );
					expect( bucketContents ).toHaveLength( 2 );
				} );

				it( "can rename an object", function(){
					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					s3.renameObject(
						testBucket,
						"example.txt",
						testBucket,
						"example-2.txt"
					);

					var bucketContents = s3.getBucket( testBucket );
					expect( bucketContents ).toHaveLength( 1 );
					expect( bucketContents[ 1 ].key ).toBe( "example-2.txt" );
				} );

				it( "can get a file", function(){
					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					var get = s3.getObject( testBucket, "example.txt" );
					expect( get.error ).toBeFalse();
					expect( get.response ).toBe( "Hello, world!" );
				} );

				it( "can get object ACL", function(){
					s3.putObject(
						bucketName = testBucket,
						uri        = "example.txt",
						data       = "Hello, world!",
						acl        = s3.ACL_PUBLIC_READ
					);
					var ACL = s3.getObjectACL( testBucket, "example.txt" );
					expect( ACL ).toBeStruct();
					expect( ACL ).toHaveKey( "owner" );
					expect( ACL.owner ).toBeStruct();
					expect( ACL.owner ).toHaveKey( "ID" );
					expect( ACL.owner ).toHaveKey( "DisplayName" );
					expect( ACL ).toHaveKey( "grants" );
					expect( ACL.grants ).toBeStruct();
					expect( ACL.grants ).toHaveKey( "FULL_CONTROL" );
					expect( ACL.grants ).toHaveKey( "WRITE" );
					expect( ACL.grants ).toHaveKey( "WRITE_ACP" );
					expect( ACL.grants ).toHaveKey( "READ" );
					expect( ACL.grants ).toHaveKey( "READ_ACP" );
					expect( ACL.grants.FULL_CONTROL ).toBeArray();
					expect( ACL.grants.WRITE ).toBeArray();
					expect( ACL.grants.WRITE_ACP ).toBeArray();
					expect( ACL.grants.READ ).toBeArray();
					expect( ACL.grants.READ_ACP ).toBeArray();
				} );

				it( "can translate canned ACL headers", function(){
					makePublic( s3, "applyACLHeaders" );

					var ACL = s3.applyACLHeaders( acl = "canned-acl" );
					expect( ACL ).toBeStruct();
					expect( ACL ).toHaveKey( "x-amz-acl" );
					expect( ACL[ "x-amz-acl" ] ).toBe( "canned-acl" );
				} );

				it( "can translate complex ACL headers", function(){
					makePublic( s3, "applyACLHeaders" );

					var ACL = s3.applyACLHeaders(
						acl = {
							"FULL_CONTROL" : [
								{ id : "12345" },
								{ uri : "http://acs.amazonaws.com/groups/global/AllUsers" },
								{ emailAddress : "xyz@amazon.com" }
							],
							"WRITE" : [
								{ id : "12345" },
								{ uri : "http://acs.amazonaws.com/groups/global/AllUsers" },
								{ emailAddress : "xyz@amazon.com" }
							],
							"WRITE_ACP" : [
								{ id : "12345" },
								{ uri : "http://acs.amazonaws.com/groups/global/AllUsers" },
								{ emailAddress : "xyz@amazon.com" }
							],
							"READ" : [
								{ id : "12345" },
								{ uri : "http://acs.amazonaws.com/groups/global/AllUsers" },
								{ emailAddress : "xyz@amazon.com" }
							],
							"READ_ACP" : [
								{ id : "12345" },
								{ uri : "http://acs.amazonaws.com/groups/global/AllUsers" },
								{ emailAddress : "xyz@amazon.com" }
							]
						}
					);
					expect( ACL ).toBeStruct();
					expect( ACL ).toHaveKey( "x-amz-grant-full-control" );
					expect( ACL[ "x-amz-grant-full-control" ] ).toBe(
						"id=""12345"", uri=""http://acs.amazonaws.com/groups/global/AllUsers"", emailAddress=""xyz@amazon.com"""
					);
					expect( ACL ).toHaveKey( "x-amz-grant-write" );
					expect( ACL[ "x-amz-grant-write" ] ).toBe(
						"id=""12345"", uri=""http://acs.amazonaws.com/groups/global/AllUsers"", emailAddress=""xyz@amazon.com"""
					);
					expect( ACL ).toHaveKey( "x-amz-grant-write" );
					expect( ACL[ "x-amz-grant-write" ] ).toBe(
						"id=""12345"", uri=""http://acs.amazonaws.com/groups/global/AllUsers"", emailAddress=""xyz@amazon.com"""
					);
					expect( ACL ).toHaveKey( "x-amz-grant-read" );
					expect( ACL[ "x-amz-grant-read" ] ).toBe(
						"id=""12345"", uri=""http://acs.amazonaws.com/groups/global/AllUsers"", emailAddress=""xyz@amazon.com"""
					);
					expect( ACL ).toHaveKey( "x-amz-grant-read-acp" );
					expect( ACL[ "x-amz-grant-read-acp" ] ).toBe(
						"id=""12345"", uri=""http://acs.amazonaws.com/groups/global/AllUsers"", emailAddress=""xyz@amazon.com"""
					);
				} );

				it( "can download a file", function(){
					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					var dl = s3.downloadObject(
						testBucket,
						"example.txt",
						expandPath( "/tests/tmp/example.txt" )
					);
					debug( dl );
					expect( dl ).notToBeEmpty();
					expect( dl.error ).toBeFalse();
				} );

				it( "validates missing bucketname", function(){
					expect( function(){
						s3.getBucket();
					} ).toThrow( message = "bucketName is required" );
				} );

				it( "Allows default bucket name", function(){
					s3.setDefaultBucketName( testBucket );
					s3.getBucket();
				} );

				it( "Allows default delimiter", function(){
					s3.setDefaultDelimiter( "/" );

					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					s3.putObject(
						testBucket,
						"testFolder/example.txt",
						"Hello, world!"
					);

					var bucketContents = s3.getBucket( bucketName = testBucket, prefix = "testFolder/" );

					expect( bucketContents ).toBeArray();
					expect( bucketContents ).toHaveLength( 1 );
					expect( bucketContents[ 1 ].isDirectory ).toBeFalse();
				} );
			} );

			describe( "buckets", function(){
				it( "returns true if a bucket exists", function(){
					expect( s3.hasBucket( testBucket ) ).toBeTrue();
				} );

				it( "can list the buckets associated with the account", function(){
					expect( arrayLen( s3.listBuckets() ) ).toBeGTE( 1, "At least one bucket should be returned" );
				} );

				xit( "can delete a bucket", function(){
					expect( s3.hasBucket( testBucket ) ).toBeTrue();
					var results = s3.deleteBucket( testBucket );
					expect( results ).toBeTrue();
					s3.putBucket( testBucket );
				} );

				it( "can get bucketPublicAccess", function(){
					var results = s3.getBucketPublicAccess( testBucket );
					expect( results ).toHaveKey( "BlockPublicAcls" );
					expect( results ).toHaveKey( "IgnorePublicAcls" );
					expect( results ).toHaveKey( "BlockPublicPolicy" );
					expect( results ).toHaveKey( "RestrictPublicBuckets" );

					expect( results.BlockPublicAcls ).toBeBoolean();
					expect( results.IgnorePublicAcls ).toBeBoolean();
					expect( results.BlockPublicPolicy ).toBeBoolean();
					expect( results.RestrictPublicBuckets ).toBeBoolean();
				} );

				it( "can set bucketPublicAccess", function(){
					s3.putBucketPublicAccess( testBucket, true, true, true, true );
					var results = s3.getBucketPublicAccess( testBucket );

					expect( results.BlockPublicAcls ).toBeTrue();
					expect( results.IgnorePublicAcls ).toBeTrue();
					expect( results.BlockPublicPolicy ).toBeTrue();
					expect( results.RestrictPublicBuckets ).toBeTrue();

					s3.putBucketPublicAccess( testBucket, false, false, false, false );
					var results = s3.getBucketPublicAccess( testBucket );

					expect( results.BlockPublicAcls ).toBeFalse();
					expect( results.IgnorePublicAcls ).toBeFalse();
					expect( results.BlockPublicPolicy ).toBeFalse();
					expect( results.RestrictPublicBuckets ).toBeFalse();
				} );

				it( "can set bucket ACL", function(){
					s3.putBucketACL( testBucket, "private" );
				} );
			} );

			describe( "Presigned URL", function(){
				afterEach( function( currentSpec ){
					var contents = s3.getBucket( testBucket );
					contents
						.filter( ( obj ) => !obj.isDirectory )
						.each( ( obj ) => s3.deleteObject( testBucket, obj.key ) );
					contents
						.filter( ( obj ) => obj.isDirectory )
						.each( ( obj ) => s3.deleteObject( testBucket, obj.key ) );
				} );

				it( "can access via get", function(){
					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					var presignedURL = s3.getAuthenticatedURL( bucketName = testBucket, uri = "example.txt" );
					cfhttp( url = "#presignedURL#", result = "local.httpResponse" );
					expect( local.httpResponse.Responseheader.status_code ?: 0 ).toBe( "200", local.httpResponse.fileContent );
					expect( local.httpResponse.fileContent ).toBe( "Hello, world!" );
				} );

				it( "can expire", function(){
					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					var presignedURL = s3.getAuthenticatedURL(
						bucketName   = testBucket,
						uri          = "example.txt",
						minutesValid = 1 / 60
					);
					sleep( 2000 )
					cfhttp( url = "#presignedURL#", result = "local.httpResponse" );

					expect( local.httpResponse.Responseheader.status_code ?: 0 ).toBe( "403", local.httpResponse.fileContent );
					expect( local.httpResponse.fileContent ).toMatch( "expired" );
				} );

				it( "cannot PUT with a GET URL", function(){
					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					var presignedURL = s3.getAuthenticatedURL( bucketName = testBucket, uri = "example.txt" );

					cfhttp(
						url    = "#presignedURL#",
						result = "local.httpResponse",
						method = "PUT"
					) {
						cfhttpparam( type = "body", value = "Pre-Signed Put!" );
					};

					// If a presigned URL is created for a GET operation, it can't be used for anything else!
					expect( local.httpResponse.Responseheader.status_code ?: 0 ).toBe( "403", local.httpResponse.fileContent );
				} );

				it( "can put file", function(){
					var presignedURL = s3.getAuthenticatedURL(
						bucketName = testBucket,
						uri        = "presignedput.txt",
						method     = "PUT"
					);
					cfhttp(
						url    = "#presignedURL#",
						result = "local.httpResponse",
						method = "PUT"
					) {
						cfhttpparam( type = "body", value = "Pre-Signed Put!" );
					};
					expect( local.httpResponse.Responseheader.status_code ?: 0 ).toBe( "200", local.httpResponse.fileContent );

					var get = s3.getObject( testBucket, "presignedput.txt" );

					expect( get.error ).toBeFalse();
					// toString() since there is no content type set in this test, Adobe doesn't send back the file as a string, but a byte output stream
					expect( toString( get.response ) ).toBe( "Pre-Signed Put!" );
				} );

				it( "can put file with friends", function(){
					var presignedURL = s3.getAuthenticatedURL(
						bucketName  = testBucket,
						uri         = "presignedputfriends.txt",
						method      = "PUT",
						metaHeaders = { "custom-header" : "custom value" },
						// If the following are left off, they are simply not verfied, meaning there is no issue if the actual CFHTTP call sends them with any value it choses.
						contentType = "text/plain",
						acl         = "public-read"
					);

					cfhttp(
						url    = "#presignedURL#",
						result = "local.httpResponse",
						method = "PUT"
					) {
						cfhttpparam( type = "body", value = "Pre-Signed Put!" );
						cfhttpparam(
							type  = "header",
							name  = "content-type",
							value = "text/plain"
						);
						cfhttpparam(
							type  = "header",
							name  = "x-amz-acl",
							value = "public-read"
						);
						cfhttpparam(
							type  = "header",
							name  = "x-amz-meta-custom-header",
							value = "custom value"
						);
					};
					expect( local.httpResponse.Responseheader.status_code ?: 0 ).toBe( "200", local.httpResponse.fileContent );

					var get = s3.getObject( testBucket, "presignedputfriends.txt" );

					expect( get.error ).toBeFalse();
					expect( get.response ).toBe( "Pre-Signed Put!" );
				} );

				it( "can enforce invalid ACL on PUT", function(){
					var presignedURL = s3.getAuthenticatedURL(
						bucketName = testBucket,
						uri        = "presignedputacl.txt",
						method     = "PUT",
						acl        = "public-read"
					);

					cfhttp(
						url    = "#presignedURL#",
						result = "local.httpResponse",
						method = "PUT"
					) {
						cfhttpparam( type = "body", value = "Pre-Signed Put!" );
						// ACL doesn't match!
						cfhttpparam(
							type  = "header",
							name  = "x-amz-acl",
							value = "public-read-write"
						);
					};
					expect( local.httpResponse.Responseheader.status_code ?: 0 ).toBe( "403", local.httpResponse.fileContent );
				} );

				it( "Can use presigned URL with forced response headers", function(){
					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					var presignedURL = s3.getAuthenticatedURL(
						bucketName      = testBucket,
						uri             = "example.txt",
						responseHeaders = {
							"content-type"        : "custom-type",
							"content-language"    : "custom-language",
							"expires"             : "custom-expires",
							"cache-control"       : "custom-cache",
							"content-disposition" : "custom-disposition",
							"content-encoding"    : "custom-encoding"
						}
					);
					cfhttp( url = "#presignedURL#", result = "local.httpResponse" );

					expect( local.httpResponse.Responseheader.status_code ?: 0 ).toBe( "200", local.httpResponse.fileContent );
					expect( local.httpResponse.fileContent ).toBe( "Hello, world!" );
					expect( local.httpResponse.Responseheader[ "content-type" ] ).toBe( "custom-type" );
					expect( local.httpResponse.Responseheader[ "content-language" ] ).toBe( "custom-language" );
					expect( local.httpResponse.Responseheader[ "expires" ] ).toBe( "custom-expires" );
					expect( local.httpResponse.Responseheader[ "cache-control" ] ).toBe( "custom-cache" );
					expect( local.httpResponse.Responseheader[ "content-disposition" ] ).toBe( "custom-disposition" );
					expect( local.httpResponse.Responseheader[ "content-encoding" ] ).toBe( "custom-encoding" );
				} );

				it( "Can use presigned URL with auto response content type", function(){
					s3.putObject(
						testBucket,
						"example.txt",
						"Hello, world!",
						"",
						"wacky-content-type"
					);
					var presignedURL = s3.getAuthenticatedURL(
						bucketName      = testBucket,
						uri             = "example.txt",
						responseHeaders = { "content-type" : "auto" }
					);
					cfhttp( url = "#presignedURL#", result = "local.httpResponse" );

					expect( local.httpResponse.Responseheader.status_code ?: 0 ).toBe( "200", local.httpResponse.fileContent );
					expect( local.httpResponse.fileContent ).toBe( "Hello, world!" );
					// Our explicit content type when storing the file is ignored and the corret type is automatically returned based on MIME type
					expect( local.httpResponse.Responseheader[ "content-type" ] ).toBe( "text/plain" );
				} );

				it( "Creating presigned URL with invalid response header throws error", function(){
					expect( () => s3.getAuthenticatedURL(
						bucketName      = testBucket,
						uri             = "example.txt",
						responseHeaders = { "fake" : "" }
					) ).toThrow();
				} );
			} );
		} );

		describe( "encryption", function(){
			afterEach( function( currentSpec ){
				// Add any test fixtures here that you create below
				s3.deleteObject( testBucket, "encrypted.txt" );
				s3.deleteObject( testBucket, "encrypted-copy.txt" );
				s3.deleteObject( testBucket, "encrypted2.txt" );
			} );

			it( "can put encrypted file", function(){
				var data = "Hello, encrypted world!";
				s3.putObject(
					bucketName          = testBucket,
					uri                 = "encrypted.txt",
					data                = data,
					encryptionAlgorithm = "AES256"
				);
				var o = s3.getObject( bucketName = testBucket, uri = "encrypted.txt" );

				expect( o.error ).toBe( false );
				expect( o.response ).toBe( data );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption" );
				expect( o.responseHeader[ "x-amz-server-side-encryption" ] ).toBe( "AES256" );

				var o = s3.getObjectInfo( bucketName = testBucket, uri = "encrypted.txt" );
				expect( o ).toHaveKey( "x-amz-server-side-encryption" );
				expect( o[ "x-amz-server-side-encryption" ] ).toBe( "AES256" );
			} );

			it( "can get presigned URL for encrypted file", function(){
				var data = "Hello, encrypted world!";
				s3.putObject(
					bucketName          = testBucket,
					uri                 = "encrypted.txt",
					data                = data,
					encryptionAlgorithm = "AES256"
				);

				var presignedURL = s3.getAuthenticatedURL( bucketName = testBucket, uri = "encrypted.txt" );
				cfhttp( url = "#presignedURL#", result = "local.httpResponse" );

				expect( local.httpResponse.Responseheader.status_code ?: 0 ).toBe( "200", local.httpResponse.fileContent );
				expect( local.httpResponse.fileContent ).toBe( data );
			} );

			it( "can get presigned URL for encrypted file with custom encrypted key", function(){
				var data   = "Hello, encrypted world!";
				var key    = generateSecretKey( "AES", 256 );
				var keyMD5 = toBase64( binaryDecode( hash( toBinary( key ), "MD5" ), "hex" ) );
				s3.putObject(
					bucketName          = testBucket,
					uri                 = "encrypted.txt",
					data                = data,
					encryptionAlgorithm = "AES256",
					encryptionKey       = key
				);

				var presignedURL = s3.getAuthenticatedURL(
					bucketName    = testBucket,
					uri           = "encrypted.txt",
					encryptionKey = key
				);

				// Since the encryption details MUST be sent via HTTP headers, it is not possible to use this signed URL in a web browser
				// Per https://docs.aws.amazon.com/AmazonS3/latest/userguide/ServerSideEncryptionCustomerKeys.html#ssec-and-presignedurl
				cfhttp( url = "#presignedURL#", result = "local.httpResponse" ) {
					cfhttpparam(
						type  = "header",
						name  = "x-amz-server-side-encryption-customer-algorithm",
						value = "AES256"
					);
					cfhttpparam(
						type  = "header",
						name  = "x-amz-server-side-encryption-customer-key",
						value = key
					);
					cfhttpparam(
						type  = "header",
						name  = "x-amz-server-side-encryption-customer-key-MD5",
						value = keyMD5
					);
				};

				expect( local.httpResponse.Responseheader.status_code ?: 0 ).toBe( "200", local.httpResponse.fileContent );
				expect( local.httpResponse.fileContent ).toBe( data );
			} );

			it( "can copy encrypted file", function(){
				var data = "Hello, encrypted world!";
				s3.putObject(
					bucketName          = testBucket,
					uri                 = "encrypted.txt",
					data                = data,
					encryptionAlgorithm = "AES256"
				);
				var o = s3.copyObject(
					fromBucket          = testBucket,
					fromURI             = "encrypted.txt",
					toBucket            = testBucket,
					toURI               = "encrypted-copy.txt",
					encryptionAlgorithm = "AES256"
				);
				var o = s3.getObject( bucketName = testBucket, uri = "encrypted-copy.txt" );

				expect( o.error ).toBe( false );
				expect( o.response ).toBe( data );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption" );
				expect( o.responseHeader[ "x-amz-server-side-encryption" ] ).toBe( "AES256" );
			} );

			it( "can rename encrypted file", function(){
				var data = "Hello, encrypted world!";
				s3.putObject(
					bucketName          = testBucket,
					uri                 = "encrypted.txt",
					data                = data,
					encryptionAlgorithm = "AES256"
				);
				var o = s3.renameObject(
					oldBucketName       = testBucket,
					oldFileKey          = "encrypted.txt",
					newBucketName       = testBucket,
					newFileKey          = "encrypted-copy.txt",
					encryptionAlgorithm = "AES256"
				);
				var o = s3.getObject( bucketName = testBucket, uri = "encrypted-copy.txt" );

				expect( o.error ).toBe( false );
				expect( o.response ).toBe( data );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption" );
				expect( o.responseHeader[ "x-amz-server-side-encryption" ] ).toBe( "AES256" );
			} );

			it( "can put encrypted with custom encryption key", function(){
				var data   = "Hello, encrypted world!";
				var key    = generateSecretKey( "AES", 256 );
				var keyMD5 = toBase64( binaryDecode( hash( toBinary( key ), "MD5" ), "hex" ) );
				s3.putObject(
					bucketName    = testBucket,
					uri           = "encrypted.txt",
					data          = data,
					encryptionKey = key
				);
				var o = s3.getObject(
					bucketName    = testBucket,
					uri           = "encrypted.txt",
					encryptionKey = key
				);

				expect( o.error ).toBe( false );
				expect( o.response ).toBe( data );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption-customer-algorithm" );
				expect( o.responseHeader[ "x-amz-server-side-encryption-customer-algorithm" ] ).toBe( "AES256" );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption-customer-key-MD5" );
				expect( o.responseHeader[ "x-amz-server-side-encryption-customer-key-MD5" ] ).toBe( keyMD5 );
			} );

			it( "can copy encrypted file with custom encryption key", function(){
				var data = "Hello, encrypted world!";
				var key  = generateSecretKey( "AES", 256 );
				// Store file with original encryption key
				s3.putObject(
					bucketName    = testBucket,
					uri           = "encrypted.txt",
					data          = data,
					encryptionKey = key
				);

				var newKey = generateSecretKey( "AES", 256 );
				var keyMD5 = toBase64( binaryDecode( hash( toBinary( newKey ), "MD5" ), "hex" ) );

				// Copy file with new encryption key
				var o = s3.copyObject(
					fromBucket          = testBucket,
					fromURI             = "encrypted.txt",
					toBucket            = testBucket,
					toURI               = "encrypted-copy.txt",
					encryptionKey       = newKey,
					encryptionKeySource = key
				);

				var o = s3.getObject(
					bucketName    = testBucket,
					uri           = "encrypted-copy.txt",
					encryptionKey = newKey
				);

				expect( o.error ).toBe( false );
				expect( o.response ).toBe( data );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption-customer-algorithm" );
				expect( o.responseHeader[ "x-amz-server-side-encryption-customer-algorithm" ] ).toBe( "AES256" );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption-customer-key-MD5" );
				expect( o.responseHeader[ "x-amz-server-side-encryption-customer-key-MD5" ] ).toBe( keyMD5 );
			} );

			it( "can rename encrypted file with custom encryption key", function(){
				var data   = "Hello, encrypted world!";
				var key    = generateSecretKey( "AES", 256 );
				var keyMD5 = toBase64( binaryDecode( hash( toBinary( key ), "MD5" ), "hex" ) );
				// Store file with original encryption key
				s3.putObject(
					bucketName    = testBucket,
					uri           = "encrypted.txt",
					data          = data,
					encryptionKey = key
				);

				// Copy file with new encryption key
				var o = s3.renameObject(
					oldBucketName = testBucket,
					oldFileKey    = "encrypted.txt",
					newBucketName = testBucket,
					newFileKey    = "encrypted-copy.txt",
					encryptionKey = key
				);

				var o = s3.getObject(
					bucketName    = testBucket,
					uri           = "encrypted-copy.txt",
					encryptionKey = key
				);

				expect( o.error ).toBe( false );
				expect( o.response ).toBe( data );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption-customer-algorithm" );
				expect( o.responseHeader[ "x-amz-server-side-encryption-customer-algorithm" ] ).toBe( "AES256" );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption-customer-key-MD5" );
				expect( o.responseHeader[ "x-amz-server-side-encryption-customer-key-MD5" ] ).toBe( keyMD5 );
			} );

			it( "can put encrypted with custom encryption key and custom algorithm", function(){
				var data   = "Hello, encrypted world!";
				var key    = generateSecretKey( "AES", 256 );
				var keyMD5 = toBase64( binaryDecode( hash( toBinary( key ), "MD5" ), "hex" ) );
				s3.putObject(
					bucketName          = testBucket,
					uri                 = "encrypted.txt",
					data                = data,
					encryptionKey       = key,
					encryptionAlgorithm = "AES256"
				);
				var o = s3.getObject(
					bucketName          = testBucket,
					uri                 = "encrypted.txt",
					encryptionKey       = key,
					encryptionAlgorithm = "AES256"
				);

				expect( o.error ).toBe( false );
				expect( o.response ).toBe( data );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption-customer-algorithm" );
				expect( o.responseHeader[ "x-amz-server-side-encryption-customer-algorithm" ] ).toBe( "AES256" );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption-customer-key-MD5" );
				expect( o.responseHeader[ "x-amz-server-side-encryption-customer-key-MD5" ] ).toBe( keyMD5 );

				var o = s3.getObjectInfo(
					bucketName          = testBucket,
					uri                 = "encrypted.txt",
					encryptionKey       = key,
					encryptionAlgorithm = "AES256"
				);

				expect( o ).toHaveKey( "x-amz-server-side-encryption-customer-algorithm" );
				expect( o[ "x-amz-server-side-encryption-customer-algorithm" ] ).toBe( "AES256" );
				expect( o ).toHaveKey( "x-amz-server-side-encryption-customer-key-MD5" );
				expect( o[ "x-amz-server-side-encryption-customer-key-MD5" ] ).toBe( keyMD5 );

				var filePath = expandPath( "/tests/tmp/example.txt" );
				var o        = s3.downloadObject(
					bucketName          = testBucket,
					uri                 = "encrypted.txt",
					filepath            = filePath,
					encryptionKey       = key,
					encryptionAlgorithm = "AES256"
				);

				expect( o ).toHaveKey( "error" );
				expect( o.error ).toBe( false );

				// Lucee doesn't return headers AND direct download a file because it's dumb
				// https://luceeserver.atlassian.net/browse/LDEV-4357
				if ( isNull( server.lucee ) ) {
					expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption-customer-algorithm" );
					expect( o.responseHeader[ "x-amz-server-side-encryption-customer-algorithm" ] ).toBe( "AES256" );
					expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption-customer-key-MD5" );
					expect( o.responseHeader[ "x-amz-server-side-encryption-customer-key-MD5" ] ).toBe( keyMD5 );
				}
				expect( fileRead( filePath ) ).toBe( data );
			} );


			it( "can use default encryption algorithm", function(){
				var data = "Hello, encrypted world!";
				s3.setDefaultEncryptionAlgorithm( "AES256" );

				s3.putObject(
					bucketName = testBucket,
					uri        = "encrypted.txt",
					data       = data
				);
				var o = s3.getObject( bucketName = testBucket, uri = "encrypted.txt" );

				expect( o.error ).toBe( false );
				expect( o.response ).toBe( data );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption" );
				expect( o.responseHeader[ "x-amz-server-side-encryption" ] ).toBe( "AES256" );

				var o = s3.getObjectInfo( bucketName = testBucket, uri = "encrypted.txt" );
				expect( o ).toHaveKey( "x-amz-server-side-encryption" );
				expect( o[ "x-amz-server-side-encryption" ] ).toBe( "AES256" );


				var presignedURL = s3.getAuthenticatedURL( bucketName = testBucket, uri = "encrypted.txt" );
				cfhttp( url = "#presignedURL#", result = "local.httpResponse" );

				expect( local.httpResponse.Responseheader.status_code ?: 0 ).toBe( "200", local.httpResponse.fileContent );
				expect( local.httpResponse.fileContent ).toBe( data );

				var o = s3.copyObject(
					fromBucket = testBucket,
					fromURI    = "encrypted.txt",
					toBucket   = testBucket,
					toURI      = "encrypted-copy.txt"
				);
				var o = s3.getObject( bucketName = testBucket, uri = "encrypted-copy.txt" );

				expect( o.error ).toBe( false );
				expect( o.response ).toBe( data );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption" );
				expect( o.responseHeader[ "x-amz-server-side-encryption" ] ).toBe( "AES256" );

				var o = s3.renameObject(
					oldBucketName = testBucket,
					oldFileKey    = "encrypted.txt",
					newBucketName = testBucket,
					newFileKey    = "encrypted2.txt"
				);
				var o = s3.getObject( bucketName = testBucket, uri = "encrypted2.txt" );

				expect( o.error ).toBe( false );
				expect( o.response ).toBe( data );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption" );
				expect( o.responseHeader[ "x-amz-server-side-encryption" ] ).toBe( "AES256" );

				s3.setDefaultEncryptionAlgorithm( "" );
			} );



			it( "can use default encryption key", function(){
				var data   = "Hello, encrypted world!";
				var key    = generateSecretKey( "AES", 256 );
				var keyMD5 = toBase64( binaryDecode( hash( toBinary( key ), "MD5" ), "hex" ) );
				s3.setDefaultEncryptionKey( key );

				s3.putObject(
					bucketName = testBucket,
					uri        = "encrypted.txt",
					data       = data
				);
				var o = s3.getObject( bucketName = testBucket, uri = "encrypted.txt" );

				expect( o.error ).toBe( false );
				expect( o.response ).toBe( data );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption-customer-algorithm" );
				expect( o.responseHeader[ "x-amz-server-side-encryption-customer-algorithm" ] ).toBe( "AES256" );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption-customer-key-MD5" );
				expect( o.responseHeader[ "x-amz-server-side-encryption-customer-key-MD5" ] ).toBe( keyMD5 );

				var o = s3.getObjectInfo( bucketName = testBucket, uri = "encrypted.txt" );
				expect( o ).toHaveKey( "x-amz-server-side-encryption-customer-algorithm" );
				expect( o[ "x-amz-server-side-encryption-customer-algorithm" ] ).toBe( "AES256" );
				expect( o ).toHaveKey( "x-amz-server-side-encryption-customer-key-MD5" );
				expect( o[ "x-amz-server-side-encryption-customer-key-MD5" ] ).toBe( keyMD5 );


				var presignedURL = s3.getAuthenticatedURL( bucketName = testBucket, uri = "encrypted.txt" );
				cfhttp( url = "#presignedURL#", result = "local.httpResponse" ) {
					cfhttpparam(
						type  = "header",
						name  = "x-amz-server-side-encryption-customer-algorithm",
						value = "AES256"
					);
					cfhttpparam(
						type  = "header",
						name  = "x-amz-server-side-encryption-customer-key",
						value = key
					);
					cfhttpparam(
						type  = "header",
						name  = "x-amz-server-side-encryption-customer-key-MD5",
						value = keyMD5
					);
				};

				expect( local.httpResponse.Responseheader.status_code ?: 0 ).toBe( "200", local.httpResponse.fileContent );
				expect( local.httpResponse.fileContent ).toBe( data );

				var o = s3.copyObject(
					fromBucket = testBucket,
					fromURI    = "encrypted.txt",
					toBucket   = testBucket,
					toURI      = "encrypted-copy.txt"
				);
				var o = s3.getObject( bucketName = testBucket, uri = "encrypted-copy.txt" );

				expect( o.error ).toBe( false );
				expect( o.response ).toBe( data );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption-customer-algorithm" );
				expect( o.responseHeader[ "x-amz-server-side-encryption-customer-algorithm" ] ).toBe( "AES256" );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption-customer-key-MD5" );
				expect( o.responseHeader[ "x-amz-server-side-encryption-customer-key-MD5" ] ).toBe( keyMD5 );

				var o = s3.renameObject(
					oldBucketName = testBucket,
					oldFileKey    = "encrypted.txt",
					newBucketName = testBucket,
					newFileKey    = "encrypted2.txt"
				);
				var o = s3.getObject( bucketName = testBucket, uri = "encrypted2.txt" );

				expect( o.error ).toBe( false );
				expect( o.response ).toBe( data );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption-customer-algorithm" );
				expect( o.responseHeader[ "x-amz-server-side-encryption-customer-algorithm" ] ).toBe( "AES256" );
				expect( o.responseHeader ).toHaveKey( "x-amz-server-side-encryption-customer-key-MD5" );
				expect( o.responseHeader[ "x-amz-server-side-encryption-customer-key-MD5" ] ).toBe( keyMD5 );

				s3.setDefaultEncryptionKey( "" );
			} );
		} );
	}

	private function createLogStub(){
		return createStub()
			.$( "canDebug", false )
			.$( "debug" )
			.$( "error" )
			.$( "warn" );
	}

	/**
	 * Boxlang uses java.nio which is non blocking so file operations may take a few ms to complete.
	 */
	function sleepIfNIO( duration = 50 ){
		if ( getMetadata( this ).name == "LocalProvider" && server.keyExists( "boxlang" ) ) {
			sleep( duration );
		}
	}

}

component extends="coldbox.system.testing.BaseTestCase" {

	variables.targetEngine = getUtil().getSystemSetting( "ENGINE", "localhost" );
	variables.testBucket   = "ortus2-s3sdk-bdd-#replace( variables.targetEngine, "@", "-" )#";

	function beforeAll(){
		prepTmpFolder();

		variables.s3 = new s3sdk.models.AmazonS3(
			accessKey = getUtil().getSystemSetting( "AWS_ACCESS_KEY" ),
			secretKey = getUtil().getSystemSetting( "AWS_ACCESS_SECRET" ),
			awsRegion = getUtil().getSystemSetting( "AWS_REGION" ),
			awsDomain = getUtil().getSystemSetting( "AWS_DOMAIN" )
		);
		prepareMock( s3 );
		s3.$property( propertyName = "log", mock = createLogStub() );

		try {
			s3.putBucket( testBucket );
		} catch ( any e ) {
			writeDump(
				var    = "Error putting test bucket, maybe cached: #e.message# #e.detail#",
				output = "console"
			);
		}
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
					s3.deleteObject( testBucket, "emptyFolder/" );
					s3.deleteObject( testBucket, "exam%20p   le (fo%2Fo)+,!@##$%^&*()_+~ ;:.txt" );

					// Avoid these on cf11,2016 because their http sucks!
					if ( !isOldACF() ) {
						s3.deleteObject( testBucket, "Word Doc Tests.txt" );
					}
					s3.setDefaultBucketName( "" );
				} );

				it( "can store a new object", function(){
					s3.putObject( bucketName=testBucket, uri="example.txt", data="Hello, world!", contentType="auto" );
					var md = s3.getObjectInfo( testBucket, "example.txt" );
					debug( md );
					expect( md ).notToBeEmpty();
					expect( md[ 'Content-Type' ] ).toBe( 'text/plain' );
				} );

				it( "can store a new object from file", function(){
					var filePath = expandPath( "/tests/tmp/example.txt" );
					fileWrite( filePath, "file contents" );
					s3.putObject( bucketName=testBucket, uri="example.txt", filepath=filePath, contentType="auto" );
					var md = s3.getObjectInfo( testBucket, "example.txt" );
					//debug( md );
					expect( md ).notToBeEmpty();
					expect( md[ 'Content-Type' ] ).toBe( 'text/plain' );
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
						//debug( md );
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
					expect( ACL[ "x-amz-grant-full-control" ] ).toBe( "id=""12345"", uri=""http://acs.amazonaws.com/groups/global/AllUsers"", emailAddress=""xyz@amazon.com""" );
					expect( ACL ).toHaveKey( "x-amz-grant-write" );
					expect( ACL[ "x-amz-grant-write" ] ).toBe( "id=""12345"", uri=""http://acs.amazonaws.com/groups/global/AllUsers"", emailAddress=""xyz@amazon.com""" );
					expect( ACL ).toHaveKey( "x-amz-grant-write" );
					expect( ACL[ "x-amz-grant-write" ] ).toBe( "id=""12345"", uri=""http://acs.amazonaws.com/groups/global/AllUsers"", emailAddress=""xyz@amazon.com""" );
					expect( ACL ).toHaveKey( "x-amz-grant-read" );
					expect( ACL[ "x-amz-grant-read" ] ).toBe( "id=""12345"", uri=""http://acs.amazonaws.com/groups/global/AllUsers"", emailAddress=""xyz@amazon.com""" );
					expect( ACL ).toHaveKey( "x-amz-grant-read-acp" );
					expect( ACL[ "x-amz-grant-read-acp" ] ).toBe( "id=""12345"", uri=""http://acs.amazonaws.com/groups/global/AllUsers"", emailAddress=""xyz@amazon.com""" );
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
			} );

			describe( "Presigned URL", function(){
				afterEach( function( currentSpec ){
					// Add any test fixtures here that you create below
					s3.deleteObject( testBucket, "example.txt" );
					s3.deleteObject( testBucket, "presignedput.txt" );
					s3.deleteObject( testBucket, "presignedputfriends.txt" );
					s3.deleteObject( testBucket, "presignedputacl.txt" );
				} );

				it( "can access via get", function(){
					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					var presignedURL = s3.getAuthenticatedURL( bucketName = testBucket, uri = "example.txt" );
					cfhttp( url = "#presignedURL#", result = "local.cfhttp" );

					expect( local.cfhttp.Responseheader.status_code ?: 0 ).toBe( "200", local.cfhttp.fileContent );
					expect( local.cfhttp.fileContent ).toBe( "Hello, world!" );
				} );

				it( "can expire", function(){
					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					var presignedURL = s3.getAuthenticatedURL(
						bucketName   = testBucket,
						uri          = "example.txt",
						minutesValid = 1 / 60
					);
					sleep( 2000 )
					cfhttp( url = "#presignedURL#", result = "local.cfhttp" );

					expect( local.cfhttp.Responseheader.status_code ?: 0 ).toBe( "403", local.cfhttp.fileContent );
					expect( local.cfhttp.fileContent ).toMatch( "expired" );
				} );

				it( "cannot PUT with a GET URL", function(){
					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					var presignedURL = s3.getAuthenticatedURL( bucketName = testBucket, uri = "example.txt" );

					cfhttp(
						url    = "#presignedURL#",
						result = "local.cfhttp",
						method = "PUT"
					) {
						cfhttpparam( type = "body", value = "Pre-Signed Put!" );
					};

					// If a presigned URL is created for a GET operation, it can't be used for anything else!
					expect( local.cfhttp.Responseheader.status_code ?: 0 ).toBe( "403", local.cfhttp.fileContent );
				} );

				it( "can put file", function(){
					var presignedURL = s3.getAuthenticatedURL(
						bucketName = testBucket,
						uri        = "presignedput.txt",
						method     = "PUT"
					);
					cfhttp(
						url    = "#presignedURL#",
						result = "local.cfhttp",
						method = "PUT"
					) {
						cfhttpparam( type = "body", value = "Pre-Signed Put!" );
					};
					expect( local.cfhttp.Responseheader.status_code ?: 0 ).toBe( "200", local.cfhttp.fileContent );

					var get = s3.getObject( testBucket, "presignedput.txt" );

					expect( get.error ).toBeFalse();
					// toString() since there is no content type set in thnis test, Adobe doesn't send back the file as a string, but a byte output stream
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
						result = "local.cfhttp",
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
					expect( local.cfhttp.Responseheader.status_code ?: 0 ).toBe( "200", local.cfhttp.fileContent );

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
						result = "local.cfhttp",
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
					expect( local.cfhttp.Responseheader.status_code ?: 0 ).toBe( "403", local.cfhttp.fileContent );
				} );
			} );
		} );
	}

	private function createLogStub(){
		return createStub()
			.$( "canDebug", false )
			.$( "debug" )
			.$( "error" );
	}

}

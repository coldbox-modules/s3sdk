component extends="coldbox.system.testing.BaseTestCase" {

	variables.targetEngine = getUtil().getSystemSetting( "ENGINE", "localhost" );
	variables.testBucket   = "ortus-s3sdk-bdd-#replace( variables.targetEngine, "@", "-" )#";

	function beforeAll() {
		variables.s3 = new s3sdk.models.AmazonS3(
			accessKey = getUtil().getSystemSetting( "AWS_ACCESS_KEY" ),
			secretKey = getUtil().getSystemSetting( "AWS_ACCESS_SECRET" ),
			awsRegion = getUtil().getSystemSetting( "AWS_REGION" ),
			awsDomain = getUtil().getSystemSetting( "AWS_DOMAIN" )
		);
		prepareMock( s3 );
		s3.$property( propertyName = "log", mock = createLogStub() );

		s3.putBucket( testBucket );
	}

	function afterAll() {
		try {
			s3.deleteBucket( bucketName = testBucket, force = true );
		} catch ( any e ) {
		}
	}

	private function isOldACF(){
		var isLucee = StructKeyExists(server, 'lucee');
		return !isLucee and listFind( "11,2016", listFirst( server.coldfusion.productVersion ) );
	}

	function run() {
		describe( "Amazon S3 SDK", function() {
			describe( "objects", function() {
				afterEach( function( currentSpec ) {
					// Add any test fixtures here that you create below
					s3.deleteObject( testBucket, "example.txt" );
					s3.deleteObject( testBucket, "example-2.txt" );
					s3.deleteObject( testBucket, "testFolder/example.txt" );
					s3.deleteObject( testBucket, "emptyFolder/" );

					// Avoid these on cf11,2016 because their http sucks!
					if ( !isOldACF() ) {
						s3.deleteObject( testBucket, "Word Doc Tests.txt" );
					}
					s3.setDefaultBucketName( "" );
				} );

				it( "can store a new object", function() {
					s3.putObject(
						testBucket,
						"example.txt",
						"Hello, world!"
					);
					var md = s3.getObjectInfo( testBucket, "example.txt" );
					debug( md );
					expect( md ).notToBeEmpty();
				} );

				it(
					title = "can store a new object with spaces in the name",
					skip  = isOldACF(),
					body  = function() {
						s3.putObject(
							testBucket,
							"Word Doc Tests.txt",
							"Hello, space world!"
						);
						var md = s3.getObjectInfo( testBucket, "Word Doc Tests.txt" );
						debug( md );
						expect( md ).notToBeEmpty();
					}
				);

				it( "can list all objects", function() {
					s3.putObject(
						testBucket,
						"example.txt",
						"Hello, world!"
					);
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

				it( "can list with prefix", function() {
					s3.putObject(
						testBucket,
						"example.txt",
						"Hello, world!"
					);
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

				it( "can list with and without delimter", function() {
					s3.putObject(
						testBucket,
						"example.txt",
						"Hello, world!"
					);
					s3.putObject(
						testBucket,
						"testFolder/example.txt",
						"Hello, world!"
					);

					// With no delimiter, there is no concept of folders, so all keys just show up and everything is a "file"
					var bucketContents = s3.getBucket( bucketName = testBucket, delimiter = "" );
					expect( bucketContents ).toBeArray();
					expect( bucketContents ).toHaveLength( 2 );

					bucketContents.each( function( item ) {
						expect( item.isDirectory ).toBeFalse();
					} );

					// With a delimiter of "/", we only get the top level items and "testFolder" shows as a directory
					var bucketContents = s3.getBucket( bucketName = testBucket, delimiter = "/" );
					expect( bucketContents ).toBeArray();
					expect( bucketContents ).toHaveLength( 2 );

					bucketContents.each( function( item ) {
						if ( item.key == "testFolder" ) {
							expect( item.isDirectory ).toBeTrue();
						} else {
							expect( item.isDirectory ).toBeFalse();
						}
					} );
				} );

				it( "can check if an object exists", function() {
					s3.putObject(
						testBucket,
						"example.txt",
						"Hello, world!"
					);
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

				it( "can delete an object from a bucket", function() {
					s3.putObject(
						testBucket,
						"example.txt",
						"Hello, world!"
					);
					s3.deleteObject( testBucket, "example.txt" );
					var bucketContents = s3.getBucket( testBucket );
					expect( bucketContents ).toBeArray();
					expect( bucketContents ).toHaveLength( 0 );
				} );

				it( "can copy an object", function() {
					s3.putObject(
						testBucket,
						"example.txt",
						"Hello, world!"
					);
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

				it( "can rename an object", function() {
					s3.putObject(
						testBucket,
						"example.txt",
						"Hello, world!"
					);
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

				it( "can get a file", function() {
					s3.putObject(
						testBucket,
						"example.txt",
						"Hello, world!"
					);
					var get = s3.getObject( testBucket, "example.txt" );
					expect( get.error ).toBeFalse();
					expect( get.response ).toBe( "Hello, world!" );
				} );

				it( "can download a file", function() {
					s3.putObject(
						testBucket,
						"example.txt",
						"Hello, world!"
					);
					var dl = s3.downloadObject(
						testBucket,
						"example.txt",
						"ram:///example.txt"
					);
					debug( dl );
					expect( dl ).notToBeEmpty();
					expect( dl.error ).toBeFalse();
				} );

				it( "validates missing bucketname", function() {
					expect( function() {
						s3.getBucket();
					} ).toThrow( message = "bucketName is required" );
				} );

				it( "Allows default bucket name", function() {
					s3.setDefaultBucketName( testBucket );
					s3.getBucket();
				} );

				it( "Allows default delimiter", function() {
					s3.setDefaultDelimiter( "/" );

					s3.putObject(
						testBucket,
						"example.txt",
						"Hello, world!"
					);
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

				it( "generates a valid authenticated URL", function() {
					var testFileContents = "Hello, world!";
					s3.putObject( testBucket, "example.txt", testFileContents );

					var authedURL = s3.getAuthenticatedURL( bucketName=testBucket, uri="example.txt" );

					var httpSvc = new http();
					httpSvc.setMethod("get");
					httpSvc.setUrl(authedURL);
					var response = httpSvc.send().getPrefix();
					expect( response.fileContent ).toBe( testFileContents );
				} );
			} );

			describe( "buckets", function() {
				it( "returns true if a bucket exists", function() {
					expect( s3.hasBucket( testBucket ) ).toBeTrue();
				} );
				it( "can list the buckets associated with the account", function() {
					expect( arrayLen( s3.listBuckets() ) ).toBeGTE( 1, "At least one bucket should be returned" );
				} );
				it( "can delete a bucket", function() {
					expect( s3.hasBucket( testBucket ) ).toBeTrue();
					var results = s3.deleteBucket( testBucket );
					expect( results ).toBeTrue();
				} );
			} );
		} );
	}

	private function createLogStub() {
		return createStub()
			.$( "canDebug", false )
			.$( "debug" )
			.$( "error" );
	}

}

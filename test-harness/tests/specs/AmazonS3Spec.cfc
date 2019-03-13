component extends="coldbox.system.testing.BaseTestCase" {

	variables.targetEngine = getUtil().getSystemSetting( "ENGINE", "localhost" );
    variables.testBucket = "ortus-s3sdk-bdd-bucket-#replace( variables.targetEngine, "@", "-" )#";

    function beforeAll() {
        variables.s3 = new s3sdk.models.AmazonS3(
            getUtil().getSystemSetting( "AWS_ACCESS_KEY" ),
            getUtil().getSystemSetting( "AWS_ACCESS_SECRET" ),
            getUtil().getSystemSetting( "AWS_REGION" ),
            getUtil().getSystemSetting( "AWS_DOMAIN" )
        );
        prepareMock( s3 );
		s3.$property( propertyName = "log", mock = createLogStub() );

		s3.putBucket( testBucket );
    }

    function afterAll() {
		s3.deleteBucket( bucketName = testBucket, force = true );
	}

    function run() {
        describe( "Amazon S3 SDK", function() {

			describe( "objects", function() {
				afterEach(function( currentSpec ){
					s3.deleteObject( testBucket, "example.txt" );
					s3.deleteObject( testBucket, "example-2.txt" );
				});

                it( "can store a new object", function() {
					s3.putObject( testBucket, "example.txt", "Hello, world!" );
					var md = s3.getObjectInfo( testBucket, "example.txt" );
					//debug( md );
					expect( md ).notToBeEmpty();
                } );

                it( "can list all objects", function() {
                    s3.putObject( testBucket, "example.txt", "Hello, world!" );
                    var bucketContents = s3.getBucket( testBucket );
                    expect( bucketContents ).toBeArray();
                    expect( bucketContents ).toHaveLength( 1 );
                } );

                it( "can delete an object from a bucket", function() {
                    s3.putObject( testBucket, "example.txt", "Hello, world!" );
                    s3.deleteObject( testBucket, "example.txt" );
					var bucketContents = s3.getBucket( testBucket );
                    expect( bucketContents ).toBeArray();
                    expect( bucketContents ).toHaveLength( 0 );
                } );

                it( "can copy an object", function() {
                    s3.putObject( testBucket, "example.txt", "Hello, world!" );
                    var bucketContents = s3.getBucket( testBucket );
                    expect( bucketContents[ 1 ].key ).toBe( "example.txt" );

                    s3.copyObject( testBucket, "example.txt", testBucket, "example-2.txt" );

                    var bucketContents = s3.getBucket( testBucket );
                    expect( bucketContents ).toHaveLength( 2 );
                } );

                it( "can rename an object", function() {
                    s3.putObject( testBucket, "example.txt", "Hello, world!" );
                    s3.renameObject( testBucket, "example.txt", testBucket, "example-2.txt" );

                    var bucketContents = s3.getBucket( testBucket );
                    expect( bucketContents ).toHaveLength( 1 );
                    expect( bucketContents[ 1 ].key ).toBe( "example-2.txt" );
                } );
			} );

            describe( "buckets", function() {
                it( "returns true if a bucket exists", function() {
                    expect( s3.hasBucket( testBucket ) ).toBeTrue();
				} );
				it( "can list the buckets associated with the account", function() {
					expect( arrayLen( s3.listBuckets() ) )
						.toBeGTE( 1, "At least one bucket should be returned" );
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
            .$( "debug" );
    }

}

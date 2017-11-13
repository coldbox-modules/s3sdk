component extends="testbox.system.BaseSpec" {

    variables.testBucket = "ortus-s3sdk-test-bucket";

    function beforeAll() {
        var system = createObject( "java", "java.lang.System" );
        variables.s3 = new S3SDK.AmazonS3(
            system.getProperty( "S3_ACCESS_KEY" ),
            system.getProperty( "S3_SECRET_KEY" )
        );
        prepareMock( s3 );
        s3.$property( propertyName = "log", mock = createLogStub() );
    }

    function afterAll() {
        if ( s3.hasBucket( testBucket ) ) {
            s3.deleteBucket( bucketName = testBucket, force = true );
        }
    }

    function run() {
        describe( "Amazon S3 SDK", function() {
            describe( "buckets", function() {
                beforeEach( function() {
                    if ( s3.hasBucket( testBucket ) ) {
                        s3.deleteBucket( bucketName = testBucket, force = true );
                    }
                } );

                it( "can create a new bucket", function() {
                    expect( function() {
                        s3.getBucket( testBucket )
                    } ).toThrow( regex = "Error making Amazon REST Call" );
                    s3.putBucket( testBucket );
                    expect( function() {
                        s3.getBucket( testBucket )
                    } ).notToThrow( regex = "Error making Amazon REST Call" );
                } );

                it( "returns true if a bucket exists", function() {
                    expect( s3.hasBucket( testBucket ) ).toBeFalse();
                    s3.putBucket( testBucket );
                    expect( s3.hasBucket( testBucket ) ).toBeTrue();
                } );

                it( "can delete a bucket", function() {
                    expect( s3.hasBucket( testBucket ) ).toBeFalse();
                    expect( function() {
                        s3.deleteBucket( testBucket );
                    } ).toThrow( regex = "Error making Amazon REST Call" );
                    s3.putBucket( testBucket );
                    expect( s3.hasBucket( testBucket ) ).toBeTrue();
                    s3.deleteBucket( testBucket );
                    expect( s3.hasBucket( testBucket ) ).toBeFalse();
                } );

                it( "can list the buckets associated with the account", function() {
                    s3.putBucket( testBucket );
                    expect( arrayLen( s3.listBuckets() ) ).toBeGTE( 1, "At least one bucket should be returned" );
                } );
            } );

            describe( "objects", function() {
                beforeEach( function() {
                    if ( s3.hasBucket( testBucket ) ) {
                        s3.deleteBucket( testBucket, true );
                    }
                    s3.putBucket( testBucket );
                } );

                it( "can store a new object", function() {
                    s3.putObject( testBucket, "example.txt", "Hello, world!" );
                    // writeDump( var = s3.getObjectInfo( "example.txt" ), top = 2, abort = true );
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
                    expect( bucketContents ).toBeArray();
                    expect( bucketContents ).toHaveLength( 1 );
                    expect( bucketContents[ 1 ].key ).toBe( "example.txt" );
                    expect( bucketContents[ 1 ].size ).toBe( 13 );

                    s3.copyObject( testBucket, "example.txt", testBucket, "example-2.txt" );

                    var bucketContents = s3.getBucket( testBucket );
                    expect( bucketContents ).toBeArray();
                    expect( bucketContents ).toHaveLength( 2 );
                    expect( bucketContents[ 1 ].size ).toBe( 13 );
                    expect( bucketContents[ 2 ].size ).toBe( 13 );
                } );

                it( "can rename an object", function() {
                    s3.putObject( testBucket, "example.txt", "Hello, world!" );
                    var bucketContents = s3.getBucket( testBucket );
                    expect( bucketContents ).toBeArray();
                    expect( bucketContents ).toHaveLength( 1 );
                    expect( bucketContents[ 1 ].key ).toBe( "example.txt" );
                    expect( bucketContents[ 1 ].size ).toBe( 13 );

                    s3.renameObject( testBucket, "example.txt", testBucket, "example-2.txt" );

                    var bucketContents = s3.getBucket( testBucket );
                    expect( bucketContents ).toBeArray();
                    expect( bucketContents ).toHaveLength( 1 );
                    expect( bucketContents[ 1 ].key ).toBe( "example-2.txt" );
                    expect( bucketContents[ 1 ].size ).toBe( 13 );
                } );
            } );
        } );
    }

    private function createLogStub() {
        return createStub()
            .$( "debug" );
    }

}

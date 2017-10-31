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
            s3.deleteBucket( testBucket );
        }
    }

    function run() {
        describe( "Amazon S3 SDK", function() {
            beforeEach( function() {
                if ( s3.hasBucket( testBucket ) ) {
                    s3.deleteBucket( testBucket );
                }
            } );

            describe( "buckets", function() {
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
        } );
    }

    private function createLogStub() {
        return createStub()
            .$( "debug" );
    }

}

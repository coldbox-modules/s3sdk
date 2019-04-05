/**
 ********************************************************************************
 * Copyright 2005-2007 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
 ********************************************************************************
 *
 * Amazon S3 REST Wrapper
 *
 * Written by Joe Danziger (joe@ajaxcf.com) with much help from
 * dorioo on the Amazon S3 Forums.  See the readme for more
 * details on usage and methods.
 * Thanks to Steve Hicks for the bucket ACL updates.
 * Thanks to Carlos Gallupa for the EU storage location updates.
 * Thanks to Joel Greutman for the fix on the getObject link.
 * Thanks to Jerad Sloan for the Cache Control headers.
 *
 * Version 1.7 - Released: December 15, 2008
 * Version 2.0 - Luis Majano updated for ColdBox and extra features.
 *
 * You will have to create some settings in your ColdBox configuration file:
 *
 * s3_accessKey : The Amazon access key
 * s3_secretKey : The Amazon secret key
 * s3_encryption_charset : encryptyion charset (Optional, defaults to utf-8)
 * s3_ssl : Whether to use ssl on all cals or not (Optional, defaults to false)
 */
component accessors="true" singleton {

    // DI
    property name="log" inject="logbox:logger:{this}";

    // Properties
    property name="accessKey";
    property name="secretKey";
    property name="encryption_charset";
    property name="ssl";
	property name="URLEndpoint";
	property name="awsRegion";
	property name="awsDomain";
	property name="defaultDelimiter";
	property name="defaultBucketName";

    // STATIC Contsants
    this.ACL_PRIVATE 			= "private";
    this.ACL_PUBLIC_READ 		= "public-read";
    this.ACL_PUBLIC_READ_WRITE 	= "public-read-write";
    this.ACL_AUTH_READ 			= "authenticated-read";

    /**
     * Create a new S3SDK Instance
     *
     * @accessKey The Amazon access key.
     * @secretKey The Amazon secret key.
	 * @awsRegion The Amazon region. Defaults to us-east-1
	 * @awsDomain The Domain used S3 Service (amazonws.com, digitalocean.com). Defaults to amazonws.com
     * @encryption_charset The charset for the encryption. Defaults to UTF-8.
     * @ssl True if the request should use SSL. Defaults to true.
     * @defaultDelimiter Delimter to use for getBucket calls. "/" is standard to treat keys as file paths
     * @defaultBucketName Bucket name to use by default
     *
     * @return An AmazonS3 instance.
     */
    AmazonS3 function init(
        required string accessKey,
		required string secretKey,
		string awsRegion = "us-east-1",
		string awsDomain = "amazonaws.com",
        string encryption_charset = "UTF-8",
        boolean ssl = true,
        string defaultDelimiter='/',
	    string defaultBucketName=''
    ) {
        variables.accessKey          = arguments.accessKey;
        variables.secretKey          = arguments.secretKey;
        variables.encryption_charset = arguments.encryption_charset;
		variables.awsRegion          = arguments.awsRegion;
		variables.awsDomain          = arguments.awsDomain;
		variables.defaultDelimiter   = arguments.defaultDelimiter;
		variables.defaultBucketName  = arguments.defaultBucketName;

		// Construct the SSL Domain
		setSSL( arguments.ssl );

		// Build out the endpoint URL
		buildUrlEndpoint();

		// Build signature utility
        variables.sv4Util = new Sv4Util(
            accessKeyId        = variables.accessKey,
            secretAccessKey    = variables.secretKey,
            defaultRegionName  = arguments.awsRegion,
            defaultServiceName = "s3"
		);

        return this;
    }

    /**
     * Set the Amazon Credentials.
     *
     * @accessKey The Amazon access key.
     * @secretKey The Amazon secret key.
     *
     * @return    The AmazonS3 Instance.
     */
    AmazonS3 function setAuth( required string accessKey, required string secretKey ) {
        variables.accessKey = arguments.accessKey;
        variables.secretKey = arguments.secretKey;
        return this;
	}

	/**
	 * This function builds the variables.UrlEndpoint according to credentials and ssl configuration, usually called after init() for you automatically.
	 */
	AmazonS3 function buildUrlEndpoint(){
		// Build accordingly
		var URLEndPointProtocol = ( variables.ssl ) ? "https://" : "http://";
		variables.URLEndpoint	=  ( variables.awsDomain contains 'amazonaws.com' ) ?
									'#URLEndPointProtocol#s3.#variables.awsRegion#.#variables.awsDomain#' :
									'#URLEndPointProtocol##variables.awsDomain#';
		return this;
	}

    /**
     * Set the ssl flag.
     * Alters the internal URL endpoint accordingly.
     *
     * @useSSL True if SSL should be used for the requests.
     *
     * @return The AmazonS3 instance.
     */
    AmazonS3 function setSSL( boolean useSSL = true ) {
		variables.ssl = arguments.useSSL;
        return this;
    }

    /**
     * @deprecated
     * Create a v2 signature to sign the request.
     *
     * @stringToSign The string to sign for the request.
     *
     * @return A signed string to send with the request.
     */
    string function createSignature( required string stringToSign ) {
        return toBase64( HMAC_SHA1(
            variables.secretKey,
            replace( arguments.stringToSign, "\n", "#chr( 10 )#", "all" )
        ) );
    }

    /**
     * List all the buckets associated with the Amazon credentials.
     *
     * @return
     */
    array function listBuckets() {
        var results = S3Request();

        var bucketsXML = xmlSearch( results.response, "//*[local-name()='Bucket']" );

        return arrayMap( bucketsXML, function( node ) {
            return {
                "name"         = trim( node.name.xmlText ),
                "creationDate" = trim( node.creationDate.xmlText )
            };
        } );
    }

    /**
     * Get the S3 region for the bucket provided.
     *
     * @bucketName The bucket for which to fetch the region.
     *
     * @return     The region code for the bucket.
     */
    string function getBucketLocation( required string bucketName=variables.defaultBucketName ) {
        requireBucketName( arguments.bucketName );
        var results = S3Request( resource = arguments.bucketname & "?location" );

        if ( results.error ) {
            throw( message="Error making Amazon REST Call", detail=results.message );
        }

        if ( len( results.response.LocationConstraint.XMLText ) ) {
            return results.response.LocationConstraint.XMLText;
        }

        return "US";
    }

    /**
     * Get the versioning status of a bucket.
     *
     * @bucketName The bucket for which to fetch the versioning status.
     *
     * @return     The bucket version status or an empty string if there is none.
     */
    string function getBucketVersionStatus( required string bucketName=variables.defaultBucketName ) {
        requireBucketName( arguments.bucketName );
        var results = S3Request( resource = arguments.bucketname & "?versioning" );

        var status = xmlSearch( results.response, "//*[local-name()='VersioningConfiguration']//*[local-name()='Status']/*[1]" );

        if ( arrayLen( status ) > 0 ) {
            return status[ 1 ].xmlText;
        }

        return "";
    }

    /**
     * Set versioning status for a bucket.
     *
     * @bucketName The bucket to set the versioning status.
     * @version    The status for the versioning property.
     *
     * @return     True if the request was successful.
     */
    boolean function setBucketVersionStatus( required string bucketName=variables.defaultBucketName, boolean version = true ) {
        requireBucketName( arguments.bucketName );
        var constraintXML 	= "";
        var headers = { "content-type" = "text/plain" };

        if ( arguments.version ) {
            headers[ "?versioning" ] = "";
            constraintXML = '<VersioningConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Status>Enabled</Status></VersioningConfiguration>';
        }

        var results = S3Request(
            method 		= "PUT",
            resource	= arguments.bucketName,
            body 		= constraintXML,
            headers 	= headers,
            amzHeaders	= {}
        );

        return results.responseheader.status_code == 200;
    }

    /**
     * Gets a bucket's or object's ACL policy.
     *
     * @bucketName The bucket to get the ACL.
     * @uri        An optional resource uri to get the ACL.
     *
     * @return     An array containing the ACL for the given resource.
     */
    array function getAccessControlPolicy( required string bucketName=variables.defaultBucketName, string uri = "" ) {
        requireBucketName( arguments.bucketName );
        var resource = arguments.bucketName;

        if ( len( arguments.uri ) ) {
            resource = resource & "\" & arguments.uri;
        }

        var results = S3Request( resource = resource & "?acl" );

        var grantsXML = xmlSearch( results.response, "//*[local-name()='Grant']" );
        return arrayMap( grantsXML, function( node ) {
            return {
                "type" 		  = node.grantee.XMLAttributes[ "xsi:type" ],
                "displayName" = "",
                "permission"  = node.permission.XMLText,
                "uri"         = node.grantee.XMLAttributes[ "xsi:type" ] == "Group" ? node.grantee.uri.xmlText : node.grantee.displayName.xmlText
            };
        } );
    }

    /**
     * Lists information about the objects of a bucket.
     *
     * @bucketName The bucket name to list.
     * @prefix     Limits the response to keys which begin with the indicated prefix, if any.
     * @marker     Indicates where in the bucket to begin listing, if any.
     * @maxKeys    The maximum number of keys you'd like to see in the response body, if any.
     * @delimiter  The delimiter to use in the keys, if any.
     *
     * @return     The bucket contents.
     */
    array function getBucket(
        required string bucketName=variables.defaultBucketName,
        string prefix = "",
        string marker = "",
        string maxKeys = "",
        string delimiter = variables.defaultDelimiter
    ) {
        requireBucketName( arguments.bucketName );
        var parameters = {};

        if ( len( arguments.prefix ) ) {
            parameters[ "prefix" ] = arguments.prefix;
        }

        if ( len( arguments.marker ) ) {
            parameters[ "marker" ] = arguments.marker;
        }

        if ( isNumeric(arguments.maxKeys ) ) {
            parameters[ "max-keys" ] = arguments.maxKeys;
        }

        if ( len( arguments.delimiter ) ) {
            parameters[ "delimiter" ] = arguments.delimiter;
        }

        var results = S3Request(
            resource 	= arguments.bucketName,
            parameters 	= parameters
        );

        var contentsXML = xmlSearch( results.response, "//*[local-name()='Contents']" );
		var foldersXML 	= xmlSearch( results.response, "//*[local-name()='CommonPrefixes']" );

        var objectContents = arrayMap( contentsXML, function( node ) {
            return {
                "key"           = trim( node.key.xmlText ),
                "lastModified"  = trim( node.lastModified.xmlText ),
                "size"          = trim( node.Size.xmlText ),
                "eTag"          = trim( node.etag.xmlText ),
                "isDirectory"   = ( ( findNoCase( "_$folder$", node.key.xmlText ) || ( len( delimiter ) && node.key.xmlText.endsWith( delimiter ) ) ) ? true : false )
            };
        } );

        var folderContents = arrayMap( foldersXML, function( node ) {
            return {
                "key"          = reReplaceNoCase( trim( node.prefix.xmlText ), "\/$", "" ),
                "lastModified" = '',
                "size"         = '',
                "eTag"         = '',
                "isDirectory"  = true
            };
        } );

        arrayAppend( objectContents, folderContents, true );
        return objectContents;
    }

    /**
     * Create a new bucket.
     *
     * @bucketName The name for the new bucket.
     * @acl        The ACL policy for the new bucket.
     * @location   The bucket location.
     *
     * @return     True if the bucket was created successfully.
     */
    boolean function putBucket(
        required string bucketName=variables.defaultBucketName,
        string acl = this.ACL_PUBLIC_READ,
        string location = "USA"
    ) {
        requireBucketName( arguments.bucketName );
        var constraintXML = arguments.location == "EU" ?
            "<CreateBucketConfiguration><LocationConstraint>EU</LocationConstraint></CreateBucketConfiguration>" :
            "";

        var results = S3Request(
            method     = "PUT",
            resource   = arguments.bucketName,
            body       = constraintXML,
            headers    = { "content-type" = "text/xml" },
            amzHeaders = { "x-amz-acl" = arguments.acl }
        );

        return results.responseheader.status_code == 200;
    }

    /**
     * Checks for the existance of a bucket
     *
     * @bucketName The bucket to check for its existance.
     *
     * @return     True if the bucket exists.
     */
    boolean function hasBucket( required string bucketName=variables.defaultBucketName ) {
        requireBucketName( arguments.bucketName );
        return ! arrayIsEmpty( arrayFilter( listBuckets(), function( bucket ) {
            return bucket.name == bucketName;
        } ) );
    }

    /**
     * Deletes a bucket.
     *
     * @bucketName The name of the bucket to delete.
     * @force      If true, delete the contents of the bucket before deleting the bucket.
     *
     * @return     True, if the bucket was deleted successfully.
     */
	boolean function deleteBucket(
        required string bucketName=variables.defaultBucketName,
        boolean force = false
    ) {
        requireBucketName( arguments.bucketName );
        if ( arguments.force && hasBucket( arguments.bucketName ) ){
            var bucketContents = getBucket( arguments.bucketName );
            for ( var item in bucketContents ) {
                deleteObject( arguments.bucketName, item.key );
            }
        }

        var results = S3Request(
            method 	 		= "DELETE",
			resource        = arguments.bucketName,
			throwOnError    = false
		);

		var bucketDoesntExist = findNoCase( "NoSuchBucket", results.message ) neq 0;

		if( results.error && !bucketDoesntExist ){
			throw(
                type 	= "S3SDKError",
                message = "Error making Amazon REST Call",
                detail 	= results.message
            );
		} else if( bucketDoesntExist ){
			return  false;
		}

		return true;
    }

    /**
     * Puts an object from a local file in to a bucket.
     *
     * @bucketName   The bucket in which to store the object.
     * @filepath     The absolute file path to read in the binary.
     * @uri          The destination uri key to use when saving the object.
     *               If not provided, the name of the file will be used.
     * @contentType  The file content type. Defaults to binary/octet-stream.
     * @HTTPTimeout  The HTTP timeout to use
     * @cacheControl The caching header to send. Defaults to no caching.
     *               Example: public,max-age=864000  ( 10 days ).
     *               For more info look here:
     *               http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html##sec14.9
     * @expires      Sets the expiration header of the object in days.
     * @acl          The Amazon security access policy to use.
     *               Defaults to public-read.
     * @metaHeaders  Additonal metadata headers to add.
     *
     * @return       The file's eTag
     */
    string function putObjectFile(
        required string bucketName=variables.defaultBucketName,
        required string filepath,
        string uri = "",
        string contentType = "binary/octet-stream",
        numeric HTTPTimeout = 300,
        string cacheControl = "no-store, no-cache, must-revalidate",
        string expires = "",
        string acl = this.ACL_PUBLIC_READ,
        struct metaHeaders = {}
    ) {
        requireBucketName( arguments.bucketName );
        arguments.data = fileReadBinary( arguments.filepath );

        if ( NOT len( arguments.uri ) ) {
            arguments.uri = getFileFromPath( arguments.filePath );
        }

        //arguments.uri = urlEncodedFormat( arguments.uri );
        //arguments.uri = replaceNoCase( arguments.uri, "%2F", "/", "all" );
        //arguments.uri = replaceNoCase( arguments.uri, "%2E", ".", "all" );
        //arguments.uri = replaceNoCase( arguments.uri, "%2D", "-", "all" );
        //arguments.uri = replaceNoCase( arguments.uri, "%5F", "_", "all" );

        return putObject( argumentCollection = arguments );
    }

    /**
     * Puts an folder in to a bucket.
     *
     * @bucketName   The bucket in which to store the object.
     * @uri          The destination uri key to use when saving the object.
     *               If not provided, the name of the folder will be used.
     * @contentType  The folder content type. Defaults to binary/octet-stream.
     * @HTTPTimeout  The HTTP timeout to use
     * @cacheControl The caching header to send. Defaults to no caching.
     *               Example: public,max-age=864000  ( 10 days ).
     *               For more info look here:
     *               http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html##sec14.9
     * @expires      Sets the expiration header of the object in days.
     * @acl          The Amazon security access policy to use.
     *               Defaults to public-read.
     * @metaHeaders  Additonal metadata headers to add.
     *
     * @return       The folder's eTag
     */
    string function putObjectFolder(
        required string bucketName=variables.defaultBucketName,
        string uri = "",
        string contentType = "binary/octet-stream",
        numeric HTTPTimeout = 300,
        string cacheControl = "no-store, no-cache, must-revalidate",
        string expires = "",
        string acl = this.ACL_PUBLIC_READ,
        struct metaHeaders = {}
    ) {
        requireBucketName( arguments.bucketName );
        arguments.data = "";
        return putObject( argumentCollection = arguments );
    }

    /**
     * Create a structure of Amazon-enabled metadata headers.
     *
     * @metaHeaders Headers to convert to the Amazon meta headers.
     *
     * @return      A struct of Amazon-enabled metadata headers.
     */
    struct function createMetaHeaders( struct metaHeaders = {} ) {
        var md = {};
        for ( var key in arguments.metaHeaders ) {
            md[ "x-amz-meta-" & key ] = arguments.metaHeaders[ key ];
        }
        return md;
    }

    /**
     * Puts an object into a bucket.
     *
     * @bucketName         The bucket in which to store the object.
     * @uri                The destination uri key to use when saving the object.
     * @data               The content to save as data.
     *                     This can be binary, string, or anything you'd like.
     * @contentDisposition The content-disposition header to use when downloading the file.
     * @contentType        The file/data content type. Defaults to text/plain.
     * @HTTPTimeout        The HTTP timeout to use.
     * @cacheControl       The caching header to send. Defaults to no caching.
     *                     Example: public,max-age=864000  ( 10 days ).
     *                     For more info look here:
     *                     http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html##sec14.9
     * @expires            Sets the expiration header of the object in days.
     * @acl                The Amazon security access policy to use.
     *                     Defaults to public-read.
     * @metaHeaders        Additonal metadata headers to add.
     *
     * @return             The object's eTag.
     */
    string function putObject(
        required string bucketName=variables.defaultBucketName,
        string uri = "",
        any data = "",
        string contentDisposition = "",
        string contentType = "text/plain",
        numeric HTTPTimeout = 300,
        string cacheControl = "no-store, no-cache, must-revalidate",
        string expires = "",
        string acl = this.ACL_PUBLIC_READ,
        struct metaHeaders = {}
    ) {
        requireBucketName( arguments.bucketName );
        var amzHeaders = createMetaHeaders( arguments.metaHeaders );
        amzHeaders[ "x-amz-acl" ] = arguments.acl;

        var headers = {
            "content-type" = arguments.contentType,
            "cache-control" = arguments.cacheControl
        };

        if ( len( arguments.contentDisposition ) ) {
            headers[ "content-disposition" ] = arguments.contentDisposition;
        }

        if ( isNumeric( arguments.expires ) ) {
            headers[ "expires" ] = "#DateFormat( now() + arguments.expires, 'ddd, dd mmm yyyy' )# #TimeFormat( now(), 'H:MM:SS' )# GMT";
        }

        var results = S3Request(
            method 	   = "PUT",
            resource   = arguments.bucketName & "/" & arguments.uri,
            body       = arguments.data,
            timeout    = arguments.HTTPTimeout,
            headers    = headers,
            amzHeaders = amzHeaders
        );

        if ( results.responseHeader.status_code == 200 ) {
            return results.responseHeader.etag;
        }

        return "";
    }

    /**
     * Get an object's metadata information.
     *
     * @bucketName The bucket the object resides in.
     * @uri        The object URI to retrieve the info.
     *
     * @return     The object's metadata information.
     */
    struct function getObjectInfo(
        required string bucketName=variables.defaultBucketName,
        required string uri
    ) {
        requireBucketName( arguments.bucketName );
        var results = S3Request(
            method = "HEAD",
            resource = arguments.bucketName & "/" & arguments.uri
        );

        var metadata = {};
        for ( var key in results.responseHeader ) {
            metadata[ key ] = results.responseHeader[ key ];
        }
        return metadata;
    }

    /**
     * Check if an object exists in the bucket
     *
     * @bucketName The bucket the object resides in.
     * @uri        The object URI to check on.
     *
     * @return     True/false whether the object exists
     */
    boolean function objectExists(
        required string bucketName=variables.defaultBucketName,
        required string uri
    ) {
        requireBucketName( arguments.bucketName );
        var results = S3Request(
            method = "HEAD",
            resource = arguments.bucketName & "/" & arguments.uri,
            throwOnError=false
        );
        var status_code = results.responseHeader.status_code ?: 0;

        if( results.error == false && status_code >= 200 && status_code < 300 ) {
            return true;
        } else if( status_code == 404 ) {
            return false;
        } else {
            throw( message='Error checking for the existence of [#uri#].', detail=results.message );
        }

    }

    /**
     * Returns a query string authenticated URL to an object in S3.
     *
     * @bucketName       The bucket the object resides in.
     * @uri              The uri to the object to create a link for.
     * @minutesValid     The minutes the link is valid for. Defaults to 60 minutes.
     * @virtualHostStyle Whether to use virtual bucket style or path style.
     *                   Defaults to true.
     * @useSSL           Use SSL for the returned url.
     *
     * @return           An authenticated url to the resource.
     */
    string function getAuthenticatedURL(
        required string bucketName=variables.defaultBucketName,
        required string uri,
        string minutesValid = 60,
        boolean virtualHostStyle = false,
        boolean useSSL = variables.ssl
    ) {
		requireBucketName( arguments.bucketName );

        var epochTime = DateDiff( "s", DateConvert( "utc2Local", "January 1 1970 00:00" ), now() ) + ( arguments.minutesValid * 60 );
        var HTTPPrefix = arguments.useSSL ? "https://" : "http://";

		// Encode incoming URI
		arguments.uri = urlEncodedFormat( arguments.uri );
		// Replace back specific delimiters as required by AWS
        arguments.uri = replaceNoCase( arguments.uri, "%2F", "/", "all" );
        arguments.uri = replaceNoCase( arguments.uri, "%2E", ".", "all" );
        arguments.uri = replaceNoCase( arguments.uri, "%2D", "-", "all" );
        arguments.uri = replaceNoCase( arguments.uri, "%5F", "_", "all" );

		// Sign URL
        var stringToSign 	= "GET\n\n\n#epochTime#\n/#arguments.bucketName#/#arguments.uri#";
        var signature 		= urlEncodedFormat( createSignature( stringToSign ) );
        var securedLink 	= "#arguments.uri#?AWSAccessKeyId=#variables.accessKey#&Expires=#epochTime#&Signature=#signature#";

		if( log.canDebug() ){
			log.debug( "String to sign: #stringToSign# . Signature: #signature#" );
		}

        if ( arguments.virtualHostStyle ) {
            if ( variables.awsDomain contains 'amazonaws.com' ) {
                return "#HTTPPrefix##arguments.bucketName#.s3.amazonaws.com/#securedLink#";
            } else{
                return "#HTTPPrefix##arguments.bucketName#.#variables.awsRegion#.#variables.awsDomain#/#securedLink#";
            }
		}

        if ( variables.awsDomain contains 'amazonaws.com' ) {
            return "#HTTPPrefix#s3.amazonaws.com/#arguments.bucketName#/#securedLink#";
        } else{
            return "#HTTPPrefix##variables.awsRegion#.#variables.awsDomain#/#arguments.bucketName#/#securedLink#";
        }
    }

    /**
     * Deletes an object.
     *
     * @bucketName The bucket name the object resides in.
     * @uri        The file object uri to delete.
     *
     * @return     Returns true if the object is deleted successfully.
     */
	boolean function deleteObject(
        required string bucketName=variables.defaultBucketName,
        required string uri
    ) {
        requireBucketName( arguments.bucketName );

		//arguments.uri = urlEncodedFormat( urlDecode( arguments.uri ) );
        //arguments.uri = replaceNoCase( arguments.uri, "%2F", "/", "all" );
        //arguments.uri = replaceNoCase( arguments.uri, "%2E", ".", "all" );
        //arguments.uri = replaceNoCase( arguments.uri, "%2D", "-", "all" );
        //arguments.uri = replaceNoCase( arguments.uri, "%5F", "_", "all" );

        var results = S3Request(
            method = "DELETE",
            resource = arguments.bucketName & "/" & arguments.uri
		);

        return results.responseheader.status_code == 204;
    }

    /**
     * Copies an object.
     *
     * @fromBucket  The source bucket
     * @fromURI     The source URI
     * @toBucket    The destination bucket
     * @toURI       The destination URI
     * @acl         The Amazon security access policy to use. Defaults to private.
     * @metaHeaders Additonal metadata headers to add.
     *
     * @return      True if the object was copied correctly.
     */
    boolean function copyObject(
        required string fromBucket,
        required string fromURI,
        required string toBucket,
        required string toURI,
        string acl = this.ACL_PRIVATE,
        struct metaHeaders = {}
    ) {
        var headers 	= { "content-length" = 0 };
        var amzHeaders 	= createMetaHeaders( arguments.metaHeaders );

        if( not structIsEmpty( arguments.metaHeaders ) ){
            amzHeaders[ "x-amz-metadata-directive" ] = "REPLACE";
        }

        amzHeaders[ "x-amz-copy-source" ] 	= "/#arguments.fromBucket#/#arguments.fromURI#";
        amzHeaders[ "x-amz-acl" ] 			= arguments.acl;

        //arguments.toURI = urlEncodedFormat( arguments.toURI );
        //arguments.toURI = replaceNoCase( arguments.toURI, "%2F", "/", "all" );
        //arguments.toURI = replaceNoCase( arguments.toURI, "%2E", ".", "all" );
        //arguments.toURI = replaceNoCase( arguments.toURI, "%2D", "-", "all" );
        //arguments.toURI = replaceNoCase( arguments.toURI, "%5F", "_", "all" );

        var results = S3Request(
            method 		= "PUT",
            resource 	= arguments.toBucket & "/" & arguments.toURI,
            metaHeaders = metaHeaders,
            headers 	= headers,
            amzHeaders 	= amzHeaders
        );

        return results.responseheader.status_code == 204;
    }

    /**
     * Renames an object by copying then deleting original.
     *
     * @oldBucketName The source bucket.
     * @oldFileKey    The source URI.
     * @newBucketName The destination bucket.
     * @newFileKey    The destination URI.
     *
     * @return        True if the rename operation is successful.
     */
    boolean function renameObject(
        required string oldBucketName,
        required string oldFileKey,
        required string newBucketName,
        required string newFileKey
    ) {
        if ( compare( oldBucketName, newBucketName ) || compare( oldFileKey, newFileKey ) ) {
            copyObject( oldBucketName, oldFileKey, newBucketName, newFileKey );
            deleteObject( oldBucketName, oldFileKey );
            return true;
        }

        return false;
    }

    /**
     * Make a request to Amazon S3.
     *
     * @method     The HTTP method for the request.
     * @resource   The resource to hit in the Amazon S3 service.
     * @body       The body content of the request, if passed.
     * @headers    A struct of HTTP headers to send.
     * @amzHeaders A struct of special Amazon headers to send.
     * @parameters A struct of HTTP URL parameters to send.
     * @timeout    The default CFHTTP timeout.
	 * @throwOnError Flag to throw exceptions on any error or not, default is true
     *
     * @return     The response information.
     */
    private struct function s3Request(
        string method = "GET",
        string resource = "",
        any body = "",
        struct headers = {},
        struct amzHeaders = {},
        struct parameters = {},
		numeric timeout = 20,
		boolean throwOnError = true
    ) {
        var results = {
            "error"          = false,
            "response"       = {},
            "message"        = "",
            "responseheader" = {}
        };
        var HTTPResults = "";
        var param       = "";
        var md5         = "";
		var sortedAMZ   = listToArray( listSort( structKeyList( arguments.amzHeaders ), "textnocase" ) );

        // Default Content Type
        if ( NOT structKeyExists( arguments.headers, "content-type" ) ) {
        	arguments.headers[ "Content-Type" ] = "";
        }

        // Prepare amz headers in sorted order
        for( var x = 1; x <= arrayLen( sortedAMZ ); x++ ) {
            // Create amz signature string
            arguments.headers[ sortedAMZ[ x ] ] = arguments.amzHeaders[ sortedAMZ[ x ] ];
        }

		// Create Signature
        var signatureData = sv4Util.generateSignatureData(
            requestMethod  	= arguments.method,
			hostName 		= reReplaceNoCase( variables.URLEndpoint, "https?\:\/\/", "" ),
            requestURI     	= arguments.resource,
            requestBody    	= arguments.body,
            requestHeaders 	= arguments.headers,
            requestParams  	= arguments.parameters
		);

		cfhttp(
            method = arguments.method,
            url = "#variables.URLEndPoint#/#arguments.resource#",
            charset = "utf-8",
			result = "HTTPResults",
			redirect = true,
			timeout = arguments.timeout,
			useragent = "ColdFusion-S3SDK"
        ) {
            // Amazon Global Headers
            cfhttpparam(
                type = "header",
                name = "Date",
                value = signatureData.amzDate
            );

            cfhttpparam(
                type = "header",
                name = "Authorization",
                value = signatureData.authorizationHeader
            );

            for ( var headerName in signatureData.requestHeaders ) {
                cfhttpparam(
                    type = "header",
                    name = headerName,
                    value = signatureData.requestHeaders[ headerName ]
                );
            }

            for ( var paramName in signatureData.requestParams ) {
                cfhttpparam(
                    type = "URL",
                    name = paramName,
                    value = signatureData.requestParams[ paramName ]
                );
            }

            if ( len( arguments.body ) ) {
                cfhttpparam( type = "body", value = arguments.body );
            }
        }

		if( log.canDebug() ){
			log.debug( "Amazon Rest Call ->Arguments: #arguments.toString()#, ->Encoded Signature=#signatureData.signature#", HTTPResults );
		}

        results.response = HTTPResults.fileContent;
        results.responseHeader = HTTPResults.responseHeader;

        results.message = HTTPResults.errorDetail;
		if ( len( HTTPResults.errorDetail ) && HTTPResults.errorDetail neq '302 Found' ) {
			results.error = true;
		}

        // Check XML Parsing?
        if ( structKeyExists( HTTPResults.responseHeader, "content-type" ) &&
            HTTPResults.responseHeader[ "content-type" ] == "application/xml" &&
            isXML( HTTPResults.fileContent )
        ) {
            results.response = XMLParse( HTTPResults.fileContent );
            // Check for Errors
            if ( NOT listFindNoCase( "200,204,302", HTTPResults.responseHeader.status_code ) ) {
                results.error = true;
                results.message = arrayToList( arrayMap( results.response.error.XmlChildren, function( node ) {
                    return "#node.XmlName#: #node.XmlText#";
                } ), "\n" );
            }
		}

		if( results.error ){
			log.error( "Amazon Rest Call ->Arguments: #arguments.toString()#, ->Encoded Signature=#signatureData.signature#", HTTPResults );
		}

        if( results.error && arguments.throwOnError ){
            throw(
                type 	= "S3SDKError",
                message = "Error making Amazon REST Call",
                detail 	= results.message
            );
        }

        return results;
    }

    /**
     * NSA SHA-1 Algorithm: RFC 2104HMAC-SHA1
     */
    private binary function HMAC_SHA1(
        required string signKey,
        required string signMessage
    ) {
        var jMsg = JavaCast( "string", arguments.signMessage ).getBytes( encryption_charset );
        var jKey = JavaCast( "string", arguments.signKey ).getBytes( encryption_charset );
        var key = createObject( "java", "javax.crypto.spec.SecretKeySpec" ).init( jKey,"HmacSHA1" );
        var mac = createObject( "java", "javax.crypto.Mac" ).getInstance( key.getAlgorithm() );

        mac.init( key );
        mac.update( jMsg );

        return mac.doFinal();
    }

    /**
     * Helper function to catch missing bucket name
     */
    private function requireBucketName( bucketName ) {
        if( isNull( arguments.bucketName ) || !len( arguments.bucketName )  ) {
            throw( 'bucketName is required.  Please provide the name of the bucket to access or set a default bucket name in the SDk.' );
        }
    }

}

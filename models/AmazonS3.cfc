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
	property name="defaultTimeOut";
	property name="defaultDelimiter";
	property name="defaultBucketName";
	property name="defaultCacheControl";
	property name="defaultStorageClass";
	property name="defaultACL";
	property name="autoContentType";
	property name="autoMD5";
	property name="mimeTypes";
	property name="serviceName";

	// STATIC Contsants
	this.ACL_PRIVATE           = "private";
	this.ACL_PUBLIC_READ       = "public-read";
	this.ACL_PUBLIC_READ_WRITE = "public-read-write";
	this.ACL_AUTH_READ         = "authenticated-read";

	this.S3_STANDARD = "STANDARD";
	this.S3_IA       = "STANDARD_IA";
	this.S3_TIERING  = "INTELLIGENT_TIERING";
	this.S3_ONEZONE  = "ONEZONE_IA";
	this.S3_GLACIER  = "GLACIER";
	this.S3_ARCHIVE  = "DEEP_ARCHIVE";
	this.S3_RRS      = "REDUCED_REDUNDANCY"; // deprecated

	// Google Cloud storage classes
	this.GS_STANDARD = "regional";
	this.GS_MULTI    = "multi_regional";
	this.GS_NEARLINE = "nearline";
	this.GS_COLDLINE = "coldline";

	/**
	 * Create a new S3SDK Instance
	 *
	 * @accessKey The Amazon access key.
	 * @secretKey The Amazon secret key.
	 * @awsDomain The Domain used S3 Service (amazonws.com, digitalocean.com, storage.googleapis.com). Defaults to amazonws.com
	 * @awsRegion The Amazon region. Defaults to us-east-1 for amazonaws.com
	 * @encryption_charset The charset for the encryption. Defaults to UTF-8.
	 * @signature The signature version to calculate, "V2" is deprecated but more compatible with other endpoints. "V4" requires Sv4Util.cfc & ESAPI on Lucee. Defaults to V4
	 * @ssl True if the request should use SSL. Defaults to true.
	 * @defaultTimeOut Default HTTP timeout for all requests. Defaults to 300.
	 * @defaultDelimiter Delimter to use for getBucket calls. "/" is standard to treat keys as file paths
	 * @defaultBucketName Bucket name to use by default
	 * @defaultCacheControl Default caching policy for objects. Defaults to: no-store, no-cache, must-revalidate
	 * @defaultStorageClass Default storage class for objects that affects cost, access speed and durability. Defaults to STANDARD.
	 * @defaultACL Default access control policy for objects and buckets. Defaults to public-read.
	 * @throwOnRequestError If an exception should be thrown for request errors. Defaults to true.
	 * @autoContentType Tries to determine content type of file by file extension. Defaults to false.
	 * @autoMD5 Calculates MD5 hash of content automatically. Defaults to false.
	 * @debug Used to turn debugging on or off outside of logbox. Defaults to false.
	 *
	 * @return An AmazonS3 instance.
	 */
	AmazonS3 function init(
		required string accessKey,
		required string secretKey,
		string awsDomain           = "amazonaws.com",
		string awsRegion           = "", // us-east-1 default for aws
		string encryption_charset  = "UTF-8",
		string signatureType       = "V4",
		boolean ssl                = true,
		string defaultTimeOut      = 300,
		string defaultDelimiter    = "/",
		string defaultBucketName   = "",
		string defaultCacheControl = "no-store, no-cache, must-revalidate",
		string defaultStorageClass = this.S3_STANDARD,
		string defaultACL          = this.ACL_PUBLIC_READ,
		string throwOnRequestError = true,
		boolean autoContentType    = false,
		boolean autoMD5            = false,
		string serviceName         = "s3",
		boolean debug              = false
	) {
		if ( arguments.awsDomain == "amazonaws.com" && arguments.awsRegion == "" ) {
			arguments.awsRegion = "us-east-1";
		}
		variables.accessKey           = arguments.accessKey;
		variables.secretKey           = arguments.secretKey;
		variables.encryption_charset  = arguments.encryption_charset;
		variables.signatureType       = arguments.signatureType;
		variables.awsDomain           = arguments.awsDomain;
		variables.awsRegion           = arguments.awsRegion;
		variables.defaultTimeOut      = arguments.defaultTimeOut;
		variables.defaultDelimiter    = arguments.defaultDelimiter;
		variables.defaultBucketName   = arguments.defaultBucketName;
		variables.defaultCacheControl = arguments.defaultCacheControl;
		variables.defaultStorageClass = arguments.defaultStorageClass;
		variables.defaultACL          = arguments.defaultACL;
		variables.throwOnRequestError = arguments.throwOnRequestError;
		variables.autoContentType     = arguments.autoContentType;
		variables.autoMD5             = ( variables.signatureType == "V2" || arguments.autoMD5 ? "auto" : "" );
		variables.serviceName         = arguments.serviceName;

		// Construct the SSL Domain
		setSSL( arguments.ssl );

		// Build out the endpoint URL
		buildUrlEndpoint();

		// Build signature utility
		variables.signatureUtil = createSignatureUtil( variables.signatureType );

		// manual debugging replacement for logbox
		if ( NOT structKeyExists( variables, "log" ) ) {
			variables.log = new MiniLogBox( arguments.debug );
		}

		// detect mimetypes from file extension
		variables.mimeTypes = {
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

		return this;
	}

	function createSignatureUtil( required string type ) {
		if ( arguments.type == "V4" ) {
			return new Sv4Util();
		} else if ( arguments.type == "V2" ) {
			return new Sv2Util();
		}
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

	AmazonS3 function setAWSDomain( required string domain ) {
		variables.awsDomain = arguments.domain;
		buildUrlEndpoint();
		return this;
	}

	AmazonS3 function setAWSRegion( required string region ) {
		variables.awsRegion = arguments.region;
		buildUrlEndpoint();
		return this;
	}

	/**
	 * This function builds the variables.UrlEndpoint according to credentials and ssl configuration, usually called after init() for you automatically.
	 */
	AmazonS3 function buildUrlEndpoint() {
		// Build accordingly
		var URLEndPointProtocol = ( variables.ssl ) ? "https://" : "http://";
		variables.URLEndpoint   = ( variables.awsDomain contains "amazonaws.com" ) ? "#URLEndPointProtocol#s3.#variables.awsRegion#.#variables.awsDomain#" : "#URLEndPointProtocol##variables.awsDomain#";
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
		buildUrlEndpoint();
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
		return toBase64(
			hMAC_SHA1(
				variables.secretKey,
				replace(
					arguments.stringToSign,
					"\n",
					chr( 10 ),
					"all"
				)
			)
		);
	}

	/**
	 * List all the buckets associated with the Amazon credentials.
	 *
	 * @return
	 */
	array function listBuckets() {
		var results = s3Request();

		var bucketsXML = xmlSearch( results.response, "//*[local-name()='Bucket']" );

		return arrayMap( bucketsXML, function( node ) {
			return {
				"name"         : trim( node.name.xmlText ),
				"creationDate" : trim( node.creationDate.xmlText )
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
        var results = S3Request( resource = arguments.bucketname, parameters={ "location" : true } );

		if ( results.error ) {
			throw( message = "Error making Amazon REST Call", detail = results.message );
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
        var results = S3Request( resource = arguments.bucketname, parameters={ "versioning" : true } );

		var status = xmlSearch(
			results.response,
			"//*[local-name()='VersioningConfiguration']//*[local-name()='Status']/*[1]"
		);

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
	boolean function setBucketVersionStatus(
		required string bucketName = variables.defaultBucketName,
		boolean version            = true
	) {
		requireBucketName( arguments.bucketName );
		var constraintXML = "";
		var headers       = { "content-type" : "text/plain" };

		if ( arguments.version ) {
			headers[ "?versioning" ] = "";
			constraintXML            = '<VersioningConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Status>Enabled</Status></VersioningConfiguration>';
		}

		var results = s3Request(
			method     = "PUT",
			resource   = arguments.bucketName,
			body       = constraintXML,
			headers    = headers,
			amzHeaders = {}
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
            resource = resource & "/" & arguments.uri;
        }

        var results = S3Request( resource = resource, parameters={ "acl" : true } );

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
     * Sets a bucket's or object's ACL policy.
     *
     * @bucketName The bucket to get the ACL.
     * @uri        An optional resource uri to get the ACL.
	 * @acl        A known ACL string
     *
     */
	void function setAccessControlPolicy( required string bucketName=variables.defaultBucketName, string uri = "", string acl ){
		requireBucketName( arguments.bucketName );

		var resource = arguments.bucketName;

        if ( len( arguments.uri ) ) {
            resource = resource & "/" & arguments.uri;
        }

		S3Request(
            method     = "PUT",
            resource   = resource,
			parameters = { "acl" : true },
            amzHeaders = { "x-amz-acl" = arguments.acl }
        );

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
		required string bucketName = variables.defaultBucketName,
		string prefix              = "",
		string marker              = "",
		string maxKeys             = "",
		string delimiter           = variables.defaultDelimiter
	) {
        requireBucketName( arguments.bucketName );
        var parameters = {
			"list-type" : 2
		};

        if ( len( arguments.prefix ) ) {
            parameters[ "prefix" ] = arguments.prefix;
        }

		if ( len( arguments.marker ) ) {
			parameters[ "marker" ] = arguments.marker;
		}

		if ( isNumeric( arguments.maxKeys ) ) {
			parameters[ "max-keys" ] = arguments.maxKeys;
		}

        if ( isNumeric( arguments.maxKeys ) ) {
            parameters[ "max-keys" ] = arguments.maxKeys;
        }

		var results = s3Request( resource = arguments.bucketName, parameters = parameters );

		var contentsXML = xmlSearch( results.response, "//*[local-name()='Contents']" );
		var foldersXML  = xmlSearch( results.response, "//*[local-name()='CommonPrefixes']" );

		var objectContents = arrayMap( contentsXML, function( node ) {
			return {
				"key"          : trim( node.key.xmlText ),
				"lastModified" : trim( node.lastModified.xmlText ),
				"size"         : trim( node.Size.xmlText ),
				"eTag"         : replace(
					trim( node.etag.xmlText ),
					'"',
					"",
					"all"
				),
				"isDirectory" : (
					(
						findNoCase( "_$folder$", node.key.xmlText ) || (
							len( delimiter ) && node.key.xmlText.endsWith( delimiter )
						)
					) ? true : false
				)
			};
		} );

		var folderContents = arrayMap( foldersXML, function( node ) {
			return {
				"key" : reReplaceNoCase(
					trim( node.prefix.xmlText ),
					"\/$",
					""
				),
				"lastModified" : "",
				"size"         : "",
				"eTag"         : "",
				"isDirectory"  : true
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
		required string bucketName = variables.defaultBucketName,
		string acl                 = variables.defaultACL,
		string location            = "USA"
	) {
		requireBucketName( arguments.bucketName );
		var constraintXML = arguments.location == "EU" ? "<CreateBucketConfiguration><LocationConstraint>EU</LocationConstraint></CreateBucketConfiguration>" : "";

		var results = s3Request(
			method     = "PUT",
			resource   = arguments.bucketName,
			body       = constraintXML,
			headers    = { "content-type" : "text/xml" },
			amzHeaders = { "x-amz-acl" : arguments.acl }
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
	boolean function hasBucket( required string bucketName = variables.defaultBucketName ) {
		requireBucketName( arguments.bucketName );
		return !arrayIsEmpty(
			arrayFilter( listBuckets(), function( bucket ) {
				return bucket.name == bucketName;
			} )
		);
	}

	/**
	 * Deletes a bucket.
	 *
	 * @bucketName The name of the bucket to delete.
	 * @force      If true, delete the contents of the bucket before deleting the bucket.
	 *
	 * @return     True, if the bucket was deleted successfully.
	 */
	boolean function deleteBucket( required string bucketName = variables.defaultBucketName, boolean force = false ) {
		requireBucketName( arguments.bucketName );
		if ( arguments.force && hasBucket( arguments.bucketName ) ) {
			var bucketContents = getBucket( arguments.bucketName );
			for ( var item in bucketContents ) {
				deleteObject( arguments.bucketName, item.key );
			}
		}

		var results = s3Request(
			method       = "DELETE",
			resource     = arguments.bucketName,
			throwOnError = false
		);

		var bucketDoesntExist = findNoCase( "NoSuchBucket", results.message ) neq 0;

		if ( results.error && !bucketDoesntExist ) {
			throw(
				type    = "S3SDKError",
				message = "Error making Amazon REST Call: #results.message#",
				detail  = serializeJSON( results.response )
			);
		} else if ( bucketDoesntExist ) {
			return false;
		}

		return true;
	}

	/**
	 * Puts an object from a local file in to a bucket.
	 *
	 * @bucketName      The bucket in which to store the object.
	 * @filepath        The absolute file path to read in the binary.
	 * @uri             The destination uri key to use when saving the object.
	 *                  If not provided, the name of the file will be used.
	 * @contentType     The file content type. Defaults to binary/octet-stream.
	 * @contentEncoding The file content encoding, useful to gzip data.
	 * @HTTPTimeout     The HTTP timeout to use
	 * @cacheControl    The caching header to send. Defaults to no caching.
	 *                  Example: public,max-age=864000  ( 10 days ).
	 *                  For more info look here:
	 *                  http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html##sec14.9
	 * @expires         Sets the expiration header of the object in days.
	 * @acl             The Amazon security access policy to use.
	 *                  Defaults to public-read.
	 * @metaHeaders     Additonal metadata headers to add.
	 * @md5             Set the MD5 hash which allows aws to checksum the object
	 *                  was sent correctly.
	 *                  Set to "auto" to calculate the md5 in the client.
	 * @storageClass    Sets the S3 storage class which affects cost, access speed and durability.
	 *                  Defaults to STANDARD.
	 *
	 * @return          The file's eTag
	 */
	string function putObjectFile(
		required string bucketName = variables.defaultBucketName,
		required string filepath,
		string uri             = "",
		string contentType     = "",
		string contentEncoding = "",
		numeric HTTPTimeout    = variables.defaultTimeout,
		string cacheControl    = variables.defaultCacheControl,
		string expires         = "",
		string acl             = variables.defaultACL,
		struct metaHeaders     = {},
		string md5             = variables.autoMD5,
		string storageClass    = variables.defaultStorageClass
	) {
		requireBucketName( arguments.bucketName );
		arguments.data = fileReadBinary( arguments.filepath );

		if ( NOT len( arguments.uri ) ) {
			arguments.uri = getFileFromPath( arguments.filePath );
		}

		if ( arguments.contentType == "" ) {
			arguments.contentType = ( variables.autoContentType ? "auto" : "binary/octet-stream" );
		}
		if ( arguments.contentType == "auto" ) {
			arguments.contentType = getFileMimeType( arguments.filepath );
		}

		// arguments.uri = urlEncodedFormat( arguments.uri );
		// arguments.uri = replaceNoCase( arguments.uri, "%2F", "/", "all" );
		// arguments.uri = replaceNoCase( arguments.uri, "%2E", ".", "all" );
		// arguments.uri = replaceNoCase( arguments.uri, "%2D", "-", "all" );
		// arguments.uri = replaceNoCase( arguments.uri, "%5F", "_", "all" );

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
		required string bucketName = variables.defaultBucketName,
		string uri                 = "",
		string contentType         = "binary/octet-stream",
		numeric HTTPTimeout        = variables.defaultTimeOut,
		string cacheControl        = variables.defaultCacheControl,
		string expires             = "",
		string acl                 = variables.defaultACL,
		struct metaHeaders         = {}
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
	 * @contentEncoding    The file content encoding, useful to gzip data.
	 * @HTTPTimeout        The HTTP timeout to use.
	 * @cacheControl       The caching header to send. Defaults to no caching.
	 *                     Example: public,max-age=864000  ( 10 days ).
	 *                     For more info look here:
	 *                     http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html##sec14.9
	 * @expires            Sets the expiration header of the object in days.
	 * @acl                The Amazon security access policy to use.
	 *                     Defaults to public-read.
	 * @metaHeaders        Additonal metadata headers to add.
	 * @md5                Set the MD5 hash which allows aws to checksum the object
	 *                     was sent correctly.
	 *                     Set to "auto" to calculate the md5 in the client.
	 * @storageClass       Sets the S3 storage class which affects cost, access speed and durability.
	 *                     Defaults to STANDARD.
	 *
	 * @return             The object's eTag.
	 */
	string function putObject(
		required string bucketName = variables.defaultBucketName,
		required string uri,
		any data                  = "",
		string contentDisposition = "",
		string contentType        = ( variables.autoContentType ? "auto" : "text/plain" ),
		string contentEncoding    = "",
		numeric HTTPTimeout       = variables.defaultTimeOut,
		string cacheControl       = variables.defaultCacheControl,
		string expires            = "",
		string acl                = variables.defaultACL,
		struct metaHeaders        = {},
		string md5                = variables.autoMD5,
		string storageClass       = variables.defaultStorageClass
	) {
		requireBucketName( arguments.bucketName );
		var amzHeaders            = createMetaHeaders( arguments.metaHeaders );
		amzHeaders[ "x-amz-acl" ] = arguments.acl;

		if ( len( arguments.storageClass ) ) {
			amzHeaders[ "x-amz-storage-class" ] = arguments.storageClass;
		}

		var headers = { "content-type" : arguments.contentType };

		if ( len( arguments.cacheControl ) ) {
			headers[ "cache-control" ] = arguments.cacheControl;
		};

		if ( arguments.md5 == "auto" ) {
			headers[ "content-md5" ] = mD5inBase64( arguments.content );
		} else if ( len( arguments.md5 ) ) {
			headers[ "content-md5" ] = arguments.md5;
		}

		if ( len( arguments.contentEncoding ) ) {
			headers[ "content-encoding" ] = arguments.contentEncoding;
		}

		if ( len( arguments.contentDisposition ) ) {
			headers[ "content-disposition" ] = arguments.contentDisposition;
		}

		if ( isNumeric( arguments.expires ) ) {
			headers[ "expires" ] = "#dateFormat( now() + arguments.expires, "ddd, dd mmm yyyy" )# #timeFormat( now(), "H:MM:SS" )# GMT";
		}

		var results = s3Request(
			method     = "PUT",
			resource   = arguments.bucketName & "/" & arguments.uri,
			body       = arguments.data,
			timeout    = arguments.HTTPTimeout,
			headers    = headers,
			amzHeaders = amzHeaders
		);

		if ( results.responseHeader.status_code == 200 ) {
			return replace(
				results.responseHeader.etag,
				'"',
				"",
				"all"
			);
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
	struct function getObjectInfo( required string bucketName = variables.defaultBucketName, required string uri ) {
		requireBucketName( arguments.bucketName );
		var results = s3Request( method = "HEAD", resource = arguments.bucketName & "/" & arguments.uri );

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
	boolean function objectExists( required string bucketName = variables.defaultBucketName, required string uri ) {
		requireBucketName( arguments.bucketName );
		var results = s3Request(
			method       = "HEAD",
			resource     = arguments.bucketName & "/" & arguments.uri,
			throwOnError = false
		);
		var status_code = results.responseHeader.status_code ?: 0;

		if ( results.error == false && status_code >= 200 && status_code < 300 ) {
			return true;
		} else if ( status_code == 404 ) {
			return false;
		} else {
			throw( message = "Error checking for the existence of [#uri#].", detail = results.message );
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
		required string bucketName = variables.defaultBucketName,
		required string uri,
		string minutesValid      = 60,
		boolean virtualHostStyle = false,
		boolean useSSL           = variables.ssl
	) {
		requireBucketName( arguments.bucketName );

		var epochTime = dateDiff(
			"s",
			dateConvert( "utc2Local", "January 1 1970 00:00" ),
			now()
		) + ( arguments.minutesValid * 60 );
		var HTTPPrefix = arguments.useSSL ? "https://" : "http://";

		// Encode incoming URI
		arguments.uri = urlEncodedFormat( arguments.uri );
		// Replace back specific delimiters as required by AWS
		arguments.uri = replaceNoCase( arguments.uri, "%2F", "/", "all" );
		arguments.uri = replaceNoCase( arguments.uri, "%2E", ".", "all" );
		arguments.uri = replaceNoCase( arguments.uri, "%2D", "-", "all" );
		arguments.uri = replaceNoCase( arguments.uri, "%5F", "_", "all" );

		// Sign URL
		var stringToSign = "GET\n\n\n#epochTime#\n/#arguments.bucketName#/#arguments.uri#";
		var signature    = urlEncodedFormat( createSignature( stringToSign ) );
		var securedLink  = "#arguments.uri#?AWSAccessKeyId=#variables.accessKey#&Expires=#epochTime#&Signature=#signature#";

		if ( log.canDebug() ) {
			log.debug( "String to sign: #stringToSign# . Signature: #signature#" );
		}

		if ( arguments.virtualHostStyle ) {
			if ( variables.awsDomain contains "amazonaws.com" ) {
				return "#HTTPPrefix##arguments.bucketName#.s3.amazonaws.com/#securedLink#";
			} else if ( len( variables.awsRegion ) ) {
				return "#HTTPPrefix##arguments.bucketName#.#variables.awsRegion#.#variables.awsDomain#/#securedLink#";
			} else {
				return "#HTTPPrefix##arguments.bucketName#.#variables.awsDomain#/#securedLink#";
			}
		}

		if ( variables.awsDomain contains "amazonaws.com" ) {
			return "#HTTPPrefix#s3.amazonaws.com/#arguments.bucketName#/#securedLink#";
		} else if ( len( variables.awsRegion ) ) {
			return "#HTTPPrefix##variables.awsRegion#.#variables.awsDomain#/#arguments.bucketName#/#securedLink#";
		} else {
			return "#HTTPPrefix##variables.awsDomain#/#arguments.bucketName#/#securedLink#";
		}
	}

	/**
	 * Get an object's metadata information.
	 *
	 * @bucketName The bucket the object resides in.
	 * @uri        The object URI to retrieve the info.
	 *
	 * @return     The object's metadata information.
	 */
	struct function getObject( required string bucketName = variables.defaultBucketName, required string uri ) {
		requireBucketName( arguments.bucketName );
		var results = s3Request( method = "GET", resource = arguments.bucketName & "/" & arguments.uri );
		return results;
	}

	/**
	 * Gets an object from a bucket.
	 *
	 * @bucketName         The bucket in which to store the object.
	 * @uri                The destination uri key to use when saving the object.
	 * @filepath           The file path write the object to, if no filename given filename from uri is used
	 * @charset            The file charset, defaults to UTF-8
	 * @HTTPTimeout        The HTTP timeout to use.
	 *
	 * @return             The object's eTag.
	 */
	struct function downloadObject(
		required string bucketName = variables.defaultBucketName,
		required string uri,
		required string filepath
	) {
		requireBucketName( arguments.bucketName );

		// if filepath is a directory, append filename
		if ( right( arguments.filepath, 1 ) == "/" || right( arguments.filepath, 1 ) == "\" ) {
			arguments.filepath &= listLast( arguments.uri, "/\" );
		}

		var results = s3Request(
			method        = "GET",
			resource      = arguments.bucketName & "/" & arguments.uri,
			filename      = arguments.filepath,
			parseResponse = false
		);

		results.filename = arguments.filepath;

		if ( !fileExists( arguments.filepath ) ) {
			results.error   = true;
			results.message = "Downloaded file doesn't exist";
		}

		return results;
	}

	/**
	 * Deletes an object.
	 *
	 * @bucketName The bucket name the object resides in.
	 * @uri        The file object uri to delete.
	 *
	 * @return     Returns true if the object is deleted successfully.
	 */
	boolean function deleteObject( required string bucketName = variables.defaultBucketName, required string uri ) {
		requireBucketName( arguments.bucketName );

		var results = s3Request( method = "DELETE", resource = arguments.bucketName & "/" & arguments.uri );

		return results.responseheader.status_code == 204;
	}

	/**
	 * Copies an object.
	 *
	 * @fromBucket   The source bucket
	 * @fromURI      The source URI
	 * @toBucket     The destination bucket
	 * @toURI        The destination URI
	 * @acl          The Amazon security access policy to use. Defaults to public.
	 * @storageClass Sets the S3 storage class which affects cost, access speed and durability.
	 *               Defaults to STANDARD.
	 * @metaHeaders  Additonal metadata headers to add.
	 *
	 * @return      True if the object was copied correctly.
	 */
	boolean function copyObject(
		required string fromBucket,
		required string fromURI,
		required string toBucket,
		required string toURI,
		string acl          = variables.defaultACL,
		struct metaHeaders  = {},
		string storageClass = variables.defaultStorageClass
	) {
		var headers    = { "content-length" : 0 };
		var amzHeaders = createMetaHeaders( arguments.metaHeaders );

		if ( not structIsEmpty( arguments.metaHeaders ) ) {
			amzHeaders[ "x-amz-metadata-directive" ] = "REPLACE";
		}

		amzHeaders[ "x-amz-copy-source" ] = "/#arguments.fromBucket#/#arguments.fromURI#";
		amzHeaders[ "x-amz-acl" ]         = arguments.acl;

		if ( len( arguments.storageClass ) ) {
			amzHeaders[ "x-amz-storage-class" ] = arguments.storageClass;
		}

		// arguments.toURI = urlEncodedFormat( arguments.toURI );
		// arguments.toURI = replaceNoCase( arguments.toURI, "%2F", "/", "all" );
		// arguments.toURI = replaceNoCase( arguments.toURI, "%2E", ".", "all" );
		// arguments.toURI = replaceNoCase( arguments.toURI, "%2D", "-", "all" );
		// arguments.toURI = replaceNoCase( arguments.toURI, "%5F", "_", "all" );

		var results = s3Request(
			method      = "PUT",
			resource    = arguments.toBucket & "/" & arguments.toURI,
			metaHeaders = metaHeaders,
			headers     = headers,
			amzHeaders  = amzHeaders
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
			copyObject(
				oldBucketName,
				oldFileKey,
				newBucketName,
				newFileKey
			);
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
		string method         = "GET",
		string resource       = "",
		any body              = "",
		struct headers        = {},
		struct amzHeaders     = {},
		struct parameters     = {},
		string filename       = "",
		numeric timeout       = variables.defaultTimeOut,
		boolean parseResponse = true,
		boolean throwOnError  = variables.throwOnRequestError
	) {
		var results = {
			"error"          : false,
			"response"       : {},
			"message"        : "",
			"responseheader" : {}
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
		for ( var x = 1; x <= arrayLen( sortedAMZ ); x++ ) {
			// Create amz signature string
			arguments.headers[ sortedAMZ[ x ] ] = arguments.amzHeaders[ sortedAMZ[ x ] ];
		}

		// Create Signature
		var signatureData = signatureUtil.generateSignatureData(
			requestMethod = arguments.method,
			hostName      = reReplaceNoCase(
				variables.URLEndpoint,
				"https?\:\/\/",
				""
			),
			requestURI     = arguments.resource,
			requestBody    = arguments.body,
			requestHeaders = arguments.headers,
			requestParams  = arguments.parameters,
			accessKey      = variables.accessKey,
			secretKey      = variables.secretKey,
			regionName     = variables.awsRegion,
			serviceName    = variables.serviceName
		);
		cfhttp(
			method   =arguments.method,
			url      ="#variables.URLEndPoint#/#arguments.resource#",
			charset  ="utf-8",
			result   ="HTTPResults",
			redirect =true,
			timeout  =arguments.timeout,
			useragent="ColdFusion-S3SDK"
		) {
			// Amazon Global Headers
			cfhttpparam(
				type ="header",
				name ="Date",
				value=signatureData.amzDate
			);

			cfhttpparam(
				type ="header",
				name ="Authorization",
				value=signatureData.authorizationHeader
			);

			for ( var headerName in signatureData.requestHeaders ) {
				cfhttpparam(
					type ="header",
					name =headerName,
					value=signatureData.requestHeaders[ headerName ]
				);
			}

			for ( var paramName in signatureData.requestParams ) {
				cfhttpparam(
					type   ="URL",
					name   =paramName,
					encoded=false,
					value  =signatureData.requestParams[ paramName ]
				);
			}

			if ( len( arguments.body ) ) {
				cfhttpparam( type="body", value=arguments.body );
			}
		}

		if ( len( arguments.filename ) ) {
			fileWrite( arguments.filename, HTTPResults.fileContent );
		}

		if ( log.canDebug() ) {
			log.debug(
				"Amazon Rest Call ->Arguments: #arguments.toString()#, ->Encoded Signature=#signatureData.signature#",
				HTTPResults
			);
		}

		results.response       = HTTPResults.fileContent;
		results.responseHeader = HTTPResults.responseHeader;

		results.message = HTTPResults.errorDetail;
		if ( len( HTTPResults.errorDetail ) && HTTPResults.errorDetail neq "302 Found" ) {
			results.error = true;
		}

		// Check XML Parsing?
		if (
			arguments.parseResponse &&
			structKeyExists( HTTPResults.responseHeader, "content-type" ) &&
			HTTPResults.responseHeader[ "content-type" ] == "application/xml" &&
			isXML( HTTPResults.fileContent )
		) {
			results.response = xmlParse( HTTPResults.fileContent );
			// Check for Errors
			if ( NOT listFindNoCase( "200,204,302", HTTPResults.responseHeader.status_code ) ) {
				results.error   = true;
				results.message = arrayToList(
					arrayMap( results.response.error.XmlChildren, function( node ) {
						return "#node.XmlName#: #node.XmlText#";
					} ),
					"\n"
				);
			}
		}

		if ( results.error ) {
			log.error(
				"Amazon Rest Call ->Arguments: #arguments.toString()#, ->Encoded Signature=#signatureData.signature#",
				HTTPResults
			);
			results.http = HTTPResults;
		}

		if ( results.error && arguments.throwOnError ) {
			/**
			writeDump( var=results );
			writeDump( var=signatureData );
			writeDump( var=arguments );
			writeDump( var=callStackGet() );
			abort;
			**/

			throw(
				type    = "S3SDKError",
				message = "Error making Amazon REST Call: #results.message#",
				detail  = serializeJSON( results.response )
			);
		}

		return results;
	}

	/**
	 * NSA SHA-1 Algorithm: RFC 2104HMAC-SHA1
	 */
	private binary function HMAC_SHA1( required string signKey, required string signMessage ) {
		var jMsg = javacast( "string", arguments.signMessage ).getBytes( encryption_charset );
		var jKey = javacast( "string", arguments.signKey ).getBytes( encryption_charset );
		var key  = createObject( "java", "javax.crypto.spec.SecretKeySpec" ).init( jKey, "HmacSHA1" );
		var mac  = createObject( "java", "javax.crypto.Mac" ).getInstance( key.getAlgorithm() );

		mac.init( key );
		mac.update( jMsg );

		return mac.doFinal();
	}

	/**
	 * @description Generate RSA MD5 hash
	 */
	string function MD5inBase64( required content ) {
		var result = 0;
		var digest = createObject( "java", "java.security.MessageDigest" );
		digest     = digest.getInstance( "MD5" );
		if ( isSimpleValue( arguments.content ) ) {
			result = digest.digest( arguments.content.getBytes() );
		} else {
			result = digest.digest( arguments.content );
		}
		return toBase64( result );
	}


	/**
	 * Helper function to catch missing bucket name
	 */
	private function requireBucketName( bucketName ) {
		if ( isNull( arguments.bucketName ) || !len( arguments.bucketName ) ) {
			throw(
				"bucketName is required.  Please provide the name of the bucket to access or set a default bucket name in the SDk."
			);
		}
	}

	/**
	 * Determine mime type from the file extension
	 * */
	string function getFileMimeType( required string filePath ) {
		var contentType = "binary/octet-stream";
		if ( len( arguments.filePath ) ) {
			var ext = listLast( arguments.filePath, "." );
			if ( structKeyExists( variables.mimeTypes, ext ) ) {
				contentType = variables.mimeTypes[ ext ];
			} else {
				try {
					contentType = getPageContext()
						.getServletContext()
						.getMimeType( arguments.filePath );
				} catch ( any cfcatch ) {
				}
				if ( !isDefined( "contentType" ) ) {
					contentType = "binary/octet-stream";
				}
			}
		}
		return contentType;
	}

}

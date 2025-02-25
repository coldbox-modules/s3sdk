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
 * s3_ssl : Whether to use ssl on all calls or not (Optional, defaults to false)
 */
component accessors="true" singleton {

	// DI
	property name="log"          inject="logbox:logger:{this}";
	property name="asyncManager" inject="box:AsyncManager";

	// Properties
	property name="accessKey";
	property name="secretKey";
	property name="encryptionCharset";
	property name="ssl";
	property name="URLEndpoint";
	property name="URLEndpointHostname";
	property name="awsRegion";
	property name="awsDomain";
	property name="defaultTimeOut";
	property name="defaultDelimiter";
	property name="defaultBucketName";
	property name="defaultCacheControl";
	property name="defaultStorageClass";
	property name="defaultObjectOwnership";
	property name="defaultACL";
	property name="throwOnRequestError";
	property name="retriesOnError";
	property name="autoContentType";
	property name="autoMD5";
	property name="mimeTypes";
	property name="serviceName";
	property name="defaultEncryptionAlgorithm";
	property name="defaultEncryptionKey";
	property name="multiPartByteThreshold";
	property name="defaultBlockPublicAcls";
	property name="defaultIgnorePublicAcls";
	property name="defaultBlockPublicPolicy";
	property name="defaultRestrictPublicBuckets";
	property name="urlStyle";

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
	 * @accessKey                    The Amazon access key.
	 * @secretKey                    The Amazon secret key.
	 * @awsDomain                    The Domain used S3 Service (amazonws.com, digitalocean.com, storage.googleapis.com). Defaults to amazonws.com
	 * @awsRegion                    The Amazon region. Defaults to us-east-1 for amazonaws.com
	 * @encryptionCharset            The charset for the encryption. Defaults to UTF-8.
	 * @signature                    The signature version to calculate, "V2" is deprecated but more compatible with other endpoints. "V4" requires Sv4Util.cfc & ESAPI on Lucee. Defaults to V4
	 * @ssl                          True if the request should use SSL. Defaults to true.
	 * @defaultTimeOut               Default HTTP timeout for all requests. Defaults to 300.
	 * @defaultDelimiter             Delimter to use for getBucket calls. "/" is standard to treat keys as file paths
	 * @defaultBucketName            Bucket name to use by default
	 * @defaultCacheControl          Default caching policy for objects. Defaults to: no-store, no-cache, must-revalidate
	 * @defaultStorageClass          Default storage class for objects that affects cost, access speed and durability. Defaults to STANDARD.
	 * @defaultACL                   Default access control policy for objects and buckets. Defaults to public-read.
	 * @throwOnRequestError          If an exception should be thrown for request errors. Defaults to true.
	 * @autoContentType              Tries to determine content type of file by file extension. Defaults to false.
	 * @autoMD5                      Calculates MD5 hash of content automatically. Defaults to false.
	 * @debug                        Used to turn debugging on or off outside of logbox. Defaults to false.
	 * @defaultEncryptionAlgorithm   The default server side encryption algorithm to use.  Usually "AES256". Not needed if using custom defaultEncryptionKey
	 * @defaultEncryptionKey         The default base64 encoded AES 356 bit key for server side encryption.
	 * @multiPartByteThreshold       Min size for multi-part uploads
	 * @defaultObjectOwnership       Default bucket object ownership.  One of the values BucketOwnerPreferred, ObjectWriter, BucketOwnerEnforced
	 * @defaultBlockPublicAcls       Specifies whether Amazon S3 should block public access control lists (ACLs) for this bucket and objects in this bucket.
	 * @defaultIgnorePublicAcls      Specifies whether Amazon S3 should block public bucket policies for this bucket. Setting this element to TRUE causes Amazon S3 to reject calls to PUT Bucket policy if the specified bucket policy allows public access.
	 * @defaultBlockPublicPolicy     Specifies whether Amazon S3 should ignore public ACLs for this bucket and objects in this bucket. Setting this element to TRUE causes Amazon S3 to ignore all public ACLs on this bucket and objects in this bucket.
	 * @defaultRestrictPublicBuckets Specifies whether Amazon S3 should restrict public bucket policies for this bucket. Setting this element to TRUE restricts access to this bucket to only AWS service principals and authorized users within this account if the bucket has a public policy.
	 * @urlStyle                     Specifies the format of the URL whether it is the `path` format or `virtual` format. Defaults to path. For more information see https://docs.aws.amazon.com/AmazonS3/latest/userguide/VirtualHosting.html
	 *
	 * @return An AmazonS3 instance.
	 */
	AmazonS3 function init(
		required string accessKey,
		required string secretKey,
		string  awsDomain                    = "amazonaws.com",
		string  awsRegion                    = "", //        us-east-1 default for aws
		string  encryptionCharset            = "UTF-8",
		string  signatureType                = "V4",
		boolean ssl                          = true,
		string  defaultTimeOut               = 300,
		string  defaultDelimiter             = "/",
		string  defaultBucketName            = "",
		string  defaultCacheControl          = "no-store, no-cache, must-revalidate",
		string  defaultStorageClass          = this.S3_STANDARD,
		string  defaultACL                   = this.ACL_PUBLIC_READ,
		string  throwOnRequestError          = true,
		numeric retriesOnError               = 3,
		boolean autoContentType              = false,
		boolean autoMD5                      = false,
		string  serviceName                  = "s3",
		boolean debug                        = false,
		string  defaultEncryptionAlgorithm   = "",
		string  defaultEncryptionKey         = "",
		numeric multiPartByteThreshold       = 5242880, // 5.2MB is the AWS default minimum size for multipart uploads
		string defaultObjectOwnership        = "ObjectWriter",
		boolean defaultBlockPublicAcls       = false,
		boolean defaultIgnorePublicAcls      = false,
		boolean defaultBlockPublicPolicy     = false,
		boolean defaultRestrictPublicBuckets = false,
		string urlStyle                      = "path"
	){
		if ( arguments.awsDomain == "amazonaws.com" && arguments.awsRegion == "" ) {
			arguments.awsRegion = "us-east-1";
		}
		/*
			Add backwards compatability for the previous key name
			'encryption_charset'. Remove this from the next major release.
		*/
		if ( arguments.keyExists( "encryption_charset" ) ) {
			arguments.encryptionCharset = arguments.encryption_charset;
		}
		variables.accessKey                    = arguments.accessKey;
		variables.secretKey                    = arguments.secretKey;
		variables.encryptionCharset            = arguments.encryptionCharset;
		variables.signatureType                = arguments.signatureType;
		variables.awsDomain                    = arguments.awsDomain;
		variables.awsRegion                    = arguments.awsRegion;
		variables.defaultTimeOut               = arguments.defaultTimeOut;
		variables.defaultDelimiter             = arguments.defaultDelimiter;
		variables.defaultBucketName            = arguments.defaultBucketName;
		variables.defaultCacheControl          = arguments.defaultCacheControl;
		variables.defaultStorageClass          = arguments.defaultStorageClass;
		variables.defaultACL                   = arguments.defaultACL;
		variables.throwOnRequestError          = arguments.throwOnRequestError;
		variables.retriesOnError               = arguments.retriesOnError;
		variables.autoContentType              = arguments.autoContentType;
		variables.autoMD5                      = ( variables.signatureType == "V2" || arguments.autoMD5 ? "auto" : "" );
		variables.serviceName                  = arguments.serviceName;
		variables.defaultEncryptionAlgorithm   = arguments.defaultEncryptionAlgorithm;
		variables.defaultEncryptionKey         = arguments.defaultEncryptionKey;
		variables.multiPartByteThreshold       = arguments.multiPartByteThreshold;
		variables.defaultObjectOwnership       = arguments.defaultObjectOwnership;
		variables.defaultBlockPublicAcls       = arguments.defaultBlockPublicAcls;
		variables.defaultIgnorePublicAcls      = arguments.defaultIgnorePublicAcls;
		variables.defaultBlockPublicPolicy     = arguments.defaultBlockPublicPolicy;
		variables.defaultRestrictPublicBuckets = arguments.defaultRestrictPublicBuckets;
		variables.urlStyle                     = arguments.urlStyle;

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

	function createSignatureUtil( required string type ){
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
	 * @return The AmazonS3 Instance.
	 */
	AmazonS3 function setAuth( required string accessKey, required string secretKey ){
		variables.accessKey = arguments.accessKey;
		variables.secretKey = arguments.secretKey;
		return this;
	}

	AmazonS3 function setAWSDomain( required string domain ){
		variables.awsDomain = arguments.domain;
		buildUrlEndpoint();
		return this;
	}

	AmazonS3 function setAWSRegion( required string region ){
		variables.awsRegion = arguments.region;
		buildUrlEndpoint();
		return this;
	}

	/**
	 * This function builds variables.UrlEndpoint and variables.URLEndpointHostname according to credentials and ssl configuration, usually called after init() for you automatically.
	 */
	AmazonS3 function buildUrlEndpoint( string bucketName ){
		// Build accordingly
		var URLEndPointProtocol = ( variables.ssl ) ? "https://" : "http://";

		var hostnameComponents = [];
		if ( variables.urlStyle == "path" ) {
			if ( variables.awsDomain contains "amazonaws.com" ) {
				hostnameComponents.append( "s3" );
			}
			if ( len( variables.awsRegion ) ) {
				hostnameComponents.append( variables.awsRegion );
			}
		} else if ( variables.urlStyle == "virtual" ) {
			if ( variables.awsDomain contains "amazonaws.com" ) {
				if ( !isNull( arguments.bucketName ) ) {
					hostnameComponents.append( arguments.bucketName );
				}

				hostnameComponents.append( "s3" );

				if ( len( variables.awsRegion ) ) {
					hostnameComponents.append( variables.awsRegion );
				}
			}
		}
		hostnameComponents.append( variables.awsDomain );
		variables.URLEndpointHostname = arrayToList( hostnameComponents, "." );
		variables.URLEndpoint         = URLEndpointProtocol & variables.URLEndpointHostname;
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
	AmazonS3 function setSSL( boolean useSSL = true ){
		variables.ssl = arguments.useSSL;
		buildUrlEndpoint();
		return this;
	}

	/**
	 * List all the buckets associated with the Amazon credentials.
	 *
	 * @return
	 */
	array function listBuckets(){
		var results = s3Request();

		var bucketsXML = xmlSearch( results.response, "//*[local-name()='Bucket']" );

		return arrayMap( bucketsXML, function( node ){
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
	 * @return The region code for the bucket.
	 */
	string function getBucketLocation( required string bucketName = variables.defaultBucketName ){
		requireBucketName( arguments.bucketName );
		var results = s3Request( resource = arguments.bucketname, parameters = { "location" : true } );

		if ( results.error ) {
			throw( message = "Error making Amazon REST Call", detail = results.message );
		}
		// Should this return whatever comes from AWS? It seems like hardcoding a potentially wrong answer is not a good idea.
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
	 * @return The bucket version status or an empty string if there is none.
	 */
	string function getBucketVersionStatus( required string bucketName = variables.defaultBucketName ){
		requireBucketName( arguments.bucketName );
		var results = s3Request( resource = arguments.bucketname, parameters = { "versioning" : true } );

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
	 * @return True if the request was successful.
	 */
	boolean function setBucketVersionStatus(
		required string bucketName = variables.defaultBucketName,
		boolean version            = true
	){
		requireBucketName( arguments.bucketName );
		var constraintXML = "";
		var headers       = { "content-type" : "text/plain" };

		if ( arguments.version ) {
			headers[ "?versioning" ] = "";
			constraintXML            = "<VersioningConfiguration xmlns=""http://s3.amazonaws.com/doc/2006-03-01/""><Status>Enabled</Status></VersioningConfiguration>";
		}

		var results = s3Request(
			method   = "PUT",
			resource = arguments.bucketName,
			body     = constraintXML,
			headers  = headers
		);

		return results.responseheader.status_code == 200;
	}

	/**
	 * Gets a bucket's or object's ACL policy.
	 *
	 * @bucketName The bucket to get the ACL.
	 * @uri        An optional resource uri to get the ACL.
	 *
	 * @return An array containing the ACL for the given resource.
	 */
	array function getAccessControlPolicy(
		required string bucketName = variables.defaultBucketName,
		string uri                 = ""
	){
		requireBucketName( arguments.bucketName );
		var resource = arguments.bucketName;

		if ( len( arguments.uri ) ) {
			resource = resource & "/" & arguments.uri;
		}

		var results = s3Request( resource = resource, parameters = { "acl" : true } );

		var grantsXML = xmlSearch( results.response, "//*[local-name()='Grant']" );
		return arrayMap( grantsXML, function( node ){
			return {
				"type"        : node.grantee.XMLAttributes[ "xsi:type" ],
				"displayName" : "",
				"permission"  : node.permission.XMLText,
				"uri"         : node.grantee.XMLAttributes[ "xsi:type" ] == "Group" ? node.grantee.uri.xmlText : node.grantee.displayName.xmlText
			};
		} );
	}


	/**
	 * Sets a bucket's or object's ACL policy.
	 *
	 * @bucketName The bucket to set the ACL.
	 * @uri        An optional resource uri to set the ACL.
	 * @acl        The security policy to use. Specify a canned ACL like "public-read" as a string, or provide a struct in the format of the "grants" key returned by getObjectACL()
	 * @see        https://docs.aws.amazon.com/AmazonS3/latest/userguide/acl_overview.html#permissions
	 */
	void function setAccessControlPolicy(
		required string bucketName = variables.defaultBucketName,
		string uri                 = "",
		any acl
	){
		requireBucketName( arguments.bucketName );

		var resource = arguments.bucketName;

		if ( len( arguments.uri ) ) {
			resource = resource & "/" & arguments.uri;
		}

		s3Request(
			method     = "PUT",
			resource   = resource,
			parameters = { "acl" : true },
			headers    = applyACLHeaders( acl = arguments.acl )
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
	 * @see        https://docs.aws.amazon.com/AmazonS3/latest/API/API_ListObjectsV2.html
	 *
	 * @return The bucket contents.
	 */
	array function getBucket(
		required string bucketName = variables.defaultBucketName,
		string prefix              = "",
		string marker              = "",
		string maxKeys             = "",
		string delimiter           = variables.defaultDelimiter
	){
		requireBucketName( arguments.bucketName );

		var parameters = { "list-type" : 2 };

		if ( len( arguments.prefix ) ) {
			parameters[ "prefix" ] = arguments.prefix;
		}

		if ( len( arguments.marker ) ) {
			parameters[ "marker" ] = arguments.marker;
		}

		if ( isNumeric( arguments.maxKeys ) ) {
			parameters[ "max-keys" ] = arguments.maxKeys;
		}

		if ( len( arguments.delimiter ) ) {
			parameters[ "delimiter" ] = arguments.delimiter;
		}

		var results = s3Request( resource = arguments.bucketName, parameters = parameters );

		var contentsXML = xmlSearch( results.response, "//*[local-name()='Contents']" );
		var foldersXML  = xmlSearch( results.response, "//*[local-name()='CommonPrefixes']" );

		var objectContents = arrayMap( contentsXML, function( node ){
			return {
				"key"          : trim( node.key.xmlText ),
				"lastModified" : trim( node.lastModified.xmlText ),
				"size"         : trim( node.Size.xmlText ),
				"eTag"         : replace( trim( node.etag.xmlText ), """", "", "all" ),
				"isDirectory"  : (
					(
						findNoCase( "_$folder$", node.key.xmlText ) || (
							len( delimiter ) && node.key.xmlText.endsWith( delimiter )
						)
					) ? true : false
				)
			};
		} );

		var folderContents = arrayMap( foldersXML, function( node ){
			return {
				"key"          : reReplaceNoCase( trim( node.prefix.xmlText ), "\/$", "" ),
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
	 * @bucketName      The name for the new bucket.
	 * @acl             The security policy to use. Specify a canned ACL like "public-read" as a string, or provide a struct in the format of the "grants" key returned by getObjectACL()
	 * @location        The bucket location.
	 * @objectOwnership One of the values BucketOwnerPreferred, ObjectWriter, BucketOwnerEnforced
	 *
	 * @return True if the bucket was created successfully.
	 */
	boolean function putBucket(
		required string bucketName    = variables.defaultBucketName,
		string acl                    = variables.defaultACL,
		string location               = "USA",
		string objectOwnership        = variables.defaultObjectOwnership,
		boolean BlockPublicAcls       = false,
		boolean IgnorePublicAcls      = false,
		boolean BlockPublicPolicy     = false,
		boolean RestrictPublicBuckets = false
	){
		requireBucketName( arguments.bucketName );
		var constraintXML = arguments.location == "EU" ? "<CreateBucketConfiguration><LocationConstraint>EU</LocationConstraint></CreateBucketConfiguration>" : "";
		var headers       = { "content-type" : "text/xml" };

		if ( len( arguments.objectOwnership ) ) {
			if (
				!listFindNoCase(
					"BucketOwnerPreferred,ObjectWriter,BucketOwnerEnforced",
					arguments.objectOwnership
				)
			) {
				throw(
					message = "Invalid value [#arguments.objectOwnership#] for [objectOwnership] when creating bucket.",
					detail  = "Valid options are: [BucketOwnerPreferred, ObjectWriter, BucketOwnerEnforced]"
				);
			}
			headers[ "x-amz-object-ownership" ] = arguments.objectOwnership;
		}

		var results = s3Request(
			method   = "PUT",
			resource = arguments.bucketName,
			body     = constraintXML,
			headers  = headers
		);

		// s3 does not provide a way to set this when creating the bucket
		putBucketPublicAccess(
			arguments.bucketName,
			arguments.BlockPublicAcls,
			arguments.IgnorePublicAcls,
			arguments.BlockPublicPolicy,
			arguments.RestrictPublicBuckets
		);

		// Must set ACL in second step in case public access settings above would prevent the ACL from being saved.
		putBucketACL( arguments.bucketName, arguments.acl );

		return results.responseheader.status_code == 200;
	}

	/**
	 * Sets a bucket's ACL.
	 *
	 * @bucketName The name for the new bucket.
	 * @acl        The security policy to use. Specify a canned ACL like "public-read" as a string, or provide a struct in the format of the "grants" key returned by getObjectACL()
	 */
	function putBucketACL( required string bucketName = variables.defaultBucketName, required string acl ){
		requireBucketName( arguments.bucketName );

		var results = s3Request(
			method       = "PUT",
			resource     = arguments.bucketName,
			parameters   = { "acl" : "" },
			headers      = applyACLHeaders( {}, arguments.acl ),
			throwOnError = true
		);
	}

	/**
	 * Set the block public access configuration on a bucket
	 *
	 * @bucketName            The name for the new bucket.
	 * @BlockPublicAcls       Specifies whether Amazon S3 should block public access control lists (ACLs) for this bucket and objects in this bucket.
	 * @IgnorePublicAcls      Specifies whether Amazon S3 should block public bucket policies for this bucket. Setting this element to TRUE causes Amazon S3 to reject calls to PUT Bucket policy if the specified bucket policy allows public access.
	 * @BlockPublicPolicy     Specifies whether Amazon S3 should ignore public ACLs for this bucket and objects in this bucket. Setting this element to TRUE causes Amazon S3 to ignore all public ACLs on this bucket and objects in this bucket.
	 * @RestrictPublicBuckets Specifies whether Amazon S3 should restrict public bucket policies for this bucket. Setting this element to TRUE restricts access to this bucket to only AWS service principals and authorized users within this account if the bucket has a public policy.
	 *
	 * @return True if the bucket was created successfully.
	 */
	function putBucketPublicAccess(
		required string bucketName    = variables.defaultBucketName,
		boolean BlockPublicAcls       = true,
		boolean IgnorePublicAcls      = true,
		boolean BlockPublicPolicy     = true,
		boolean RestrictPublicBuckets = true
	){
		requireBucketName( arguments.bucketName );
		var body = "
			<PublicAccessBlockConfiguration xmlns=""http://s3.amazonaws.com/doc/2006-03-01/"">
				<BlockPublicAcls>#uCase( arguments.BlockPublicAcls )#</BlockPublicAcls>
				<IgnorePublicAcls>#uCase( arguments.IgnorePublicAcls )#</IgnorePublicAcls>
				<BlockPublicPolicy>#uCase( arguments.BlockPublicPolicy )#</BlockPublicPolicy>
				<RestrictPublicBuckets>#uCase( arguments.RestrictPublicBuckets )#</RestrictPublicBuckets>
			</PublicAccessBlockConfiguration>";

		var headers = { "content-type" : "text/xml" };

		var results = s3Request(
			method       = "PUT",
			resource     = arguments.bucketName,
			body         = body,
			headers      = headers,
			parameters   = { "publicAccessBlock" : "" },
			throwOnError = true
		);
		return;
	}

	/**
	 * Get the block public access configuration on a bucket
	 *
	 * @bucketName The name for the new bucket.
	 *
	 * @return struct with keys BlockPublicAcls, IgnorePublicAcls, BlockPublicPolicy, RestrictPublicBuckets
	 */
	function getBucketPublicAccess( required string bucketName = variables.defaultBucketName ){
		requireBucketName( arguments.bucketName );

		var results = s3Request(
			method       = "GET",
			resource     = arguments.bucketName,
			parameters   = { "publicAccessBlock" : "" },
			throwOnError = true
		);
		var data = xmlParse( results.response );
		return {
			"BlockPublicAcls"       : data.PublicAccessBlockConfiguration.BlockPublicAcls.XmlText,
			"IgnorePublicAcls"      : data.PublicAccessBlockConfiguration.IgnorePublicAcls.XmlText,
			"BlockPublicPolicy"     : data.PublicAccessBlockConfiguration.BlockPublicPolicy.XmlText,
			"RestrictPublicBuckets" : data.PublicAccessBlockConfiguration.RestrictPublicBuckets.XmlText
		};
	}



	/**
	 * Checks for the existance of a bucket
	 *
	 * @bucketName The bucket to check for its existance.
	 *
	 * @return True if the bucket exists.
	 */
	boolean function hasBucket( required string bucketName = variables.defaultBucketName ){
		requireBucketName( arguments.bucketName );
		return !arrayIsEmpty(
			arrayFilter( listBuckets(), function( bucket ){
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
	 * @return True, if the bucket was deleted successfully.
	 */
	boolean function deleteBucket(
		required string bucketName = variables.defaultBucketName,
		boolean force              = false
	){
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
	 *                  If not provided, the name of the file will be used.
	 *                  Example: public,max-age=864000  ( 10 days ).
	 *                  For more info look here:
	 *                  http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html##sec14.9
	 *                  Defaults to public-read.
	 *                  was sent correctly.
	 *                  Set to "auto" to calculate the md5 in the client.
	 *                  Defaults to STANDARD.
	 *
	 * @bucketName          The bucket in which to store the object.
	 * @filepath            The absolute file path to read in the binary.
	 * @uri                 The destination uri key to use when saving the object.
	 * @contentType         The file content type. Defaults to binary/octet-stream.
	 * @contentEncoding     The file content encoding, useful to gzip data.
	 * @HTTPTimeout         The HTTP timeout to use
	 * @cacheControl        The caching header to send. Defaults to no caching.
	 * @expires             Sets the expiration header of the object in days.
	 * @acl                 The security policy to use. Specify a canned ACL like "public-read" as a string, or provide a struct in the format of the "grants" key returned by getObjectACL()
	 * @metaHeaders         Additonal metadata headers to add.
	 * @md5                 Set the MD5 hash which allows aws to checksum the object
	 * @storageClass        Sets the S3 storage class which affects cost, access speed and durability.
	 * @encryptionAlgorithm The server side encryption algorithm to use.  Usually "AES256". Not needed if using custom encryptionKey
	 * @encryptionKey       The base64 encoded AES 356 bit key for server side encryption.
	 *
	 * @return The file's eTag
	 */
	string function putObjectFile(
		required string bucketName = variables.defaultBucketName,
		required string filepath,
		string uri                 = "",
		string contentType         = "",
		string contentEncoding     = "",
		numeric HTTPTimeout        = variables.defaultTimeout,
		string cacheControl        = variables.defaultCacheControl,
		string expires             = "",
		any acl                    = variables.defaultACL,
		struct metaHeaders         = {},
		string md5                 = variables.autoMD5,
		string storageClass        = variables.defaultStorageClass,
		string encryptionAlgorithm = variables.defaultEncryptionAlgorithm,
		string encryptionKey       = variables.defaultEncryptionKey
	){
		requireBucketName( arguments.bucketName );

		if ( NOT len( arguments.uri ) ) {
			arguments.uri = getFileFromPath( arguments.filePath );
		}

		if ( arguments.contentType == "" ) {
			arguments.contentType = ( variables.autoContentType ? "auto" : "binary/octet-stream" );
		}
		if ( arguments.contentType == "auto" ) {
			arguments.contentType = getFileMimeType( arguments.filepath );
		}

		var byteCount = getFileInfo( arguments.filepath ).size;

		if ( byteCount <= variables.multiPartByteThreshold ) {
			arguments.data = fileReadBinary( arguments.filepath );
			return putObject( argumentCollection = arguments );
		} else {
			var jFiles = createObject( "java", "java.nio.file.Files" );
			var jPath  = createObject( "java", "java.nio.file.Paths" ).get(
				// Java is less lax on slashes than CF, so getCanonicalPath() cleans that up
				javacast( "string", getCanonicalPath( arguments.filePath ) ),
				javacast( "java.lang.String[]", [] )
			);

			var parts = [];
			try {
				var multipartResponse = createMultiPartUpload( argumentCollection = arguments );
				var uploadId          = xmlParse( multipartResponse.response ).InitiateMultipartUploadResult.UploadId.xmlText;
				var partNumber        = 1;
				var numberOfUploads   = ceiling( byteCount / variables.multiPartByteThreshold );
				for ( var i = 1; i <= numberOfUploads; i++ ) {
					var remaining = byteCount - ( ( i - 1 ) * variables.multiPartByteThreshold );
					parts.append( {
						"uploadId"   : uploadId,
						"partNumber" : i,
						"offset"     : ( i - 1 ) * variables.multiPartByteThreshold,
						"limit"      : remaining <= variables.multiPartByteThreshold ? remaining : variables.multiPartByteThreshold,
						"timeout"    : arguments.HTTPTimeout,
						"channel"    : jFiles.newByteChannel( jPath, [] )
					} );
				}
				try {

					function processPart( part ){
						var channel = part.channel.position( part.offset );
						var buffer  = createObject( "java", "java.nio.ByteBuffer" ).allocate( part.limit );
						channel.read( buffer );

						return {
							"partNumber" : part.partNumber,
							"size"       : part.limit,
							"channel"    : part.channel,
							"response"   : s3Request(
								method     = "PUT",
								resource   = bucketName & "/" & uri,
								body       = buffer.array(),
								timeout    = part.timeout,
								parameters = {
									"uploadId"   : part.uploadId,
									"partNumber" : part.partNumber
								},
								headers = { "content-type" : "binary/octet-stream" }
							)
						};
					}
					// Alow for using outside of `box` context
					if( structKeyExists( variables, "asyncManager" ) ){
						parts = variables.asyncManager.allApply( parts, processPart );
					} else {
						parts = parts.map( processPart );
					}

					var finalizeBody = "<?xml version=""1.0"" encoding=""UTF-8""?><CompleteMultipartUpload xmlns=""http://s3.amazonaws.com/doc/2006-03-01/"">";

					parts.each( function( part, index ){
						finalizeBody &= "
							<Part>
								<ETag>#replace(
							part.response.responseHeader.etag,
							"""",
							"",
							"all"
						)#</ETag>
								<PartNumber>#part.partNumber#</PartNumber>
							</Part>
							";
					} );

					finalizeBody &= "</CompleteMultipartUpload>";

					var finalized = s3Request(
						method     = "POST",
						resource   = buildKeyName( arguments.uri, arguments.bucketName ),
						timeout    = arguments.HTTPTimeout,
						parameters = { "uploadId" : uploadId },
						body       = finalizeBody
					);

					return replace(
						"multipart:" & finalized.response.CompleteMultipartUploadResult.ETag.xmlText,
						"""",
						"",
						"all"
					);

					// If any part of our upload fails, fall back to the default
				} catch ( any e ) {
					s3Request(
						method     = "DELETE",
						resource   = buildKeyName( arguments.uri, arguments.bucketName ),
						timeout    = arguments.HTTPTimeout,
						parameters = { "uploadId" : uploadId }
					);
					rethrow;
				}
			} catch ( any e ) {
				log.error(
					"MultiPart Upload failed to process. The response received was #e.message#",
					{ "exception" : e }
				);
				arguments.data = fileReadBinary( arguments.filepath );
				return putObject( argumentCollection = arguments );
			} finally {
				parts.each( ( p ) => {
					try {
						p.channel.close()
					} catch ( any e ) {
					}
				} );
			}
		}
	}

	/**
	 * Puts an folder in to a bucket.
	 *
	 *               If not provided, the name of the folder will be used.
	 *               Example: public,max-age=864000  ( 10 days ).
	 *               For more info look here:
	 *               http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html##sec14.9
	 *               Defaults to public-read.
	 *
	 * @bucketName   The bucket in which to store the object.
	 * @uri          The destination uri key to use when saving the object.
	 * @contentType  The folder content type. Defaults to binary/octet-stream.
	 * @HTTPTimeout  The HTTP timeout to use
	 * @cacheControl The caching header to send. Defaults to no caching.
	 * @expires      Sets the expiration header of the object in days.
	 * @acl          The security policy to use. Specify a canned ACL like "public-read" as a string, or provide a struct in the format of the "grants" key returned by getObjectACL()
	 * @metaHeaders  Additonal metadata headers to add.
	 *
	 * @return The folder's eTag
	 */
	string function putObjectFolder(
		required string bucketName = variables.defaultBucketName,
		string uri                 = "",
		string contentType         = "binary/octet-stream",
		numeric HTTPTimeout        = variables.defaultTimeOut,
		string cacheControl        = variables.defaultCacheControl,
		string expires             = "",
		any acl                    = variables.defaultACL,
		struct metaHeaders         = {}
	){
		requireBucketName( arguments.bucketName );
		arguments.data = "";
		return putObject( argumentCollection = arguments );
	}

	/**
	 * Create a structure of Amazon-enabled metadata headers.
	 *
	 * @metaHeaders Headers to convert to the Amazon meta headers.
	 *
	 * @return A struct of Amazon-enabled metadata headers.
	 */
	struct function createMetaHeaders( struct metaHeaders = {} ){
		var md = {};
		for ( var key in arguments.metaHeaders ) {
			md[ "x-amz-meta-" & key ] = arguments.metaHeaders[ key ];
		}
		return md;
	}

	/**
	 * Puts an object into a bucket.
	 *
	 *                     This can be binary, string, or anything you'd like.
	 *                     Example: public,max-age=864000  ( 10 days ).
	 *                     For more info look here:
	 *                     http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html##sec14.9
	 *                     Defaults to public-read.
	 *                     was sent correctly.
	 *                     Set to "auto" to calculate the md5 in the client.
	 *                     Defaults to STANDARD.
	 *
	 * @bucketName          The bucket in which to store the object.
	 * @uri                 The destination uri key to use when saving the object.
	 * @data                The content to save as data.
	 * @contentDisposition  The content-disposition header to use when downloading the file.
	 * @contentType         The file/data content type. Defaults to text/plain.
	 * @contentEncoding     The file content encoding, useful to gzip data.
	 * @HTTPTimeout         The HTTP timeout to use.
	 * @cacheControl        The caching header to send. Defaults to no caching.
	 * @expires             Sets the expiration header of the object in days.
	 * @acl                 The security policy to use. Specify a canned ACL like "public-read" as a string, or provide a struct in the format of the "grants" key returned by getObjectACL()
	 * @metaHeaders         Additonal metadata headers to add.
	 * @md5                 Set the MD5 hash which allows aws to checksum the object
	 * @storageClass        Sets the S3 storage class which affects cost, access speed and durability.
	 * @encryptionAlgorithm The server side encryption algorithm to use.  Usually "AES256". Not needed if using custom encryptionKey
	 * @encryptionKey       The base64 encoded AES 356 bit key for server side encryption.
	 *
	 * @return The object's eTag.
	 */
	string function putObject(
		required string bucketName = variables.defaultBucketName,
		required string uri,
		any data                   = "",
		string contentDisposition  = "",
		string contentType         = ( variables.autoContentType ? "auto" : "text/plain" ),
		string contentEncoding     = "",
		numeric HTTPTimeout        = variables.defaultTimeOut,
		string cacheControl        = variables.defaultCacheControl,
		string expires             = "",
		any acl                    = variables.defaultACL,
		struct metaHeaders         = {},
		string md5                 = variables.autoMD5,
		string storageClass        = variables.defaultStorageClass,
		string encryptionAlgorithm = variables.defaultEncryptionAlgorithm,
		string encryptionKey       = variables.defaultEncryptionKey
	){
		requireBucketName( arguments.bucketName );
		var headers = createMetaHeaders( arguments.metaHeaders );
		applyACLHeaders( headers, arguments.acl );
		applyEncryptionHeaders( headers, arguments );

		if ( len( arguments.storageClass ) ) {
			headers[ "x-amz-storage-class" ] = arguments.storageClass;
		}

		if ( arguments.contentType == "auto" ) {
			arguments.contentType = getFileMimeType( arguments.uri );
		}
		headers[ "content-type" ] = arguments.contentType;

		if ( len( arguments.cacheControl ) ) {
			headers[ "cache-control" ] = arguments.cacheControl;
		};

		if ( arguments.md5 == "auto" ) {
			headers[ "content-md5" ] = mD5inBase64( arguments.data );
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
			method   = "PUT",
			resource = buildKeyName( arguments.uri, arguments.bucketName ),
			body     = arguments.data,
			timeout  = arguments.HTTPTimeout,
			headers  = headers
		);

		if ( results.responseHeader.status_code == 200 ) {
			return replace( results.responseHeader.etag, """", "", "all" );
		}

		return "";
	}

	/**
	 * Get an object's metadata information.
	 *
	 * @bucketName    The bucket the object resides in.
	 * @uri           The object URI to retrieve the info.
	 * @encryptionKey The base64 encoded AES 356 bit key for server side encryption.
	 *
	 * @return The object's metadata information.
	 */
	struct function getObjectInfo(
		required string bucketName = variables.defaultBucketName,
		required string uri,
		string encryptionKey = variables.defaultEncryptionKey
	){
		requireBucketName( arguments.bucketName );
		var headers = applyEncryptionHeaders( {}, arguments );
		var results = s3Request(
			method   = "HEAD",
			resource = buildKeyName( arguments.uri, arguments.bucketName ),
			headers  = headers
		);

		var metadata = {};
		for ( var key in results.responseHeader ) {
			metadata[ key ] = results.responseHeader[ key ];
		}
		return metadata;
	}

	/**
	 * Get an object's ACL information.
	 *
	 *             Also a top level "grants" key which is a struct containing keys FULL_CONTROL, WRITE, WRITE_ACP, READ, and READ_ACP.  Each
	 *             of which is an array containing zero or more structs representing a grantee which is represented as a struct with an ID, emailAddress, or URI key based on type.
	 *
	 * @bucketName   The bucket the object resides in.
	 * @uri          The object URI to retrieve the info.
	 * @throwOnError Flag to throw exceptions on any error or not, default is true
	 *
	 * @return The object's ACL information.  A struct containing a top level "owner" key which is a struct with "ID" and "Displayname" keys.
	 */
	struct function getObjectACL(
		required string bucketName = variables.defaultBucketName,
		required string uri,
		throwOnError = false
	){
		requireBucketName( arguments.bucketName );
		var results = s3Request(
			method       = "GET",
			resource     = buildKeyName( arguments.uri, arguments.bucketName ),
			parameters   = { "acl" : "" },
			throwOnError = throwOnError
		);
		var ACLs = {
			"owner"  : { "ID" : "", "DisplayName" : "" },
			"grants" : {
				"FULL_CONTROL" : [],
				"WRITE"        : [],
				"WRITE_ACP"    : [],
				"READ"         : [],
				"READ_ACP"     : []
			}
		};
		if ( !results.error ) {
			// Set owner
			for ( var child in results.response.AccessControlPolicy.owner.XMLChildren ) {
				ACLs.owner[ child.XMLName ] = child.XMLText;
			}
			for ( var child in results.response.AccessControlPolicy.AccessControlList.XMLChildren ) {
				var grant = { "type" : child.Grantee.XMLAttributes[ "xsi:type" ] };
				for ( var grantee in child.Grantee.XMLChildren ) {
					grant[ grantee.XMLName ] = grantee.XMLText;
				}
				ACLs.grants[ child.Permission.XMLText ].append( grant );
			}
		}

		return ACLs;
	}

	/**
	 * Check if an object exists in the bucket
	 *
	 * @bucketName The bucket the object resides in.
	 * @uri        The object URI to check on.
	 *
	 * @return True/false whether the object exists
	 */
	boolean function objectExists( required string bucketName = variables.defaultBucketName, required string uri ){
		requireBucketName( arguments.bucketName );
		var results = s3Request(
			method       = "HEAD",
			resource     = buildKeyName( arguments.uri, arguments.bucketName ),
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
	 * @bucketName      The bucket the object resides in.
	 * @uri             The uri to the object to create a link for.
	 * @minutesValid    The minutes the link is valid for. Defaults to 60 minutes.
	 * @useSSL          Use SSL for the returned url.
	 * @method          HTTP method that will be used
	 * @acl             The security policy to use. Specify a canned ACL like "public-read" as a string, or provide a struct in the format of the "grants" key returned by getObjectACL(). If omitted, any ACL will be allowed when PUTting the file.
	 * @metaHeaders     Additonal metadata headers to add.
	 * @contentType     The object content type for PUT.  If omitted, any content-type will be allowed when PUTting the file.
	 * @encryptionKey   The base64 encoded AES 356 bit key for server side encryption.
	 * @responseHeaders A struct of headers to be forced for the HTTP response of GET requests.  Valid options are content-type, content-language, expires, cache-control, content-disposition, content-encoding
	 *
	 * @return An authenticated url to the resource.
	 */
	string function getAuthenticatedURL(
		required string bucketName = variables.defaultBucketName,
		required string uri,
		string minutesValid = 60,
		boolean useSSL      = variables.ssl,
		string method       = "GET",
		any acl             = "",
		struct metaHeaders  = {},
		string contentType,
		string encryptionKey   = variables.defaultEncryptionKey,
		struct responseHeaders = {}
	){
		requireBucketName( arguments.bucketName );

		var headers = createMetaHeaders( arguments.metaHeaders );
		applyEncryptionHeaders( headers, arguments );

		if ( !isNull( arguments.contentType ) ) {
			headers[ "content-type" ] = arguments.contentType;
		}

		if ( !isNull( arguments.acl ) ) {
			applyACLHeaders( headers, arguments.acl );
		}

		var hostname = "#bucketName#.#variables.URLEndpointHostname#";

		var requestParams        = { "X-Amz-Expires" : round( arguments.minutesValid * 60 ) };
		var validResponseHeaders = [
			"content-type",
			"content-language",
			"expires",
			"cache-control",
			"content-disposition",
			"content-encoding"
		];
		responseHeaders.each( ( header, value ) => {
			if ( !validResponseHeaders.findNoCase( header ) ) {
				throw(
					message = "Invalid Reponse Header for signed URL: [#header#].",
					detail  = "Valid options are: [#validResponseHeaders.toList()#]"
				);
			}
			if ( header == "content-type" && value == "auto" ) {
				value = getFileMimeType( uri );
			}
			requestParams[ "response-" & header ] = value;
		} );

		var sigData = variables.signatureUtil.generateSignatureData(
			requestMethod      = arguments.method,
			hostName           = hostname,
			requestURI         = arguments.uri,
			requestBody        = "",
			requestHeaders     = headers,
			requestParams      = requestParams,
			accessKey          = variables.accessKey,
			secretKey          = variables.secretKey,
			regionName         = variables.awsRegion,
			serviceName        = variables.serviceName,
			presignDownloadURL = true
		);

		var HTTPPrefix = arguments.useSSL ? "https://" : "http://";
		return "#HTTPPrefix##hostname##variables.signatureUtil.buildCanonicalURI( arguments.uri )#?#sigData.canonicalQueryString#&X-Amz-Signature=#sigData.signature#";
	}

	struct function createMultiPartUpload(
		required string bucketName,
		required string uri,
		string  contentType         = "",
		string  contentEncoding     = "",
		string contentDisposition   = "",
		numeric HTTPTimeout         = variables.defaultTimeout,
		string  cacheControl        = variables.defaultCacheControl,
		string  expires             = 120,
		any     acl                 = variables.defaultACL,
		struct  metaHeaders         = {},
		string  md5                 = variables.autoMD5,
		string  storageClass        = variables.defaultStorageClass,
		string  encryptionAlgorithm = variables.defaultEncryptionAlgorithm,
		string  encryptionKey       = variables.defaultEncryptionKey
	){
		requireBucketName( arguments.bucketName );
		var headers = createMetaHeaders( arguments.metaHeaders );
		applyACLHeaders( headers, arguments.acl );
		applyEncryptionHeaders( headers, arguments );

		if ( len( arguments.storageClass ) ) {
			headers[ "x-amz-storage-class" ] = arguments.storageClass;
		}

		if ( arguments.contentType == "auto" ) {
			arguments.contentType = getFileMimeType( arguments.uri );
		}

		headers[ "accept" ]       = "text/xml";
		headers[ "content-type" ] = arguments.contentType;

		if ( len( arguments.cacheControl ) ) {
			headers[ "cache-control" ] = arguments.cacheControl;
		};

		if ( arguments.md5 == "auto" ) {
			headers[ "content-md5" ] = mD5inBase64( arguments.data );
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

		return s3Request(
			method        = "POST",
			resource      = buildKeyName( arguments.uri, arguments.bucketName ),
			timeout       = arguments.HTTPTimeout,
			headers       = headers,
			parameters    = { "uploads" : true },
			parseResponse = true
		);

		if ( results.responseHeader.status_code == 200 ) {
			return replace( results.responseHeader.etag, """", "", "all" );
		}

		return "";
	}

	/**
	 * Get an object's metadata information.
	 *
	 * @bucketName    The bucket the object resides in.
	 * @uri           The object URI to retrieve the info.
	 * @encryptionKey The base64 encoded AES 356 bit key for server side encryption.
	 *
	 * @return The object's metadata information.
	 */
	struct function getObject(
		required string bucketName = variables.defaultBucketName,
		required string uri,
		string encryptionKey = variables.defaultEncryptionKey
	){
		buildUrlEndpoint( arguments.bucketName );
		requireBucketName( arguments.bucketName );

		var headers = applyEncryptionHeaders( {}, arguments );

		var results = s3Request(
			method   = "GET",
			headers  = headers,
			resource = buildKeyName( arguments.uri, arguments.bucketName )
		);
		return results;
	}

	/**
	 * Gets an object from a bucket.
	 *
	 * @bucketName          The bucket in which to store the object.
	 * @uri                 The destination uri key to use when saving the object.
	 * @filepath            The file path write the object to, if no filename given filename from uri is used.
	 * @HTTPTimeout         The HTTP timeout to use.
	 * @getAsBinary         Treat the response body as binary instead of text.
	 * @encryptionAlgorithm The server side encryption algorithm to use.  Usually "AES256". Not needed if using custom encryptionKey
	 * @encryptionKey       The base64 encoded AES 356 bit key for server side encryption.
	 *
	 * @return The object's eTag.
	 */
	struct function downloadObject(
		required string bucketName = variables.defaultBucketName,
		required string uri,
		required string filepath,
		numeric HTTPTimeout        = variables.defaultTimeOut,
		boolean getAsBinary        = "no",
		string encryptionAlgorithm = variables.defaultEncryptionAlgorithm,
		string encryptionKey       = variables.defaultEncryptionKey
	){
		requireBucketName( arguments.bucketName );

		// if filepath is a directory, append filename
		if ( right( arguments.filepath, 1 ) == "/" || right( arguments.filepath, 1 ) == "\" ) {
			arguments.filepath &= listLast( arguments.uri, "/\" );
		}

		var headers = applyEncryptionHeaders( {}, arguments );
		var results = s3Request(
			method        = "GET",
			headers       = headers,
			resource      = buildKeyName( arguments.uri, arguments.bucketName ),
			filename      = arguments.filepath,
			timeout       = arguments.HTTPTimeout,
			getAsBinary   = arguments.getAsBinary,
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
	 * @return Returns true if the object is deleted successfully.
	 */
	boolean function deleteObject( required string bucketName = variables.defaultBucketName, required string uri ){
		requireBucketName( arguments.bucketName );

		var results = s3Request(
			method   = "DELETE",
			resource = buildKeyName( arguments.uri, arguments.bucketName )
		);

		return results.responseheader.status_code == 204;
	}

	/**
	 * Copies an object.
	 *
	 *               Defaults to STANDARD.
	 *               Defaults to STANDARD.
	 *
	 * @fromBucket                The source bucket
	 * @fromURI                   The source URI
	 * @toBucket                  The destination bucket
	 * @toURI                     The destination URI
	 * @acl                       The security policy to use. Specify a canned ACL like "public-read" as a string, or provide a struct in the format of the "grants" key returned by getObjectACL()
	 * @storageClass              Sets the S3 storage class which affects cost, access speed and durability.
	 * @metaHeaders               Additonal metadata headers to add.
	 * @storageClass              Sets the S3 storage class which affects cost, access speed and durability.
	 * @contentType               The file content type. Defaults to binary/octet-stream.
	 * @throwOnError              Flag to throw exceptions on any error or not, default is true
	 * @encryptionAlgorithm       The server side encryption algorithm to use.  Usually "AES256". Not needed if using custom encryptionKey
	 * @encryptionKey             The base64 encoded AES 356 bit key for server side encryption.
	 * @encryptionAlgorithmSource The server side encryption algorithm to use for the source file.  Usually "AES256". Not needed if using custom encryptionKeySource
	 * @encryptionKeySource       The base64 encoded AES 356 bit key used to encrypt the source file
	 *
	 * @return True if the object was copied correctly.
	 */
	boolean function copyObject(
		required string fromBucket = variables.defaultBucketName,
		required string fromURI,
		required string toBucket = variables.defaultBucketName,
		required string toURI,
		any acl             = variables.defaultACL,
		struct metaHeaders  = {},
		string storageClass = variables.defaultStorageClass,
		string contentType,
		boolean throwOnError             = variables.throwOnRequestError,
		string encryptionAlgorithm       = variables.defaultEncryptionAlgorithm,
		string encryptionKey             = variables.defaultEncryptionKey,
		string encryptionAlgorithmSource = variables.defaultEncryptionAlgorithm,
		string encryptionKeySource       = variables.defaultEncryptionKey
	){
		var headers = createMetaHeaders( arguments.metaHeaders );
		applyEncryptionHeaders( headers, arguments );
		headers[ "content-length" ] = 0;

		// If not passed, keep source files content type
		if ( !isNull( arguments.contentType ) ) {
			if ( arguments.contentType == "auto" ) {
				arguments.contentType = getFileMimeType( arguments.toURI );
			}
			headers[ "content-type" ]             = arguments.contentType;
			headers[ "x-amz-metadata-directive" ] = "REPLACE";
		}

		if ( not structIsEmpty( arguments.metaHeaders ) ) {
			headers[ "x-amz-metadata-directive" ] = "REPLACE";
		}

		headers[ "x-amz-copy-source" ] = signatureUtil.urlEncodePath(
			"/#arguments.fromBucket#/#arguments.fromURI#"
		);
		applyACLHeaders( headers, arguments.acl );

		if ( len( arguments.storageClass ) ) {
			headers[ "x-amz-storage-class" ] = arguments.storageClass;
		}

		var results = s3Request(
			method       = "PUT",
			resource     = arguments.toBucket & "/" & arguments.toURI,
			metaHeaders  = metaHeaders,
			headers      = headers,
			throwOnError = throwOnError
		);

		return ( results.responseheader.status_code == 204 || results.responseheader.status_code == 200 );
	}

	/**
	 * Renames an object by copying then deleting original.
	 *
	 * @oldBucketName       The source bucket.
	 * @oldFileKey          The source URI.
	 * @newBucketName       The destination bucket.
	 * @newFileKey          The destination URI.
	 * @acl                 The security policy to use. Specify a canned ACL like "public-read" as a string, or provide a struct in the format of the "grants" key returned by getObjectACL()
	 * @encryptionAlgorithm The server side encryption algorithm to use.  Usually "AES256". Not needed if using custom encryptionKey
	 * @encryptionKey       The base64 encoded AES 356 bit key for server side encryption.
	 *
	 * @return True if the rename operation is successful.
	 */
	boolean function renameObject(
		string oldBucketName = variables.defaultBucketName,
		required string oldFileKey,
		string newBucketName = variables.defaultBucketName,
		required string newFileKey,
		any acl,
		string encryptionAlgorithm = variables.defaultEncryptionAlgorithm,
		string encryptionKey       = variables.defaultEncryptionKey
	){
		if ( compare( oldBucketName, newBucketName ) || compare( oldFileKey, newFileKey ) ) {
			// If no ACL was passed, attempt to look up the old object's ACL (requires s3:GetObjectAcl permissions or READ_ACP access to the object)
			if ( isNull( arguments.acl ) ) {
				var oldACL = getObjectACL( oldBucketName, oldFileKey );
				// If this is empty, we did not have permissions to get the ACLs
				if ( len( oldACL.owner.id ) ) {
					// Set the new ACL to the grants from the old ACL
					arguments.acl = oldACL.grants;
				}
			}

			copyObject(
				fromBucket                = arguments.oldBucketName,
				fromURI                   = arguments.oldFileKey,
				toBucket                  = arguments.newBucketName,
				toURI                     = arguments.newFileKey,
				acl                       = arguments.acl,
				encryptionAlgorithm       = arguments.encryptionAlgorithm,
				encryptionKey             = arguments.encryptionKey,
				encryptionAlgorithmSource = arguments.encryptionAlgorithm,
				encryptionKeySource       = arguments.encryptionKey
			);
			deleteObject( arguments.oldBucketName, arguments.oldFileKey );
			return true;
		}

		return false;
	}

	/**
	 * Make a request to Amazon S3.
	 *
	 * @method       The HTTP method for the request.
	 * @resource     The resource to hit in the Amazon S3 service.
	 * @body         The body content of the request, if passed.
	 * @headers      A struct of HTTP headers to send.
	 * @parameters   A struct of HTTP URL parameters to send.
	 * @timeout      The default CFHTTP timeout.
	 * @throwOnError Flag to throw exceptions on any error or not, default is true
	 *
	 * @return The response information.
	 */
	private struct function s3Request(
		string method         = "GET",
		string resource       = "",
		any body              = "",
		struct headers        = {},
		struct parameters     = {},
		string filename       = "",
		numeric timeout       = variables.defaultTimeOut,
		boolean parseResponse = true,
		boolean getAsBinary   = "no",
		boolean throwOnError  = variables.throwOnRequestError,
		numeric tryCount      = 1
	){
		var results = {
			"error"          : false,
			"response"       : {},
			"message"        : "",
			"responseheader" : {}
		};
		var param = "";
		var md5   = "";

		// Default Content Type
		if ( NOT structKeyExists( arguments.headers, "content-type" ) ) {
			arguments.headers[ "Content-Type" ] = "";
		}

		// Create Signature
		var signatureData = signatureUtil.generateSignatureData(
			requestMethod  = arguments.method,
			hostName       = variables.URLEndpointHostname,
			requestURI     = arguments.resource,
			requestBody    = arguments.body,
			requestHeaders = arguments.headers,
			requestParams  = arguments.parameters,
			accessKey      = variables.accessKey,
			secretKey      = variables.secretKey,
			regionName     = variables.awsRegion,
			serviceName    = variables.serviceName
		);
		var cfhttpAttributes = {};
		if ( !isNull( server.lucee ) ) {
			// Lucee encodes CFHTTP URLs by default which breaks crap.  Adobe doesn't touch it.  Good job, Adobe.
			// Adobe will, however, fall on the floor sobbing if you include the encodeurl attribute in the code directly as it is a Lucee-only feature.
			cfhttpAttributes[ "encodeurl" ] = false;
		}

		cfhttpAttributes[ "result" ] = "local.HTTPResults";
		if ( len( arguments.filename ) ) {
			// Let the CF engine directly save the file so it can stream large files to disk and not eat up memory
			cfhttpAttributes[ "file" ] = getFileFromPath( arguments.filename );
			cfhttpAttributes[ "path" ] = getDirectoryFromPath( arguments.filename );
			if ( !directoryExists( cfhttpAttributes[ "path" ] ) ) {
				directoryCreate( cfhttpAttributes[ "path" ] );
			}
			if ( !isNull( server.lucee ) && !structKeyExists( server, "boxlang" ) ) {
				// Crummy workaround in Lucee due to lack of compat with Adobe CF.  See...
				// https://luceeserver.atlassian.net/browse/LDEV-3377
				// https://luceeserver.atlassian.net/browse/LDEV-4357
				cfhttpAttributes[ "result" ] = "";
			}
		}

		cfhttp(
			method              = arguments.method,
			url                 = "#variables.URLEndpoint##signatureData.CanonicalURI#",
			charset             = "utf-8",
			redirect            = true,
			timeout             = arguments.timeout,
			getAsBinary         = arguments.getAsBinary,
			useragent           = "ColdFusion-S3SDK",
			attributeCollection = cfhttpAttributes
		) {
			// Amazon Global Headers
			cfhttpparam(
				type  = "header",
				name  = "Date",
				value = signatureData.amzDate
			);

			cfhttpparam(
				type  = "header",
				name  = "Authorization",
				value = signatureData.authorizationHeader
			);

			for ( var headerName in signatureData.requestHeaders ) {
				cfhttpparam(
					type  = "header",
					name  = headerName,
					value = signatureData.requestHeaders[ headerName ]
				);
			}

			for ( var paramName in signatureData.requestParams ) {
				cfhttpparam(
					type    = "URL",
					name    = paramName,
					encoded = false,
					value   = signatureData.requestParams[ paramName ]
				);
			}

			if ( len( arguments.body ) ) {
				cfhttpparam( type = "body", value = arguments.body );
			}
		}

		// Lucee behavior mentioned above regarding file download incompat with Adobe
		// When Lucee direct-downnloads a file, it doesn't return ANY details from the HTTP request :/
		if ( isNull( local.HTTPResults ) || !isStruct( local.HTTPResults ) ) {
			return results;
		}

		// I've seen this variable disappear in Lucee on failed HTTP requests for some reason.
		if ( isNull( HTTPResults.responseHeader.status_code ) ) {
			HTTPResults.responseHeader.status_code = 0;
		}

		// Amazon recommends retrying these requests after a delay
		if (
			listFindNoCase( "500,503,0", HTTPResults.responseHeader.status_code ) && tryCount < variables.retriesOnError
		) {
			log.warn(
				"AWS call #arguments.method# #variables.URLEndpointHostname#/#arguments.resource# returned #HTTPResults.statusCode#.  Retrying (attempt #tryCount#)"
			);
			sleep( 1000 );
			arguments.tryCount++;
			return s3Request( argumentCollection = arguments );
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
		// Ignore redirects and 404s when getting a HEAD request (exists check)
		if (
			len( HTTPResults.errorDetail ) && HTTPResults.errorDetail neq "302 Found" && !(
				arguments.method == "HEAD" && HTTPResults.errorDetail eq "404 Not Found"
			)
		) {
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
			if ( NOT listFindNoCase( "200,404,204,302", HTTPResults.responseHeader.status_code ) ) {
				results.error   = true;
				results.message = arrayToList(
					arrayMap( results.response.error.XmlChildren, function( node ){
						return "#node.XmlName#: #node.XmlText#";
					} ),
					"\n"
				);
			}
		}

		if ( results.error ) {
			log.error(
				"Error making Amazon Rest Call ->Arguments: #arguments.toString()#, ->Encoded Signature=#signatureData.signature#",
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
	private binary function HMAC_SHA1( required string signKey, required string signMessage ){
		var jMsg = javacast( "string", arguments.signMessage ).getBytes( encryptionCharset );
		var jKey = javacast( "string", arguments.signKey ).getBytes( encryptionCharset );
		var key  = createObject( "java", "javax.crypto.spec.SecretKeySpec" ).init( jKey, "HmacSHA1" );
		var mac  = createObject( "java", "javax.crypto.Mac" ).getInstance( key.getAlgorithm() );

		mac.init( key );
		mac.update( jMsg );

		return mac.doFinal();
	}

	/**
	 * @description Generate RSA MD5 hash
	 */
	string function MD5inBase64( required content ){
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
	private function requireBucketName( bucketName ){
		if ( isNull( arguments.bucketName ) || !len( arguments.bucketName ) ) {
			throw(
				"bucketName is required.  Please provide the name of the bucket to access or set a default bucket name in the SDk."
			);
		}
	}


	/**
	 * Helper function to apply grant headers
	 */
	private function applyACLHeaders( struct headers = {}, required any acl ){
		if ( isSimpleValue( arguments.acl ) ) {
			if ( !len( arguments.acl ) ) {
				return headers;
			}
			headers[ "x-amz-acl" ] = arguments.acl;
		} else if ( isStruct( arguments.acl ) ) {
			var types = {
				"FULL_CONTROL" : "x-amz-grant-full-control",
				"WRITE"        : "x-amz-grant-write",
				"WRITE_ACP"    : "x-amz-grant-write-acp",
				"READ"         : "x-amz-grant-read",
				"READ_ACP"     : "x-amz-grant-read-acp"
			};
			for ( var type in types ) {
				if (
					structKeyExists( arguments.acl, type ) && isArray( arguments.acl[ type ] ) && arguments.acl[ type ].len()
				) {
					headers[ types[ type ] ] = arguments.acl[ type ].reduce( ( header, grant ) => {
						if ( grant.keyExists( "ID" ) ) {
							return header.listAppend( "#( len( header ) ? " " : "" )#id=""#grant.ID#""" );
						} else if ( grant.keyExists( "uri" ) ) {
							return header.listAppend( "#( len( header ) ? " " : "" )#uri=""#grant.uri#""" );
						} else if ( grant.keyExists( "emailAddress" ) ) {
							return header.listAppend(
								"#( len( header ) ? " " : "" )#emailAddress=""#grant.emailAddress#"""
							);
						} else {
							return header;
						}
					}, "" );
					if ( !len( headers[ types[ type ] ] ) ) {
						headers.delete( types[ type ] );
					}
				}
			}
		} else {
			throw( "Invalid acl argument. Must be string or struct." );
		}
		return headers;
	}

	function applyEncryptionHeaders( headers, args ){
		args.encryptionAlgorithm = args.encryptionAlgorithm ?: "";
		if ( len( args.encryptionKey ) ) {
			if ( len( args.encryptionAlgorithm ) ) {
				headers[ "x-amz-server-side-encryption-customer-algorithm" ] = args.encryptionAlgorithm;
			} else {
				headers[ "x-amz-server-side-encryption-customer-algorithm" ] = "AES256";
			}
			headers[ "x-amz-server-side-encryption-customer-key" ]     = args.encryptionKey;
			// Convert base64 key to bytes, and then MD5 hash with base64 output encoding instead of hex
			headers[ "x-amz-server-side-encryption-customer-key-MD5" ] = toBase64(
				binaryDecode( hash( toBinary( args.encryptionKey ), "MD5" ), "hex" )
			);
		} else if ( len( args.encryptionAlgorithm ) ) {
			headers[ "x-amz-server-side-encryption" ] = args.encryptionAlgorithm;
		}
		args.encryptionKeySource       = args.encryptionKeySource ?: "";
		args.encryptionAlgorithmSource = args.encryptionAlgorithmSource ?: "";
		if ( len( args.encryptionKeySource ) ) {
			if ( len( args.encryptionAlgorithmSource ) ) {
				headers[ "x-amz-copy-source-server-side-encryption-customer-algorithm" ] = args.encryptionAlgorithmSource;
			} else {
				headers[ "x-amz-copy-source-server-side-encryption-customer-algorithm" ] = "AES256";
			}
			headers[ "x-amz-copy-source-server-side-encryption-customer-key" ]     = args.encryptionKeySource;
			// Convert base64 key to bytes, and then MD5 hash with base64 output encoding instead of hex
			headers[ "x-amz-copy-source-server-side-encryption-customer-key-MD5" ] = toBase64(
				binaryDecode( hash( toBinary( args.encryptionKeySource ), "MD5" ), "hex" )
			);
		}

		return headers;
	}

	/**
	 * Determines mime type from the file extension
	 *
	 * @filePath The path to the file stored in S3.
	 *
	 * @return string
	 */
	string function getFileMimeType( required string filePath ){
		var contentType = "binary/octet-stream";
		if ( len( arguments.filePath ) ) {
			var ext = listLast( arguments.filePath, "." );
			if ( structKeyExists( variables.mimeTypes, ext ) ) {
				contentType = variables.mimeTypes[ ext ];
			} else {
				try {
					contentType = getPageContext().getServletContext().getMimeType( arguments.filePath );
				} catch ( any cfcatch ) {
				}
				if ( !isDefined( "contentType" ) ) {
					contentType = "binary/octet-stream";
				}
			}
		}
		return contentType;
	}


	/**
	 * Creates the s3 key name based on the format (path or virtual) from the bucket name and the object key
	 *
	 * @url        The key for the file in question
	 * @bucketName The name of the bucket to use. Not needed if the urlStyle is `virtual`
	 **/
	function buildKeyName( required string uri, string bucketName = "" ){
		return variables.urlStyle == "path" ? arguments.bucketName & ( arguments.bucketName.len() ? "/" : "" ) & arguments.uri : arguments.uri;
	}

}

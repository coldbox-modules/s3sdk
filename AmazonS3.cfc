<!-----------------------------------------------------------------------
********************************************************************************
Copyright 2005-2007 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
********************************************************************************

Amazon S3 REST Wrapper

Written by Joe Danziger (joe@ajaxcf.com) with much help from
dorioo on the Amazon S3 Forums.  See the readme for more
details on usage and methods.
Thanks to Steve Hicks for the bucket ACL updates.
Thanks to Carlos Gallupa for the EU storage location updates.
Thanks to Joel Greutman for the fix on the getObject link.
Thanks to Jerad Sloan for the Cache Control headers.

Version 1.7 - Released: December 15, 2008
Version 2.0 - Luis Majano updated for ColdBox and extra features.

You will have to create some settings in your ColdBox configuration file:

s3_accessKey : The Amazon access key
s3_secretKey : The Amazon secret key
s3_encryption_charset : encryptyion charset (Optional, defaults to utf-8)
s3_ssl : Whether to use ssl on all cals or not (Optional, defaults to false)


----------------------------------------------------------------------->
<cfcomponent hint="Amazon S3 REST Wrapper" output="false" accessors=true singleton>

	<!--- DI --->
	<cfproperty name="log" inject="logbox:logger:{this}">

	<!--- Properties --->
	<cfproperty name="accessKey">
	<cfproperty name="secretKey">
	<cfproperty name="encryption_charset">
	<cfproperty name="ssl">
	<cfproperty name="URLEndPoint">

	<cfscript>
		// STATIC Contsants
		this.ACL_PRIVATE 			= "private";
		this.ACL_PUBLIC_READ 		= "public-read";
		this.ACL_PUBLIC_READ_WRITE 	= "public-read-write";
		this.ACL_AUTH_READ 			= "authenticated-read";
	</cfscript>

	<cffunction name="init" access="public" returnType="AmazonS3" output="false" hint="Constructor">
		<cfargument name="accessKey" 			required="true">
		<cfargument name="secretKey" 			required="true">
		<cfargument name="encryption_charset" 	required="false" default="utf-8">
		<cfargument name="ssl" 					required="false" default="false">
		<cfscript>

			for( var thiskey in arguments ){
				variables[ thisKey ] = arguments[ thisKey ];
			}

			if( arguments.ssl ){
				variables.URLEndPoint = "https://s3.amazonaws.com";
			} else{
				variables.URLEndPoint = "http://s3.amazonaws.com";
			}

			variables.sv4Util = new Sv4Util(
				accessKeyId = variables.accessKey,
				secretAccessKey = variables.secretKey,
				defaultRegionName = "us-east-1",
				defaultServiceName = "s3"
			);

			return this;
		</cfscript>
	</cffunction>

	<!--- setAuth --->
    <cffunction name="setAuth" output="false" access="public" returntype="void" hint="Set the Amazon credentials">
    	<cfargument name="accessKey" type="string" required="true" default="" hint="The amazon access key"/>
		<cfargument name="secretKey" type="string" required="true" default="" hint="The amazon secret key"/>
		<cfscript>
			variables.accessKey = arguments.accessKey;
			variables.secretKey = arguments.secretKey;
		</cfscript>
    </cffunction>

	<!--- setSSL --->
    <cffunction name="setSSL" output="false" access="public" returntype="void" hint="Set SSL flag and alter the internal URL End point pointer">
    	<cfargument name="useSSL" type="boolean" required="false" default="true" hint="Set to true or false"/>
    	<cfscript>
			if( arguments.useSSL ){
				variables.URLEndPoint = "https://s3.amazonaws.com";
			} else{
				variables.URLEndPoint = "http://s3.amazonaws.com";
			}
		</cfscript>
    </cffunction>

<!------------------------------------------- PUBLIC ------------------------------------------>

	<!--- Create Signature --->
	<cffunction name="createSignature" returntype="any" access="public" output="false" hint="Create request signature according to AWS standards">
		<cfargument name="stringToSign" type="any" required="true" />
		<cfscript>
			var fixedData = replace( arguments.stringToSign, "\n", "#chr(10)#", "all" );

			return toBase64( HMAC_SHA1( variables.secretKey, fixedData ) );
		</cfscript>
	</cffunction>

	<!--- Create Signature v4 --->
	<cffunction name="createSignatureV4" returntype="any" access="public" output="false" hint="Create request signature according to AWS v4 standards">
		<cfargument name="date" type="any" required="true" />
		<cfargument name="region" type="any" required="true" />
		<cfargument name="headers" type="struct" required="false" default="#structNew()#" />
		<cfscript>
			return "AWS4-HMAC-SHA256 " & arrayToList( [
				"Credential=#createCredential( date, region )#",
				"SignedHeaders=#createSignedHeaders( headers )#",
				"Signature=#generateSignature()#"
			] );
		</cfscript>
	</cffunction>

	<!--- Create Credential --->
	<cffunction name="createCredential" returntype="any" access="public" output="false" hint="Create credential according to AWS v4 standards">
		<cfargument name="date" type="any" required="true" />
		<cfargument name="region" type="any" required="true" />
		<cfscript>
			return arrayToList( [
				#variables.accessKey#,
				#dateFormat( arguments.date, "YYYYMMDD" )#,
				#arguments.region#,
				"s3",
				"aws4_request"
			], "/" );
		</cfscript>
	</cffunction>

	<!--- Create Signed Headers --->
	<cffunction name="createSignedHeaders" returntype="any" access="public" output="false" hint="Create signed headers according to AWS v4 standards">
		<cfargument name="headers" type="struct" required="false" default="#structNew()#" />
		<cfscript>
			var lowercaseHeaders = arrayMap( structKeyArray( headers ), function( header ) {
				return lcase( header );
			} );
			arraySort( lowercaseHeaders, "text" );
			return arrayToList( lowercaseHeaders, ";" );
		</cfscript>
	</cffunction>

	<!--- Generate Signature --->
	<cffunction name="generateSignature" returntype="any" access="public" output="false" hint="Generate the signature portion of the authorization according to AWS v4 standards">
		<cfargument name="date" type="any" required="true" />
		<cfargument name="region" type="any" required="true" />
		<cfargument name="httpMethod" type="string" required="true" />
		<cfargument name="uri" type="string" required="true" />
		<cfargument name="queryString" type="string" required="false" default="" />
		<cfargument name="headers" type="struct" required="false" default="#structNew()#" />
		<cfargument name="payload" type="any" required="false" default="" />
		<cfscript>
			return toBase64( HMAC_SHA1(
				generateSigningKey( date, region ),
				generateStringToSign(
					httpMethod,
					generateCanonicalURI( uri ),
					generateCanonicalQueryString( queryString ),
					generateCanonicalHeaders( headers ),
					createSignedHeaders( headers ),
					generateHashedPayload( payload )
				)
			) );
		</cfscript>
	</cffunction>

	<!--- Generate Signing Key --->
	<cffunction name="generateSigningKey" returntype="any" access="public" output="false" hint="Generate the signature portion of the authorization according to AWS v4 standards">
		<cfargument name="date" type="any" required="true" />
		<cfargument name="region" type="any" required="true" />
		<cfscript>
			var dateKey = HMAC_SHA1( "AWS4 #variables.secretKey#", dateFormat( date, "yyyymmdd" ) );
			var dateRegionKey = HMAC_SHA1( dateKey, region );
			var dateRegionServiceKey = HMAC_SHA1( dateRegionKey, "s3" );
			return HMAC_SHA1( generateCanonicalRequest(

			), "aws4_request" );
		</cfscript>
	</cffunction>

	<cffunction name="generateStringToSign" returntype="any" access="public" output="false" hint="Generate the signature portion of the authorization according to AWS v4 standards">
		<cfargument name="date" type="any" required="true" />
		<cfargument name="region" type="any" required="true" />
		<cfargument name="canonicalRequest" type="any" required="true" />
		<cfscript>
			var utcDate = dateConvert( "local2Utc", date );
			return arrayToList( [
				"AWS4-HMAC-SHA256",
				dateTimeFormat( utcDate, "yyyymmdd" ) & "T" & dateTimeFormat( utcDate, "hhnnss" ) & "Z",
				"#dateFormat( utdDate, "yyyymmdd" )#/#region#/s3/aws4_request",
				toBase64( lcase( hash( canonicalRequest, "SHA-256" ) ) )
			], "#chr(10)#" );
		</cfscript>
	</cffunction>

	<!--- Get All Buckets --->
	<cffunction name="listBuckets" access="public" output="false" returntype="array" hint="List all available buckets.">
		<cfscript>
		// Invoke call
		var results = S3Request();

		// error
		if( results.error ){
			throw( message="Error making Amazon REST Call", detail=results.message );
		}
		// Parse out buckets
		var foundBuckets 	= [];
		var bucketsXML 		= xmlSearch( results.response, "//*[local-name()='Bucket']" );
		for( var x=1; x lte arrayLen( bucketsXML ); x++ ){
			var thisBucket = {
				name = trim( bucketsXML[ x ].name.xmlText ),
				creationDate = trim( bucketsXML[ x ].creationDate.xmlText )
			};
			arrayAppend( foundBuckets, thisBucket );
		}
		return foundBuckets;
		</cfscript>
	</cffunction>

	<!--- getBucketLocation --->
	<cffunction name="getBucketLocation" access="public" output="false" returntype="string" hint="Get bucket location.">
		<cfargument name="bucketName" type="string" required="true" hint="The bucket name to get info on">
		<cfscript>
		// Invoke call
		var results = S3Request( resource=arguments.bucketname & "?location" );

		// error
		if( results.error ){
			throw( message="Error making Amazon REST Call", detail=results.message );
		}

		// Parse out EU buckets
		if( len( results.response.LocationConstraint.XMLText ) ){
			return results.response.LocationConstraint.XMLText;
		}

		return "US";
		</cfscript>
	</cffunction>

	<!--- getBucketVersionStatus --->
	<cffunction name="getBucketVersionStatus" access="public" output="false" returntype="String" hint="Get bucket location.">
		<cfargument name="bucketName" type="string" required="true" hint="The bucket name to get info on">
		<cfscript>
		// Invoke call
		var results = S3Request(resource=arguments.bucketname & "?versioning");

		// error
		if( results.error ){
			throw( message="Error making Amazon REST Call", detail=results.message );
		}

		var status = xmlSearch( results.response, "//*[local-name()='VersioningConfiguration']//*[local-name()='Status']/*[1]" );

		// Parse out Version Configuration
		if( arrayLen( status ) gt 0 ){
			return status[ 1 ].xmlText;
		}

		return "";
		</cfscript>
	</cffunction>

	<!---setBucketVersion--->
	<cffunction name="setBucketVersionStatus" access="public" output="false" returntype="boolean" hint="set bucket versioning">
		<cfargument name="bucketName"		type="string"   required="true" hint="The name of the bucket to create">
		<cfargument name="version"		    type="boolean"  required="false"  default="true"   hint="the version status enabled/disabled.">
		<cfscript>
			var constraintXML 	= "";
			var headers 		= {};
			var amzHeaders 		= {};

			// Headers init
			headers[ "content-type" ] = "text/plain";

			if( arguments.version eq true ){
				headers[ "?versioning" ] = "";
				constraintXML = '<VersioningConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Status>Enabled</Status></VersioningConfiguration>';
			}

			// Invoke call
			var results = S3Request(
				method 		= "PUT",
				resource	= arguments.bucketName,
				body 		= constraintXML,
				headers 	= headers,
				amzHeaders	= amzHeaders
			);

			// error
			if( results.error ){
				throw( message="Error making Amazon REST Call", detail=results.message );
			}

			if( results.responseheader.status_code eq "200"){
				return true;
			}

			return false;
		</cfscript>
	</cffunction>

	<!--- Get getAcessControlPolicy --->
	<cffunction name="getAcessControlPolicy" access="public" output="false" returntype="array" hint="Get's a bucket or object's ACL policy'">
		<cfargument name="bucketName" type="string" required="true" hint="The bucket name to list">
		<cfargument name="uri" 		  type="string" required="false" default="" hint="The object URI to get the policy">
		<cfscript>
			var resource = arguments.bucketName;

			// incoming URI
			if( len( arguments.uri ) ){
				resource = resource & "\" & arguments.uri;
			}

			// Invoke call
			var results = S3Request( resource=resource & "?acl" );

			// error
			if( results.error ){
				throw( message="Error making Amazon REST Call", detail=results.message );
			}

			// Parse Grants
			var grantsXML 	= xmlSearch( results.response, "//*[local-name()='Grant']" );
			var foundGrants = [];
			for( var x=1; x lte arrayLen( grantsXML ); x++ ){
				var thisGrant = {
					type 		= grantsXML[ x ].grantee.XMLAttributes[ "xsi:type" ],
					uri 		= "",
					displayName = "",
					permission	= grantsXML[ x ].permission.XMLText
				};
				if( thisGrant.type eq "Group" ){
					thisGrant.uri = grantsXML[ x ].grantee.uri.xmlText;
				}
				else{
					thisGrant.uri = grantsXML[ x ].grantee.displayName.xmlText;
				}
				arrayAppend( foundGrants, thisGrant );
			}

			return foundGrants;
		</cfscript>
	</cffunction>

	<!--- Get Bucket --->
	<cffunction name="getBucket" access="public" output="false" returntype="array" hint="Lists information about the objects of a bucket">
		<cfargument name="bucketName" type="string" required="true" hint="The bucket name to list">
		<cfargument name="prefix" 	  type="string" required="false" default="" hint="Limits the response to keys which begin with the indicated prefix.">
		<cfargument name="marker" 	  type="string" required="false" default="" hint="Indicates where in the bucket to begin listing.">
		<cfargument name="maxKeys" 	  type="string" required="false" default="" hint="The maximum number of keys you'd like to see in the response body">
		<cfargument name="delimiter"  type="string" required="false" default="" hint="The delimiter to use in the keys">
		<cfscript>
			var headers 		= [];
			var parameters 		= {};

			//HTTP parameters
			if( len(arguments.prefix) ){
				parameters[ "prefix" ] = arguments.prefix;
			}
			if( len(arguments.marker) ){
				parameters[ "marker" ] = arguments.marker;
			}
			if( isNumeric(arguments.maxKeys) ){
				parameters[ "max-keys" ] = arguments.maxKeys;
			}
			if( len(arguments.delimiter) ){
				parameters[ "delimiter" ] = arguments.delimiter;
			}

			// Invoke call
			var results = S3Request(
				resource 	= arguments.bucketName,
				parameters 	= parameters
			);
			// error
			if( results.error ){
				throw( message="Error making Amazon REST Call", detail=results.message );
			}

			// Parse results
			var contentsXML 	= xmlSearch( results.response, "//*[local-name()='Contents']" );
			var foundContents 	= [];
			for( var x=1; x lte arrayLen( contentsXML ); x++ ){
				var thisContent = {
					key				= trim( contentsXML[ x ].key.xmlText ),
					lastModified	= trim( contentsXML[ x ].lastModified.xmlText ),
					size			= trim( contentsXML[ x ].Size.xmlText ),
					eTag 			= trim( contentsXML[ x ].etag.xmlText ),
					isDirectory 	= ( findNoCase( "_$folder$", contentsXML[ x ].key.xmlText ) ? true : false )
				};
				arrayAppend( foundContents, thisContent );
			}

			// parse directories
			var foldersXML 	= xmlSearch( results.response, "//*[local-name()='CommonPrefixes']" );
			for( var x=1; x lte arrayLen( foldersXML ); x++ ){
				var thisContent = {
					key				= reReplaceNoCase( trim( foldersXML[ x ].prefix.xmlText ), "\/$", "" ),
					lastModified	= '',
					size			= '',
					eTag 			= '',
					isDirectory 	= true
				};
				arrayAppend( foundContents, thisContent );
			}

			return foundContents;
		</cfscript>
	</cffunction>

	<!--- Put Bucket --->
	<cffunction name="putBucket" access="public" output="false" returntype="boolean" hint="Creates a bucket">
		<cfargument name="bucketName"		type="string" required="true" hint="The name of the bucket to create">
		<cfargument name="acl" 				type="string" required="false" default="#this.ACL_PUBLIC_READ#" hint="The ACL permissions to apply. Use the this scope constants for ease of use.">
		<cfargument name="location"  		type="string" required="false" default="USA" hint="The location of the storage, defaults to USA or EU">
		<cfscript>
		var constraintXML 	= "";
		var headers 		= {};
		var amzHeaders 		= {};

		// Man cf8 really did implicit structures NASTY!!
		amzHeaders[ "x-amz-acl" ] = arguments.acl;

		// storage location?
		if( arguments.location eq "EU" ){
			constraintXML = "<CreateBucketConfiguration><LocationConstraint>EU</LocationConstraint></CreateBucketConfiguration>";
		}

		// Headers
		headers[ "content-type" ] = "text/xml";

		// Invoke call
		var results = S3Request(
			method 		= "PUT",
			resource 	= arguments.bucketName,
			body 		= constraintXML,
			headers 	= headers,
			amzHeaders 	= amzHeaders
		);

		// error
		if( results.error ){
			throw( message="Error making Amazon REST Call", detail=results.message );
		}

		if( results.responseheader.status_code eq "200"){
			return true;
		}

		return false;
		</cfscript>
	</cffunction>

	<!--- Delete a Bucket --->
	<cffunction name="hasBucket" access="public" output="false" returntype="boolean" hint="Checks for the existance of a bucket.">
		<cfargument name="bucketName" type="string" required="yes">
		<cfscript>
			return ! arrayIsEmpty( arrayFilter( listBuckets(), function( bucket ) {
				return bucket.name == bucketName;
			} ) );
		</cfscript>
	</cffunction>

	<!--- Delete a Bucket --->
	<cffunction name="deleteBucket" access="public" output="false" returntype="boolean" hint="Deletes a bucket.">
		<cfargument name="bucketName" type="string" required="true">
		<cfargument name="force" type="boolean" default="false" required="false">
		<cfscript>
			if ( force ) {
				var bucketContents = getBucket( bucketName );
				for ( var item in bucketContents ) {
					deleteObject( bucketName, item.key );
				}
			}

			// Invoke call
			var results = S3Request(
				method 	 = "DELETE",
				resource = arguments.bucketName
			);

			// error
			if( results.error ){
				throw( message="Error making Amazon REST Call", detail=results.message );
			}

			if( results.responseheader.status_code eq "204"){ return true; }

			return false;
		</cfscript>
	</cffunction>

	<!--- Put an object from a local file --->
	<cffunction name="putObjectFile" access="public" output="false" returntype="string" hint="Puts an object from a local file into a bucket and returns the etag">
		<cfargument name="bucketName" 	 type="string"  required="true"  hint="The bucket to store in">
		<cfargument name="filepath" 	 type="string"  required="true"  hint="The absolute file path to read in binary and upload">
		<cfargument name="uri" 			 type="string"  required="false" default=""  hint="The destination uri key to use when saving the object, if not used, the name of the file will be used."/>
		<cfargument name="contentType" 	 type="string"  required="false" default="binary/octet-stream" hint="The file content type, defaults to: binary/octet-stream">
		<cfargument name="HTTPTimeout" 	 type="numeric" required="false" default="300" hint="The HTTP timeout to use">
		<cfargument name="cacheControl"  type="string"  required="false" default="no-store, no-cache, must-revalidate" hint="The caching header to send. Defaults to no caching. Example: public,max-age=864000  (10days). For more info look here: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html##sec14.9">
		<cfargument name="expires" 		 type="string"  required="false" default="" hint="Sets the expiration header of the object in days."/>
		<cfargument name="acl" 			 type="string"  required="false" default="#this.ACL_PUBLIC_READ#" hint="The default Amazon security access policy">
		<cfargument name="metaHeaders" 	 type="struct"  required="false" default="#structNew()#" hint="Add additonal metadata headers to the file by passing a struct of name-value pairs"/>
		<cfscript>
			// Read the binary file
			arguments.data = fileReadBinary( arguments.filepath );

			// Default filename
			if( NOT len( arguments.uri ) ){
				arguments.uri = getFileFromPath( arguments.filePath );
			}

			//Encode the filepath
			arguments.uri = urlEncodedFormat( arguments.uri );

			// Send to putObject
			return putObject( argumentCollection=arguments );
		</cfscript>
	</cffunction>

	<!--- Put a folder --->
	<cffunction name="putObjectFolder" access="public" output="false" returntype="string" hint="Puts an object from a local file into a bucket and returns the etag">
		<cfargument name="bucketName" 	 type="string"  required="true"  hint="The bucket to store in">
		<cfargument name="uri" 			 type="string"  required="true" default=""  hint="The destination uri key to use when saving the object, if not used, the name of the file will be used."/>
		<cfargument name="contentType" 	 type="string"  required="false" default="binary/octet-stream" hint="The file content type, defaults to: binary/octet-stream">
		<cfargument name="HTTPTimeout" 	 type="numeric" required="false" default="300" hint="The HTTP timeout to use">
		<cfargument name="cacheControl"  type="string"  required="false" default="no-store, no-cache, must-revalidate" hint="The caching header to send. Defaults to no caching. Example: public,max-age=864000  (10days). For more info look here: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html##sec14.9">
		<cfargument name="expires" 		 type="string"  required="false" default="" hint="Sets the expiration header of the object in days."/>
		<cfargument name="acl" 			 type="string"  required="false" default="#this.ACL_PUBLIC_READ#" hint="The default Amazon security access policy">
		<cfargument name="metaHeaders" 	 type="struct"  required="false" default="#structNew()#" hint="Add additonal metadata headers to the file by passing a struct of name-value pairs"/>
		<cfscript>
			// Read the binary file
			arguments.data = "";

			// Send to putObject
			return putObject( argumentCollection=arguments );
		</cfscript>
	</cffunction>

	<!--- createMetaHeaders --->
    <cffunction name="createMetaHeaders" output="false" access="public" returntype="struct" hint="Create a structure of amazon enabled metadata headers">
    	<cfargument name="metaHeaders" 	 type="struct"  required="false" default="#structNew()#" hint="Add additonal metadata headers to the file by passing a struct of name-value pairs"/>
		<cfscript>
			var md = {};
			for( var key in arguments.metaHeaders ){
				md[ "x-amz-meta-" & key ] = arguments.metaHeaders[ key ];
			}
			return md;
		</cfscript>
    </cffunction>

	<!--- Put An Object --->
	<cffunction name="putObject" access="public" output="false" returntype="string" hint="Puts an object into a bucket and returns the etag">
		<cfargument name="bucketName" 	 type="string"  required="true"  hint="The bucket to store in">
		<cfargument name="uri" 			 type="string"  required="true"  hint="The destination uri key to use when saving the object"/>
		<cfargument name="data" 		 type="any" 	required="false" default="" hint="The content to save as data, this can be binary,string or anything you like."/>
		<cfargument name="contentDisposition" type="string" required="false" default="" hint="The content-disposition header to use when downloading file"/>
		<cfargument name="contentType" 	 type="string"  required="false" default="text/plain" hint="The file/data content type, defaults to text/plain. For plain binary use: binary/octet-stream">
		<cfargument name="HTTPTimeout" 	 type="numeric" required="false" default="300" hint="The HTTP timeout to use">
		<cfargument name="cacheControl"  type="string"  required="false" default="no-store, no-cache, must-revalidate" hint="The caching header to send. Defaults to no caching. Example: public,max-age=864000  (10days). For more info look here: http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html##sec14.9">
		<cfargument name="expires" 		 type="string"  required="false" default="" hint="Sets the expiration header of the object in days."/>
		<cfargument name="acl" 			 type="string"  required="false" default="#this.ACL_PUBLIC_READ#" hint="The default Amazon security access policy">
		<cfargument name="metaHeaders" 	 type="struct"  required="false" default="#structNew()#" hint="Add additonal metadata headers to the file by passing a struct of name-value pairs"/>
		<cfscript>
			var headers 	= {};
			var amzHeaders 	= createMetaHeaders( arguments.metaHeaders );

			// Add security to amzHeaders
			amzHeaders[ "x-amz-acl" ] = arguments.acl;

			// Add Global Put Headers
			headers[ "content-type" ]  = arguments.contentType;
			headers[ "cache-control" ] = arguments.cacheControl;

			// Content Disposition
			if( len( arguments.contentDisposition ) ){
				headers[ "content-disposition" ] = arguments.contentDisposition;
			}

			// Expiration header if set
			if( isNumeric( arguments.expires ) ){
				headers[ "expires" ] = "#DateFormat( now() + arguments.expires, 'ddd, dd mmm yyyy' )# #TimeFormat( now(), 'H:MM:SS' )# GMT";
			}

			// Invoke call
			results = S3Request(
				method 			= "PUT",
				resource 		= arguments.bucketName & "/" & arguments.uri,
				body 			= arguments.data,
				timeout 		= arguments.HTTPTimeout,
				headers 		= headers,
				amzHeaders 		= amzHeaders
			);

			// error
			if( results.error ){
				throw( message="Error making Amazon REST Call", detail=results.message );
			}

			// Get results
			if( results.responseHeader.status_code eq "200" ){
				return results.responseHeader.etag;
			}

			return "";
		</cfscript>
	</cffunction>

	<!--- Get Object Info--->
	<cffunction name="getObjectInfo" access="public" output="false" returntype="struct" hint="Get an object's metadata information">
		<cfargument name="bucketName" 	type="string" required="yes" hint="The bucket the object resides in">
		<cfargument name="uri"			type="string" required="yes" hint="The object URI to retrieve info from">
		<cfscript>
			var metadata = {};

			// Invoke call
			var results = S3Request( method="HEAD", resource=arguments.bucketName & "/" & arguments.uri );

			// error
			if( results.error ){
				throw( message="Error making Amazon REST Call", detail=results.message );
			}

			// Get metadata
			for( var key in results.responseHeader ){
				metadata[ key ] = results.responseHeader[ key ];
			}

			return metadata;
		</cfscript>
	</cffunction>

	<!--- Get Secure Link To an Object--->
	<cffunction name="getAuthenticatedURL" access="public" output="false" returntype="string" hint="Returns a query string authenticated URL to an object in S3.">
		<cfargument name="bucketName" 		type="string" required="yes" hint="The bucket the object resides in">
		<cfargument name="uri"				type="string" required="yes" hint="The uri to the object to create a link for">
		<cfargument name="minutesValid" 	type="string" required="false" default="60" hint="The minutes the link is valid for. Defaults to 60 minutes">
		<cfargument name="virtualHostStyle" type="boolean" required="false" default="false" hint="Whether to use virtual bucket style or path style. Defaults to virtual"/>
		<cfargument name="useSSL" 			type="boolean" required="false" default="false" hint="Use SSL on http call"/>
		<cfscript>
			var epochTime 	= DateDiff( "s", DateConvert( "utc2Local", "January 1 1970 00:00" ), now()) + ( arguments.minutesValid * 60 );
			var HTTPPrefix 	= "http://";

			arguments.uri = urlEncodedFormat( arguments.uri );
			arguments.uri = replacenocase( arguments.uri,"%2E",".","all" );
			arguments.uri = replacenocase( arguments.uri,"%2D","-","all" );
			arguments.uri = replacenocase( arguments.uri,"%5F","_","all" );

			var stringToSign = "GET\n\n\n#epochTime#\n/#arguments.bucketName#/#arguments.uri#";

			// Sign the request
			var signature 	= createSignature( stringToSign );
			signature 		= urlEncodedFormat( signature );
			//signature = replace(signature,"%3D","%","all");

			//securedLink = "#arguments.uri#?AWSAccessKeyId=#variables.accessKey#&Expires=#epochTime#&Signature=#replace(signature,"%3D","%","all")#";
			var securedLink = "#arguments.uri#?AWSAccessKeyId=#variables.accessKey#&Expires=#epochTime#&Signature=#signature#";

			// Log it
			log.debug( "String to sign: #stringToSign# . Signature: #signature#" );

			// SSL?
			if( arguments.useSSL ){
				HTTPPrefix = "https://";
			}

			// VH style Link
			if( arguments.virtualHostSTyle ){
				return "#HTTPPrefix##arguments.bucketName#.s3.amazonaws.com/#securedLink#";
			}

			// Path Style Link
			return "#HTTPPrefix#s3.amazonaws.com/#arguments.bucketName#/#securedLink#";
		</cfscript>
	</cffunction>

	<!--- Delete Object --->
	<cffunction name="deleteObject" access="public" output="false" returntype="boolean" hint="Deletes an object.">
		<cfargument name="bucketName" type="string" required="true" hint="The bucket name">
		<cfargument name="uri"   	  type="string" required="true" hint="The file object uri to remove">
		<cfscript>
			arguments.uri = urlEncodedFormat( urlDecode( arguments.uri ) );
			arguments.uri = replacenocase( arguments.uri, "%2E", ".", "all" );
			arguments.uri = replacenocase( arguments.uri, "%2D", "-", "all" );
			arguments.uri = replacenocase( arguments.uri, "%5F", "_", "all" );

			// Invoke call
			var results = S3Request( method="DELETE", resource=arguments.bucketName & "/" & arguments.uri );

			// error
			if( results.error ){
				throw( message="Error making Amazon REST Call", detail=results.message );
			}

			if( results.responseheader.status_code eq "204"){ return true; }

			return false;
		</cfscript>
	</cffunction>

	<!--- Copy Object --->
	<cffunction name="copyObject" access="public" output="false" returntype="boolean" hint="Copies an object. False if the same object or error copying object.">
		<cfargument name="fromBucket" 	 type="string"  required="true" hint="The source bucket">
		<cfargument name="fromURI" 		 type="string"  required="true" hint="The source uri">
		<cfargument name="toBucket" 	 type="string"  required="true" hint="The destination bucket">
		<cfargument name="toURI"		 type="string"  required="true" hint="The destination uri">
		<cfargument name="acl" 			 type="string"  required="false" default="#this.ACL_PRIVATE#" hint="The default Amazon security access policy">
		<cfargument name="metaHeaders" 	 type="struct"  required="false" default="#structNew()#" hint="Replace metadata headers to the file by passing a struct of name-value pairs"/>
		<cfscript>
			var headers 	= {};
			var amzHeaders 	= createMetaHeaders( arguments.metaHeaders );

			// Copy metaHeaders or replace?
			if( not structIsEmpty( arguments.metaHeaders ) ){
				amzHeaders[ "x-amz-metadata-directive" ] = "REPLACE";
			}

			// amz copying headers
			amzHeaders[ "x-amz-copy-source" ] 	= "/#arguments.fromBucket#/#arguments.fromURI#";
			amzHeaders[ "x-amz-acl" ] 			= arguments.acl;

			// Headers
			headers[ "Content-Length" ] = 0;

			// Invoke call
			var results = S3Request(
				method 		= "PUT",
				resource 	= arguments.toBucket & "/" & arguments.toURI,
				metaHeaders = metaHeaders,
				headers 	= headers,
				amzHeaders 	= amzHeaders
			);

			// error
			if( results.error ){
				throw( message="Error making Amazon REST Call", detail=results.message );
			}

			if( results.responseheader.status_code eq "204"){ return true; }

			return false;
		</cfscript>
	</cffunction>

	<!--- Rename Object --->
	<cffunction name="renameObject" access="public" output="false" returntype="boolean" hint="Renames an object by copying then deleting original.">
		<cfargument name="oldBucketName" type="string" required="yes">
		<cfargument name="oldFileKey" type="string" required="yes">
		<cfargument name="newBucketName" type="string" required="yes">
		<cfargument name="newFileKey" type="string" required="yes">

		<cfif compare( arguments.oldBucketName,arguments.newBucketName ) or compare( arguments.oldFileKey, arguments.newFileKey )>
			<cfset copyObject( arguments.oldBucketName, arguments.oldFileKey, arguments.newBucketName, arguments.newFileKey )>
			<cfset deleteObject( arguments.oldBucketName, arguments.oldFileKey )>
			<cfreturn true>
		<cfelse>
			<cfreturn false>
		</cfif>
	</cffunction>

<!------------------------------------------- PRIVATE ------------------------------------------>

	<!--- S3Request --->
    <cffunction name="S3Request" output="false" access="private" returntype="struct" hint="Invoke an Amazon REST Call">
    	<cfargument name="method" 			type="string" 	required="false" default="GET" hint="The HTTP method to invoke"/>
		<cfargument name="resource" 		type="string" 	required="false" default="" hint="The resource to hit in the amazon s3 service."/>
		<cfargument name="body" 			type="any" 		required="false" default="" hint="The body content of the request if passed."/>
		<cfargument name="headers" 			type="struct" 	required="false" default="#structNew()#" hint="An struct of HTTP headers to send"/>
		<cfargument name="amzHeaders" 		type="struct" 	required="false" default="#structNew()#" hint="An struct of amz header name-value pairs to send"/>
		<cfargument name="parameters"		type="struct" 	required="false" default="#structNew()#" hint="An struct of HTTP URL parameters to send in the request"/>
		<cfargument name="timeout" 			type="numeric" 	required="false" default="20" hint="The default call timeout"/>
		<cfscript>
			var results = {
				error 			= false,
				response 		= {},
				message 		= "",
				responseheader 	= {}
			};
			var HTTPResults = "";
			var param = "";
			var md5 = "";
			var amz = "";
			var sortedAMZ = listToArray( listSort( structKeyList( arguments.amzHeaders ), "textnocase" ) );

			// Default Content Type
			if( NOT structKeyExists( arguments.headers, "content-type" ) ){
				arguments.headers[ "content-type" ] = "";
			}

			// Prepare amz headers in sorted order
			for(var x=1; x lte ArrayLen( sortedAMZ ); x++){
				// Create amz signature string
				arguments.headers[ sortedAMZ[ x ]] = arguments.amzHeaders[sortedAMZ[ x ]];
				amz = amz & "\n" & sortedAMZ[ x ] & ":" & arguments.amzHeaders[sortedAMZ[ x ]];
			}

			// Create Signature
			var signatureData = sv4Util.generateSignatureData(
				requestMethod = arguments.method,
				hostName = "s3.amazonaws.com",
				requestURI = arguments.resource,
				requestBody = arguments.body,
				requestHeaders = arguments.headers,
				requestParams = arguments.parameters
			);
		</cfscript>

		<!--- REST CAll --->
		<cfhttp method="#arguments.method#"
				url="#variables.URLEndPoint#/#arguments.resource#"
				charset="utf-8"
				result="HTTPResults"
				timeout="#arguments.timeout#">

			<!--- Amazon Global Headers  --->
			<cfhttpparam type="header" name="Date" value="#signatureData.amzDate#">
			<cfhttpparam type="header" name="Authorization" value="#signatureData.authorizationHeader#">

			<!--- Headers --->
			<cfloop collection="#signatureData.requestHeaders#" item="param">
				<cfhttpparam type="header" name="#param#" value="#signatureData.requestHeaders[param]#" >
			</cfloop>

			<!--- URL Parameters: encoded automatically by CF --->
			<cfloop collection="#signatureData.requestParams#" item="param">
				<cfhttpparam type="URL" name="#param#" value="#signatureData.requestParams[param]#" >
			</cfloop>

			<!--- Body --->
			<cfif len(arguments.body) >
				<cfhttpparam type="body" value="#arguments.body#" >
			</cfif>
		</cfhttp>

		<cfscript>
			// Log
			log.debug( "Amazon Rest Call ->Arguments: #arguments.toString()#, ->Encoded Signature=#signatureData.signature#", HTTPResults );

			// Set Results
			results.response 		= HTTPResults.fileContent;
			results.responseHeader 	= HTTPResults.responseHeader;
			// Error Detail
			results.message = HTTPResults.errorDetail;
			if( len( HTTPResults.errorDetail ) ){ results.error = true; }

			// Check XML Parsing?
			if( structKeyExists( HTTPResults.responseHeader, "content-type" ) AND
			    HTTPResults.responseHeader["content-type"] eq "application/xml" AND
				isXML( HTTPResults.fileContent )
			){
				results.response = XMLParse( HTTPResults.fileContent );
				// Check for Errors
				if( NOT listFindNoCase( "200,204", HTTPResults.responseHeader.status_code ) ){
					// check error xml
					results.error 	= true;
					var messages = [];
					for ( var node in results.response.error.XmlChildren ) {
						arrayAppend( messages, "#node.XmlName#: #node.XmlText#" );
					}
					results.message = arrayToList( messages, "\n" );
				}
			}

			return results;
		</cfscript>
	</cffunction>

	<!--- HMAC Encryption --->
	<cffunction name="HMAC_SHA1" returntype="binary" access="private" output="false" hint="NSA SHA-1 Algorithm: RFC 2104HMAC-SHA1 ">
		<cfargument name="signKey"     type="string" required="true" />
	   	<cfargument name="signMessage" type="string" required="true" />
	   	<cfscript>
			var jMsg = JavaCast( "string", arguments.signMessage ).getBytes( encryption_charset );
			var jKey = JavaCast( "string", arguments.signKey ).getBytes( encryption_charset );
			var key = createObject( "java", "javax.crypto.spec.SecretKeySpec" ).init( jKey,"HmacSHA1" );
			var mac = createObject( "java", "javax.crypto.Mac" ).getInstance( key.getAlgorithm() );

			mac.init( key );
			mac.update( jMsg );

			return mac.doFinal();
	   	</cfscript>
	</cffunction>

</cfcomponent>

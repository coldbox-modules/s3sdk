/**
 * Amazon Web Services Signature 4 Utility for ColdFusion
 **/
component singleton {

	/**
	 * Creates a new instance of the utility for generating signatures using the supplied settings
	 * @returns new instance initalized with specified settings
	 */
	Sv2Util function init(){
		return this;
	}

	/**
	 * Generates a version 2 signature and returns headers for the request
	 *
	 *  @requestMethod   - Request operation, ie PUT, GET, POST, etcetera.
	 *  @requestURI      - Absolute path of the URI. Portion of the URL after the host, to the "?" beginning the query string
	 *  @requestHeaders  - Structure of http headers for used the request.
	 *  @requestParams   - Structure containing any url parameters for the request.
	 *  @amzHeaders      - Structure containing any amazon headers used to build the signature.
	 */
	public struct function generateSignatureData(
		required string requestMethod,
		required string hostName,
		required string requestURI,
		required any requestBody,
		required struct requestHeaders,
		required struct requestParams,
		required string accessKey,
		required string secretKey,
		required string regionName,
		required string serviceName,
		boolean signedPayload = true,
		array excludeHeaders  = [],
		string amzDate,
		string dateStamp
	){
		var props = {
			requestHeaders : arguments.requestHeaders,
			requestParams  : arguments.requestParams,
			canonicalURI   : "",
			accessKey      : arguments.accessKey,
			secretKey      : arguments.secretKey,
			regionName     : arguments.regionName,
			serviceName    : arguments.serviceName,
			hostName       : arguments.hostName,
			requestMethod  : arguments.requestMethod,
			requestPayload : arguments.signedPayload ? hash256( arguments.requestBody ) : arguments.requestBody,
			excludeHeaders : arguments.excludeHeaders
		};

		// Override current utc date and time
		if ( structKeyExists( arguments, "amzDate" ) || structKeyExists( arguments, "dateStamp" ) ) {
			props.dateStamp = arguments.dateStamp;
			props.amzDate   = arguments.amzDate;
		} else {
			var utcDateTime = dateConvert( "local2UTC", now() );
			// Generate UTC time stamps
			props.dateStamp = dateFormat( utcDateTime, "yyyymmdd" );
			props.amzDate   = props.dateStamp & "T" & timeFormat( utcDateTime, "HHmmss" ) & "Z";
		}

		var sortedHeaders = structSort( props.requestHeaders, "text", "asc" );
		for ( var header in sortedHeaders ) {
			props.canonicalURI &= lCase( trim( header ) ) & ":" & props.requestHeaders[ header ] & chr( 10 );
		};

		props.canonicalURI = props.requestMethod & chr( 10 )
		& ( props.requestHeaders[ "content-md5" ] ?: "" ) & chr( 10 )
		& ( props.requestHeaders[ "content-type" ] ?: "" ) & chr( 10 )
		& props.amzDate & chr( 10 )
		& props.canonicalURI
		& "/" & arguments.requestURI;

		//  Calculate the hash of the information
		var digest                = hMAC_SHA1( props.secretKey, props.canonicalURI );
		//  fix the returned data to be a proper signature
		props.signature           = toBase64( digest );
		props.authorizationHeader = "AWS #props.accessKey#:#props.signature#";

		return props;
	}


	/**
	 * NSA SHA-1 Algorithm: RFC 2104HMAC-SHA1
	 */
	private binary function HMAC_SHA1(
		required string signKey,
		required string signMessage
	){
		var jMsg = javacast( "string", arguments.signMessage ).getBytes( encryptionCharset );
		var jKey = javacast( "string", arguments.signKey ).getBytes( encryptionCharset );
		var key  = createObject(
			"java",
			"javax.crypto.spec.SecretKeySpec"
		).init( jKey, "HmacSHA1" );
		var mac = createObject( "java", "javax.crypto.Mac" ).getInstance( key.getAlgorithm() );

		mac.init( key );
		mac.update( jMsg );

		return mac.doFinal();
	}

}

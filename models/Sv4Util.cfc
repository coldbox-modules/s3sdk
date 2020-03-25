/**
 * Amazon Web Services Signature 4 Utility for ColdFusion
 * Version Date: 2016-04-12 (Alpha)
 *
 * Copyright 2016 Leigh (cfsearching)
 *
 * Requirements: Adobe ColdFusion 10+
 * AWS Signature 4 specifications: http://docs.aws.amazon.com/general/latest/gr/signature-version-4.html
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
component singleton {

	/**
	 * Creates a new instance of the utility for generating signatures using the supplied settings
	 * @returns new instance initalized with specified settings
	 */
	Sv4Util function init() {
		// Algorithms used in calculating the signature
		variables.signatureAlgorithm = "AWS4-HMAC-SHA256";
		variables.hashAlorithm       = "SHA256";

		return this;
	}


	/**
	 *  Generates Signature 4 properties for the supplied request settings.
	 *
	 *  @requestMethod   - Request operation, ie PUT, GET, POST, etcetera.
	 *  @hostName        - Target host name, example: bucketname.s3.amazonaws.com
	 *  @requestURI      - Absolute path of the URI. Portion of the URL after the host, to the "?" beginning the query string
	 *  @requestBody     - Body of the request. Either a string or binary value.
	 *  @requestHeaders  - Structure of http headers for used the request. Mandatory host and date headers are automatically generated.
	 *  @requestParams   - Structure containing any url parameters for the request. Mandatory parameters are automatically generated.
	 *  @excludeHeaders  - (Optional) List of header names AWS can exclude from the signing process. Default is an empty array, which means all headers should be "signed"
	 *  @amzDate         - (Optional) Override the automatic X-Amz-Date calculation with this value. Current UTC date. If supplied, @dateStamp is required.  Format: yyyyMMddTHHnnssZ
	 *  @regionName      - (Optional) Override the instance region name with this value. Example "us-east-1"
	 *  @serviceName     - (Optional) Override the instance service name with this value. Example "s3"
	 *  @dateStamp       - (Optional) Override the automatic dateStamp calculation with this value. Current UTC date (only). If supplied, @amzDate is required. Format: yyyyMMdd
	 *  @presigningDownloadURL - (Optional) Generates a signed request with all required parameters in the query string, and no headers except for Host.
	 *  @returns  Signature value, authorization header and all properties part of the signature calculation: ALGORITHM,AMZDATE,AUTHORIZATIONHEADER,CANONICALHEADERS,CANONICALQUERYSTRING,CANONICALREQUEST,CANONICALURI,CREDENTIALSCOPE,DATESTAMP,EXCLUDEHEADERS,HOSTNAME,REGIONNAME,REQUESTHEADERS,REQUESTMETHOD,REQUESTPARAMS,REQUESTPAYLOAD,SERVICENAME,SIGNATURE,SIGNEDHEADERS,SIGNKEYBYTES,STRINGTOSIGN
	 *
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
		array excludeHeaders  = [],
		string amzDate,
		string dateStamp,
		boolean presignDownloadURL = false
	) {
		// Initialize properties
		var props          = {};
		var hasQueryParams = structCount( arguments.requestParams ) > 0;
		var utcDateTime    = dateConvert( "local2UTC", now() );

		// Generate UTC time stamps
		props.dateStamp = dateFormat( utcDateTime, "YYYYMMDD" );
		props.amzDate   = props.dateStamp & "T" & timeFormat( utcDateTime, "HHmmss" ) & "Z";

		// Override current utc date and time
		if ( structKeyExists( arguments, "amzDate" ) || structKeyExists( arguments, "dateStamp" ) ) {
			props.dateStamp = arguments.dateStamp;
			props.amzDate   = arguments.amzDate;
		}

		props.accessKey   = arguments.accessKey;
		props.secretKey   = arguments.secretKey;
		props.regionName  = arguments.regionName;
		props.serviceName = arguments.serviceName;

		// ///////////////////////////////////
		//  Basic request properties
		// ///////////////////////////////////
		props.algorithm     = variables.signatureAlgorithm;
		props.hostName      = arguments.hostName;
		props.requestMethod = arguments.requestMethod;
		props.canonicalURI  = buildCanonicalURI( requestURI = arguments.requestURI );

		// For signed requests, the payload is a checksum
		props.requestPayload  = hash256( arguments.requestBody );
		props.credentialScope = buildCredentialScope(
			dateStamp   = props.dateStamp,
			serviceName = props.serviceName,
			regionName  = props.regionName
		);


		// ///////////////////////////////////
		//  Validate headers/parameters
		// ///////////////////////////////////
		props.requestHeaders = duplicate( arguments.requestHeaders );
		props.requestParams  = duplicate( arguments.requestParams );

		// Host header is mandatory for ALL requests
		props.requestHeaders[ "Host" ] = arguments.hostName;

		// Apply mandatory headers and parameters
		if ( presignDownloadURL ) {
			// First, normalize request headers
			props.requestHeaders = cleanHeaders( props.requestHeaders );
			props.excludeHeaders = cleanHeaderNames( arguments.excludeHeaders );

			// Signed requests must include a checksum, ie hash of payload
			// props.requestParams["X-Amz-Content-Sha256"] = props.requestPayload;
			props.requestPayload = "UNSIGNED-PAYLOAD";

			// Identify which headers will be included in the signing process
			props.signedHeaders  = buildSignedHeaders(
				requestHeaders = props.requestHeaders,
				excludeNames   = props.excludeHeaders
			);

			// When presigning a download URL, canonical query string must also
			// include the parameters used as part of the signing process, ie hashing algorithm,
			// credential scope, date, and signed headers parameters.
			props.requestParams["X-Amz-Algorithm"] = variables.signatureAlgorithm;
			props.requestParams["X-Amz-Credential"] = "#props.accessKey#/#props.credentialScope#";
			props.requestParams["X-Amz-SignedHeaders"] = props.signedHeaders;
			props.requestParams["X-Amz-Date"] = props.amzDate;

			// Finally, normalize url parameters
			props.requestParams = encodeQueryParams( queryParams = props.requestParams );
		}
		// All other request types (PUT, DELETE, POST, ....)
		else {
			// Signed requests must include a checksum, ie hash of payload
			props.requestHeaders["X-Amz-Content-Sha256"] = props.requestPayload;

			// Host header is mandatory for ALL requests
			props.requestHeaders[ "Host" ]       = arguments.hostName;
			// Date header is mandatory when not passing values in url
			props.requestHeaders[ "X-Amz-Date" ] = props.amzDate;

			// Normalize headers and url parameters
			props.requestHeaders = cleanHeaders( props.requestHeaders );
			props.excludeHeaders = cleanHeaderNames( arguments.excludeHeaders );
			// Identify which headers will be included in the signing process
			props.signedHeaders  = buildSignedHeaders(
				requestHeaders = props.requestHeaders,
				excludeNames   = props.excludeHeaders
			);
			props.requestParams = encodeQueryParams( queryParams = props.requestParams );
		}


		// ///////////////////////////////////////
		//  Generate signature
		// ///////////////////////////////////////

		// Generate header, query, and request strings
		props.canonicalQueryString = buildCanonicalQueryString( requestParams = props.requestParams );
		props.canonicalHeaders     = buildCanonicalHeaders( requestHeaders = props.requestHeaders );
		props.canonicalRequest     = buildCanonicalRequest( argumentCollection = props );

		// Generate signature and authorization strings
		props.stringToSign = generateStringToSign( argumentCollection = props );
		props.signKeyBytes = generateSignatureKey( argumentCollection = props );
		props.signature    = lCase(
			binaryEncode( hmacBinary( message = props.stringToSign, key = props.signKeyBytes ), "hex" )
		);
		props.authorizationHeader = buildAuthorizationHeader( argumentCollection = props );

		// (Debugging) Convert binary values into human readable form
		props.signKeyBytes = binaryEncode( props.signKeyBytes, "hex" );

		return props;
	}

	/**
	 *  Generates request string to sign
	 *
	 *  @amzDate          - Current timestamp in UTC. Format yyyyMMddTHHnnssZ
	 *  @credentialScope  - String defining scope of request. See buildCredentialScope().
	 *  @canonicalRequest - Canonical request string
	 *  @returns          - String to be signed
	 */
	private string function generateStringToSign(
		required string amzDate,
		required string credentialScope,
		required string canonicalRequest
	) {
		// Format: Algorithm + '\n' + RequestDate + '\n' + CredentialScope + '\n' + HashedCanonicalRequest
		var elements = [
			variables.signatureAlgorithm,
			arguments.amzDate,
			arguments.credentialScope,
			hash256( arguments.canonicalRequest )
		];

		return arrayToList( elements, chr( 10 ) );
	}

	/**
	 *  Generate canonical request string
	 *
	 *  @requestMethod           - Request operation, ie PUT, GET, POST, etcetera.
	 *  @canonicalURI            - Canonical URL string. See buildCanonicalURI
	 *  @canonicalHeaders        - Canonical header string. See buildCanonicalHeaders
	 *  @canonicalQueryString    - Canonical query string. See buildCanonicalQueryString
	 *  @signedHeaders           - List of signed headers. See buildSignedHeaders
	 *  @requestPayload          - For signed requests, this is the hash of the request body. Otherwise, the raw request body
	 */
	private string function buildCanonicalRequest(
		required string requestMethod,
		required string canonicalURI,
		required string canonicalQueryString,
		required string canonicalHeaders,
		required string signedHeaders,
		required string requestPayload
	) {
		var canonicalRequest = "";

		// Build ordered list of elements in the request, delimited by new lines
		// Note: Headers and signed headers should never be empty. "Host" header is always required.
		canonicalRequest = arguments.requestMethod & chr( 10 )
		& arguments.canonicalURI & chr( 10 )
		& arguments.canonicalQueryString & chr( 10 )
		& arguments.canonicalHeaders & chr( 10 )
		& arguments.signedHeaders & chr( 10 )
		& arguments.requestPayload;

		return canonicalRequest;
	}

	/**
	 * Generates canonical query string
	 * <ul>
	 *  <li>URI-encode each parameter name and value according to RFC 3986 </li>
	 *  <li>Percent-encode all other characters with %XY, where X and Y are hexadecimal characters (0-9 and uppercase A-F)  </li>
	 *  <li>Sort the encoded parameter names by character code in ascending order (ASCII order) </li>
	 *  <li>Build the canonical query string by starting with the first parameter name in the sorted list. </li>
	 *  <li>For each parameter, append the URI-encoded parameter name, followed by the character '=' (ASCII code 61), followed by the URI-encoded parameter value. Use an empty string for parameters that have no value. </li>
	 *  <li>Append the character '&' (ASCII code 38) after each parameter value, except for the last value in the list. </li>
	 *  </ul>
	 *
	 * @requestParams Structure containing all parameters passed via the query string.
	 * @isEncoded If true, the supplied parameters are already url encoded
	 * @returns canonical query string
	 */
	private string function buildCanonicalQueryString( required struct requestParams, boolean isEncoded = true ) {
		var encodedParams = "";
		var paramNames    = "";
		var paramPairs    = "";

		// Ensure parameter names and values are URL encoded first
		encodedParams = isEncoded ? arguments.requestParams : encodeQueryParams( arguments.requestParams );

		// Extract and sort encoded parameter names
		paramNames = structKeyArray( encodedParams );
		arraySort( paramNames, "text", "asc" );

		// Build array of sorted name/value pairs
		paramPairs = [];
		arrayEach( paramNames, function( string param ) {
			arrayAppend( paramPairs, arguments.param & "=" & encodedParams[ arguments.param ] );
		} );

		// Finally, generate sorted list of parameters, delimited by "&"
		return arrayToList( paramPairs, "&" );
	}


	/**
	 * Generates a list of signed header names.
	 *
	 * <p>"...By adding this list of headers, you tell AWS which headers in the request
	 * are part of the signing process and which ones AWS can ignore (for example, any
	 * additional headers added by a proxy) for purposes of validating the request."</p>
	 *
	 * @requestHeaders Raw headers to be included in request
	 * @excludeNames Names of any headers AWS should ignore for the signing process
	 * @returns Sorted list of signed header names, delimited by semi-colon ";"
	 */
	private string function buildSignedHeaders( required struct requestHeaders, required array excludeNames ) {
		var name        = "";
		var headerNames = [];
		var allHeaders  = !arrayLen( arguments.excludeNames );

		// Identify which headers are "signed"
		structEach( arguments.requestHeaders, function( string name, any value ) {
			if ( allHeaders || !arrayFindNoCase( excludeNames, arguments.name ) ) {
				arrayAppend( headerNames, arguments.name );
			}
		} );

		// Sort header names in ASCII order
		arraySort( headerNames, "text", "asc" );

		// Return list of names
		return arrayToList( headerNames, ";" );
	}

	/**
	 * Generates a list of canonical headers
	 * @requestHeaders Structure containing headers to be included in request hash
	 * @returns Sorted list of header pairs, delimited by new lines
	 */
	private string function buildCanonicalHeaders( required struct requestHeaders ) {
		var pairs   = "";
		var names   = "";
		var headers = "";

		// Scrub the header names and values first
		headers = cleanHeaders( arguments.requestHeaders );

		// Sort header names in ASCII order
		names = structKeyArray( headers );
		arraySort( names, "text", "asc" );

		// Build array of sorted header name and value pairs
		pairs = [];
		arrayEach( names, function( string key ) {
			arrayAppend( pairs, arguments.key & ":" & headers[ arguments.key ] );
		} );

		// Generate list. Note: List must END WITH a new line character
		return arrayToList( pairs, chr( 10 ) ) & chr( 10 );
	}


	/**
	 * Generates canonical URI. Encoded, absolute path component of the URI,
	 * which is everything in the URI from the HTTP host to the question mark character ("?")
	 * that begins the query string parameters (if any)
	 *
	 * @uriPath URI or path. If empty, "/" will be used
	 * @returns URL encoded path
	 */
	private string function buildCanonicalURI( required string requestURI ) {
		var path = arguments.requestURI;
		// Return "/" for empty path
		if ( !len( trim( path ) ) ) {
			path = "/";
		}

		// Convert to absolute path (if needed)
		if ( left( path, 1 ) != "/" ) {
			path = "/" & path;
		}

		return urlEncodePath( path );
	}


	/**
	 * Generates signing key for AWS Signature V4
	 *
	 * <p>Source: http://stackoverflow.com/questions/32513197/how-to-derive-a-sign-in-key-for-aws-signature-version-4-in-coldfusion</p>
	 *
	 * @dateStamp Date stamp in YYYYMMDD format. Example: 20150830
	 * @regionName  Region name that is part of the service's endpoint (alphanumeric). Example: "us-east-1"
	 * @serviceName Service name that is part of the service's endpoint (alphanumeric). Example: "s3"
	 * @algorithm HMAC algorithm. Default is "HMACSHA256"
	 * @returns signing key in binary
	 */
	private binary function generateSignatureKey(
		required string dateStamp,
		required string regionName,
		required string serviceName,
		required string secretKey,
		string algorithm = "HMACSHA256"
	) {
		var kSecret  = charsetDecode( "AWS4" & arguments.secretKey, "UTF-8" );
		var kDate    = hmacBinary( arguments.dateStamp, kSecret );
		// Region information as a lowercase alphanumeric string
		var kRegion  = hmacBinary( lCase( arguments.regionName ), kDate );
		// Service name information as a lowercase alphanumeric string
		var kService = hmacBinary( lCase( arguments.serviceName ), kRegion );
		// A special termination string: aws4_request
		var kSigning = hmacBinary( "aws4_request", kService );

		return kSigning;
	}


	/**
	 *  Generates string indicating the scope for which the signature is valid. Credential scope
	 *  is represented by a slash-separated string of dimensions in the following order:
	 *
	 *         dateStamp / regionName / serviceName / terminationString
	 *
	 *  @dateStamp   - Current date in UTC (must be same as X-Amz-Date date). Format yyyyMMdd
	 *  @regionName  - Name of the target region, UTF-8 encoded. Example "us-east-1"
	 *  @serviceName - Name of the target service, UTF-8 encoded. Example "s3"
	 *  @returns     - formatted string. Example:  20150830/us-east-1/iam/aws4_request
	 */
	private string function buildCredentialScope(
		required string dateStamp,
		required string regionName,
		required string serviceName
	) {
		return arguments.dateStamp & "/" & lCase( arguments.regionName ) & "/" & lCase( arguments.serviceName ) & "/" & "aws4_request";
	}

	/**
	 *  Generates Authorization header string.
	 *
	 *  Format:  algorithm + ' ' + 'Credential=' + access_key + '/' + credential_scope
	 *                   + ', ' +  'SignedHeaders=' + signed_headers + ', '
	 *                   + 'Signature=' + signature
	 *
	 *  @dateStamp   - Current date in UTC (must be same as X-Amz-Date date). Format yyyyMMdd
	 *  @regionName  - Name of the target region, UTF-8 encoded. Example "us-east-1"
	 *  @serviceName - Name of the target service, UTF-8 encoded. Example "s3"
	 *  @returns     - formatted string. Example:  20150830/us-east-1/iam/aws4_request
	 */
	private string function buildAuthorizationHeader(
		required struct requestHeaders,
		required string signedHeaders,
		required string credentialScope,
		required string signature,
		required string accessKey
	) {
		var authHeader = variables.signatureAlgorithm & " "
		& "Credential=" & arguments.accessKey & "/" & arguments.credentialScope & ","
		& "SignedHeaders=" & arguments.signedHeaders & ","
		& "Signature=" & arguments.signature;


		return authHeader;
	}


	/**
	 * Convenience method which generates a (binary) HMAC code for the specified message
	 *
	 * @message Message to sign
	 * @key HMAC key in binary form
	 * @algorithm Signing algorithm. [ Default is "HMACSHA256" ]
	 * @encoding Character encoding of message string. [ Default is UTF-8 ]
	 * @returns HMAC value for the specified message as binary (currently unsupported in CF11)
	 */
	private binary function hmacBinary(
		required string message,
		required binary key,
		string algorithm = "HMACSHA256",
		string encoding  = "UTF-8"
	) {
		// Generate HMAC and decode result into binary
		return binaryDecode(
			hmac(
				arguments.message,
				arguments.key,
				arguments.algorithm,
				arguments.encoding
			),
			"hex"
		);
	}


	/**
	 * Convenience method that hashes the supplied value, with SHA256
	 * @text value to hash
	 * @returns hashed value, in lower case
	 */
	private string function hash256( required any text ) {
		return lCase( hash( arguments.text, "SHA-256" ) );
	}


	/**
	 * URL encode query parameters and names
	 * @params Structure containing all query parameters for the request
	 * @returns new structure with all parameter names and values encoded
	 */
	private struct function encodeQueryParams( required struct queryParams ) {
		// First encode parameter names and values
		var encodedParams = {};
		structEach( arguments.queryParams, function( string key, string value ) {
			encodedParams[ urlEncodeForAWS( arguments.key ) ] = urlEncodeForAWS( arguments.value );
		} );
		return encodedParams;
	}

	/**
	 * Scrubs header names and values:
	 * <ul>
	 *    <li>Removes leading and trailing spaces from names and values</li>
	 *    <li>Converts sequential spaces to single space in names and values</li>
	 *    <li>Converts all header names to lower case</li>
	 * </ul>
	 * @headers Header names and values to scrub
	 * @returns structure of parsed header names and values
	 */
	private struct function cleanHeaders( required struct headers ) {
		var headerName  = "";
		var headerValue = "";
		var cleaned     = {};

		structEach( arguments.headers, function( string key, string value ) {
			headerName                     = cleanHeader( arguments.key );
			headerValue                    = cleanHeader( arguments.value );
			cleaned[ lCase( headerName ) ] = headerValue;
		} );

		return cleaned;
	}

	/**
	 * Scrubs header names and values:
	 * <ul>
	 *    <li>Removes leading and trailing spaces</li>
	 *    <li>Converts sequential spaces to single space</li>
	 *    <li>Converts all names to lower case</li>
	 * </ul>
	 * @headers Header names to scrub
	 * @returns array of parsed header names
	 */
	private array function cleanHeaderNames( required array names ) {
		var headerName = "";

		var cleaned = [];
		arrayEach( names, function( string headerName ) {
			arrayAppend( cleaned, cleanHeader( arguments.headerName ) );
		} );

		return cleaned;
	}


	/**
	 * Removes extraneous white space from header names or values.
	 * See http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
	 *
	 * <ul>
	 *    <li>Removes leading and trailing spaces</li>
	 *    <li>Converts sequential spaces to single space</li>
	 * </ul>
	 * @text Text to scrub
	 * @returns parsed text
	 */
	private string function cleanHeader( required string text ) {
		return reReplace(
			trim( arguments.text ),
			"\s+",
			chr( 32 ),
			"all"
		);
	}


	/**
	 * URL encodes the supplied string per RFC 3986, which defines the following as
	 * unreserved characters that should NOT be encoded:
	 *
	 * A-Z, a-z, 0-9, hyphen ( - ), underscore ( _ ), period ( . ), and tilde ( ~ ).
	 *
	 * @value string to encode
	 * @returns URI encoded string
	 */
	private string function urlEncodeForAWS( string value ) {
		var encodedValue = encodeForURL( arguments.value );
		// Reverse encoding of tilde "~"
		encodedValue     = replace(
			encodedValue,
			encodeForURL( "~" ),
			"~",
			"all"
		);
		// Fix encoding of spaces, ie replace '+' into "%20"
		encodedValue = replace( encodedValue, "+", "%20", "all" );
		// Asterisk "*" should be encoded
		encodedValue = replace( encodedValue, "*", "%2A", "all" );

		return encodedValue;
	}


	/**
	 * URL encodes the supplied string per RFC 3986, which defines the following as
	 * unreserved characters that should NOT be encoded:
	 *
	 * A-Z, a-z, 0-9, hyphen ( - ), underscore ( _ ), period ( . ), and tilde ( ~ ).
	 *
	 * @value string to encode
	 * @returns URI encoded string
	 */
	private string function urlEncodePath( string value ) {
		var encodedValue = encodeForURL( arguments.value );
		// Reverse encoding of tilde "~"
		encodedValue     = replace(
			encodedValue,
			encodeForURL( "~" ),
			"~",
			"all"
		);
		// Fix encoding of spaces, ie replace '+' into "%20"
		encodedValue = replace( encodedValue, "+", "%20", "all" );
		// Asterisk "*" should be encoded
		encodedValue = replace( encodedValue, "*", "%2A", "all" );
		// Asterisk "*" should be encoded
		encodedValue = replace( encodedValue, "%2F", "/", "all" );

		return encodedValue;
	}

	/**
	 * Returns current UTC date and time in the following formats:
	 *   - dateStamp - Current UTC date, format: YYYYMMDD
	 *   - timeStamp - Current UTC date and time, format: YYYYMMDDTHHnnssZ
	 * @returns structure containing date and time strings
	 */
	public struct function getUTCStrings() {
		var utcDateTime = dateConvert( "local2UTC", now() );
		var result      = {};

		// Generate UTC time stamps
		result.dateStamp = dateFormat( utcDateTime, "YYYYMMDD" );
		result.amzDate   = result.dateStamp & "T" & timeFormat( utcDateTime, "HHmmss" ) & "Z";
		result.timeStamp = dateFormat( utcDateTime, "YYYY-MM-DD" ) & "T" & timeFormat( utcDateTime, "HH:mm:ss" ) & "Z";
		return result;
	}

}

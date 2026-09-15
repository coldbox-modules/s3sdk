[![AWS S3 SDK CI](https://github.com/coldbox-modules/s3sdk/actions/workflows/ci.yml/badge.svg)](https://github.com/coldbox-modules/s3sdk/actions/workflows/ci.yml)

[![Total Downloads](https://forgebox.io/api/v1/entry/s3sdk/badges/downloads)](https://forgebox.io/view/s3sdk)
[![Latest Stable Version](https://forgebox.io/api/v1/entry/s3sdk/badges/version)](https://forgebox.io/view/s3sdk)
[![Apache2 License](https://img.shields.io/badge/License-Apache2-blue.svg)](https://forgebox.io/view/s3sdk)


# Amazon S3 SDK

This SDK will provide you with Amazon S3 connectivity for any ColdBox, BoxLang or CFML Application. It also works great as a standalone library outside of ColdBox, and is fully compatible with S3-compatible services like DigitalOcean Spaces, Google Cloud Storage and MinIO.

Built natively for [BoxLang](https://www.boxlang.io/), and fully backwards compatible with Lucee and Adobe ColdFusion (ACF).

## Features

* First-class [BoxLang](https://www.boxlang.io/) support, running natively or in CFML compatibility mode
* Works with Lucee and Adobe ColdFusion (ACF)
* Full ColdBox Module integration with WireBox injection DSL: `AmazonS3@s3sdk`
* Also usable 100% standalone, outside of ColdBox
* AWS Signature Version 4 (default) and Version 2 support
* Compatible with any S3-compatible endpoint: Amazon S3, DigitalOcean Spaces, Google Cloud Storage, MinIO, etc
* Bucket operations: create, list, delete, ACLs, versioning, lifecycle rules
* Object operations: put, get, copy, rename, delete, metadata, streaming downloads
* Multi-part uploads for large files with configurable concurrency, keeping memory usage low
* Pre-signed URL generation for both `GET` and `PUT` operations, so clients can upload/download directly to/from S3 without proxying through your server
* Server-side encryption support (SSE-C / SSE-S3)
* Automatic retries on `500`/`503` responses with configurable retry counts
* LogBox integration for full request/response debugging

## Resources

* Source: https://github.com/coldbox-modules/s3sdk
* Issues: https://github.com/coldbox-modules/s3sdk/issues
* [Changelog](changelog.md)
* API Docs: https://apidocs.ortussolutions.com/#/coldbox-modules/s3sdk/
* S3 API Reference: https://docs.aws.amazon.com/AmazonS3/latest/API/API_Operations_Amazon_Simple_Storage_Service.html
* DigitalOcean Spaces API Reference: https://developers.digitalocean.com/documentation/spaces/

## Requirements

* [BoxLang](https://www.boxlang.io/) 1+ (native or CFML compatibility mode)
* Lucee 6+
* Adobe ColdFusion 2023+
* ColdBox 8+ (only if used as a ColdBox Module)

## Installation

This SDK can be installed as a standalone library or as a ColdBox Module. Either approach requires a simple [CommandBox](https://www.ortussolutions.com/products/commandbox) command:

```bash
box install s3sdk
```

### AI Skills

The repository's BoxLang AI skills are ignored from version control. Install them locally with:

```bash
npx skills experimental_install
```

Then follow either the standalone or module instructions below.

### Standalone Usage

This SDK will be installed into a directory called `s3sdk` and can be instantiated directly via `new s3sdk.models.AmazonS3()`:

```js
s3 = new s3sdk.models.AmazonS3(
	accessKey = "your-access-key",
	secretKey = "your-secret-key",
	awsRegion = "us-east-1"
);

// Create a bucket
s3.createBucket( bucketName = "my-bucket" );

// Upload a file
s3.putObjectFile(
	bucketName = "my-bucket",
	filepath   = "/path/to/file.pdf",
	uri        = "documents/file.pdf"
);

// Generate a pre-signed download URL valid for 5 minutes
url = s3.getAuthenticatedURL(
	bucketName = "my-bucket",
	uri        = "documents/file.pdf",
	minutesValid = 5
);

// Delete an object
s3.deleteObject( bucketName = "my-bucket", uri = "documents/file.pdf" );
```

Full constructor reference:

```js
/**
 * Create a new S3SDK Instance
 *
 * @accessKey The Amazon access key.
 * @secretKey The Amazon secret key.
 * @awsDomain The Domain used S3 Service (amazonws.com, digitalocean.com, storage.googleapis.com). Defaults to amazonws.com
 * @awsRegion The Amazon region. Defaults to us-east-1 for amazonaws.com
 * @encryptionCharset The charset for the encryption. Defaults to UTF-8.
 * @signature The signature version to calculate, "V2" is deprecated but more compatible with other endpoints. "V4" requires Sv4Util.cfc & ESAPI on Lucee. Defaults to V4
 * @ssl True if the request should use SSL. Defaults to true.
 * @defaultTimeOut Default HTTP timeout for all requests. Defaults to 300.
 * @defaultDelimiter Delimter to use for getBucket calls. "/" is standard to treat keys as file paths
 * @defaultBucketName Bucket name to use by default
 * @defaultCacheControl Default caching policy for objects. Defaults to: no-store, no-cache, must-revalidate
 * @defaultStorageClass Default storage class for objects that affects cost, access speed and durability. Defaults to STANDARD.
 * @defaultACL Default access control policy for objects and buckets. Defaults to public-read.
 * @autoContentType Tries to determine content type of file by file extension. Defaults to false.
 * @autoMD5 Calculates MD5 hash of content automatically. Defaults to false.
 * @debug Used to turn debugging on or off outside of logbox. Defaults to false.
 * @defaultEncryptionAlgorithm The default server side encryption algorithm to use.  Usually "AES256". Not needed if using custom defaultEncryptionKey
 * @defaultEncryptionKey	The default base64 encoded AES 356 bit key for server side encryption.
 * @urlStyle					 Specifies the format of the URL whether it is the `path` format or `virtual` format. Defaults to path. For more information see https://docs.aws.amazon.com/AmazonS3/latest/userguide/VirtualHosting.html
 *
 * @return An AmazonS3 instance.
 */
public AmazonS3 function init(
	required string accessKey,
	required string secretKey,
	string awsDomain = "amazonaws.com",
	string awsRegion = "us-east-1",
	string encryptionCharset = "UTF-8",
	string signature = "V4",
	boolean ssl = true,
	string defaultTimeOut= 300,
	string defaultDelimiter='/',
	string defaultBucketName='',
	string defaultCacheControl= "no-store, no-cache, must-revalidate",
	string defaultStorageClass= "STANDARD",
	string defaultACL= "public-read",
	boolean autoContentType= false,
	boolean autoMD5= false,
	boolean debug= false,
	string defaultEncryptionAlgorithm = "",
	string defaultEncryptionKey = "",
	string urlStyle	= "path"
)
```

### ColdBox Module

This package is also a ColdBox module. Configure it by creating an `s3sdk` configuration structure in your `moduleSettings` struct in `config/Coldbox.cfc`:

```js
moduleSettings = {
	s3sdk = {
		// Your amazon, digital ocean access key
		accessKey = "",
		// Tries to determine content type of file by file extension when putting files. Defaults to false.
		autoContentType = false,
		// Calculates MD5 hash of content automatically. Defaults to false.
		autoMD5 = false,
		// Your AWS/Digital Ocean Domain Mapping: defaults to amazonaws.com
		awsDomain = "amazonaws.com",
		// Your AWS/Digital Ocean Region: Defaults to us-east-1
		awsregion = "us-east-1",
		// Used to turn debugging on or off outside of logbox. Defaults to false.
		debug = false,
		// Default access control policy for objects and buckets. Defaults to public-read.
		defaultACL = "public-read",
		// The default bucket name to root the operations on.
		defaultBucketName = "",
		// Default caching policy for objects. Defaults to: no-store, no-cache, must-revalidate
		defaultCacheControl = "no-store, no-cache, must-revalidate",
		// The default delimiter for folder operations
		defaultDelimiter = "/",
		// Default storage class for objects that affects cost, access speed and durability. Defaults to STANDARD.
		// AWS classes are: STANDARD,STANDARD_IA,INTELLIGENT_TIERING,ONEZONE_IA,GLACIER,DEEP_ARCHIVE
		// Google Cloud Storage Clases: regional,multi_regional,nearline,coldline,
		defaultStorageClass = "STANDARD",
		// Default HTTP timeout in seconds for all requests. Defaults to 300 seconds.
		defaultTimeOut = 300,
		// The default encryption character set: defaults to utf-8
		encryptionCharset = "utf-8",
		// How many times to retry the request before failing if the response is a 500 or 503
		retriesOnError		: 3,
		// Your amazon, digital ocean secret key
		secretKey = "",
		// Service name that is part of the service's endpoint (alphanumeric). Example: "s3"
		// Only used for the v4 signatures
		serviceName         : "s3",
		// The signature version to calculate, "V2" is deprecated but more compatible with other endpoints. "V4" requires Sv4Util.cfc & ESAPI on Lucee. Defaults to V4
		signature = "V4",
		// SSL mode or not on cfhttp calls and when generating put/get authenticated URLs: Defaults to true
		ssl = true,
		// Throw exceptions when s3 requests fail, else it swallows them up.
		throwOnRequestError : true,
		// What format of endpoint to use whether path or virtual
		urlStyle = "path"
	}
};
```

Then leverage the SDK via the WireBox injection DSL: `AmazonS3@s3sdk`

```js
component {

	property name="s3" inject="AmazonS3@s3sdk";

	function index( event, rc, prc ){
		s3.putObjectFile(
			bucketName = "my-bucket",
			filepath   = "/path/to/file.pdf"
		);
	}

}
```

## S3-Compatible Services

Since this SDK speaks the standard S3 REST API, it works out of the box with any S3-compatible storage provider by simply changing the `awsDomain` setting:

| Provider              | `awsDomain`                  |
|------------------------|-------------------------------|
| Amazon S3               | `amazonaws.com` (default)    |
| DigitalOcean Spaces      | `digitaloceanspaces.com`      |
| Google Cloud Storage     | `storage.googleapis.com`      |
| MinIO / self-hosted      | your MinIO endpoint hostname  |

## Usage

Please check out the full API docs: https://apidocs.ortussolutions.com/#/coldbox-modules/s3sdk/, choose your version and code away!

## Running the Tests

This module ships with a `test-harness` and can be tested against any of the supported engines using CommandBox:

```bash
box install
box server start serverConfigFile="server-boxlang@1.json"
box testbox run
```

See `.github/workflows/tests.yml` for the full CI matrix, which runs against native BoxLang, BoxLang with CFML compatibility, Lucee and Adobe ColdFusion.

## Development

See [Contributing](https://github.com/coldbox-modules/s3sdk/blob/development/CONTRIBUTING.md) and [AGENTS.md](AGENTS.md) for guidance on developing and testing this module, including for AI coding agents.

## Contributing

Pull requests are welcome! Please make sure any changes pass `box run-script format:check` and the full test suite before submitting.

----

&copy; Ortus Solutions, Corp

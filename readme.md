[![Build Status](https://travis-ci.com/coldbox-modules/s3sdk.svg?branch=master)](https://travis-ci.com/coldbox-modules/s3sdk)

# Welcome to the Amazon S3, DigitalOcean Spaces SDK

This SDK allows you to add Amazon S3, Digital Ocean Spaces capabilities to your ColdFusion (CFML) applications. It is also a ColdBox Module, so if you are using ColdBox, you get auto-registration and much more.

## Resources

* Source: https://github.com/coldbox-modules/s3sdk
* Issues: https://github.com/coldbox-modules/s3sdk/issues
* [Changelog](changelog.md)
* S3 API Reference: https://docs.aws.amazon.com/AmazonS3/latest/API/API_Operations_Amazon_Simple_Storage_Service.html
* Digital Oceans Spaces API Reference: https://developers.digitalocean.com/documentation/spaces/

## Installation

This SDK can be installed as standalone or as a ColdBox Module.  Either approach requires a simple CommandBox command:

```bash
box install s3sdk
```

Then follow either the standalone or module instructions below.

### Standalone

This SDK will be installed into a directory called `s3sdk` and then the SDK can be instantiated via ` new s3sdk.models.AmazonS3()` with the following constructor arguments:

```js
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
 * @autoContentType Tries to determine content type of file by file extension. Defaults to false.
 * @autoMD5 Calculates MD5 hash of content automatically. Defaults to false.
 * @debug Used to turn debugging on or off outside of logbox. Defaults to false.
 *
 * @return An AmazonS3 instance.
 */
public AmazonS3 function init(
	required string accessKey,
	required string secretKey,
	string awsDomain = "amazonaws.com",
	string awsRegion = "us-east-1",
	string encryption_charset = "UTF-8",
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
	boolean debug= false
)
)
```

### ColdBox Module

This package also is a ColdBox module as well.  The module can be configured by creating an `s3sdk` configuration structure in your `moduleSettings` struct in the application configuration file: `config/Coldbox.cfc` with the following settings:

```js
moduleSettings = {
	s3sdk = {
		// Your amazon, digital ocean access key
		accessKey = "",
		// Your amazon, digital ocean secret key
		secretKey = "",
		// The default encryption character set: defaults to utf-8
		encryption_charset = "utf-8",
		// The signature version to calculate, "V2" is deprecated but more compatible with other endpoints. "V4" requires Sv4Util.cfc & ESAPI on Lucee. Defaults to V4
		signature = "V4",
		// SSL mode or not on cfhttp calls: Defaults to true
		ssl = true,
		// Your AWS/Digital Ocean Domain Mapping: defaults to amazonaws.com
		awsDomain = "amazonaws.com",
		// Your AWS/Digital Ocean Region: Defaults to us-east-1
		awsregion = "us-east-1",
		// Default HTTP timeout for all requests. Defaults to 300.
		defaultTimeOut = 300,
		// The default delimiter for folder operations
		defaultDelimiter = "/",
		// The default bucket name to root the operations on.
		defaultBucketName = "",
		// Default caching policy for objects. Defaults to: no-store, no-cache, must-revalidate
		defaultCacheControl = "no-store, no-cache, must-revalidate",
		// Default storage class for objects that affects cost, access speed and durability. Defaults to STANDARD.
		defaultStorageClass = "STANDARD",
		// Default access control policy for objects and buckets. Defaults to public-read.
		defaultACL = "public-read",
		// Tries to determine content type of file by file extension. Defaults to false.
		autoContentType = false,
		// Calculates MD5 hash of content automatically. Defaults to false.
		autoMD5 = false
		// Used to turn debugging on or off outside of logbox. Defaults to false.
		debug = false
	}
};
```

Then you can leverage the SDK CFC via the injection DSL: `AmazonS3@s3sdk`

## Usage

Please check out the api docs: https://apidocs.ortussolutions.com/#/coldbox-modules/s3sdk/

## Development

See [Dev Setup](https://github.com/coldbox-modules/s3sdk/blob/development/dev_setup.md)

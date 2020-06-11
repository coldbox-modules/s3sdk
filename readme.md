[![Build Status](https://travis-ci.org/coldbox-modules/s3sdk.svg?branch=master)](https://travis-ci.org/coldbox-modules/s3sdk)

# Welcome to the Amazon S3, DigitalOcean Spaces SDK

This SDK allows you to add Amazon S3, Digital Ocean Spaces capabilities to your ColdFusion (CFML) applications. It is also a ColdBox Module, so if you are using ColdBox, you get auto-registration and much more.

## Resources

* Source: https://github.com/coldbox-modules/s3sdk
* Issues: https://github.com/coldbox-modules/s3sdk/issues
* [Changelog](changelog.md)
* S3 API Reference: http://docs.aws.amazon.com/AmazonS3/latest/API/Welcome.html
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
 * @awsRegion The Amazon region. Defaults to us-east-1
 * @awsDomain The Domain used S3 Service (amazonws.com, digitalocean.com). Defaults to amazonws.com
 * @encryption_charset The charset for the encryption. Defaults to UTF-8.
 * @ssl True if the request should use SSL. Defaults to true.
 * @defaultDelimiter Delimter to use for getBucket calls. "/" is standard to treat keys as file paths
 * @defaultBucketName Bucket name to use by default
 *
 * @return An AmazonS3 instance.
 */
public AmazonS3 function init(
	required string accessKey,
	required string secretKey,
	string awsRegion = "us-east-1",
	string awsDomain = "amazonaws.com",
	string encryption_charset = "UTF-8",
	boolean ssl = true,
	string defaultDelimiter='/',
	string defaultBucketName=''
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
		// SSL mode or not on cfhttp calls: Defaults to true
		ssl = true,
		// Your AWS/Digital Ocean Region: Defaults to us-east-1
		awsregion = "us-east-1",
		// Your AWS/Digital Ocean Domain Mapping: defaults to amazonaws.com
		awsDomain = "amazonaws.com",
		// The default delimiter for folder operations
		defaultDelimiter	= "/",
		// The default bucket name to root the operations on.
		defaultBucketName	= ""
	}
};
```

Then you can leverage the SDK CFC via the injection DSL: `AmazonS3@s3sdk`

## Usage

Please check out the api docs: https://apidocs.ortussolutions.com/#/coldbox-modules/s3sdk/

## Development

See [[dev_setup.md]].

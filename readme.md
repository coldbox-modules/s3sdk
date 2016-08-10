This SDK allows you to add Amazon S3 capabilities to your ColdFusion (CFML) applications. It is also a ColdBox Module, so if you are using ColdBox, you get auto-registration and much more.

## Resources

* Source: https://github.com/coldbox-modules/s3sdk
* Issues: https://github.com/coldbox-modules/s3sdk/issues
* [Changelog](changelog.md)
* S3 API Reference: http://docs.aws.amazon.com/AmazonS3/latest/API/Welcome.html

## Installation 
This SDK can be installed as standalone or as a ColdBox Module.  Either approach requires a simple CommandBox command:

```
box install s3sdk
```

Then follow either the standalone or module instructions below.

### Standalone

This SDK will be installed into a directory called `s3sdk` and then the SDK can be instantiated via ` new s3sdk.AmazonS3()` with the following constructor arguments:

```
<cfargument name="accessKey" 			required="true">
<cfargument name="secretKey" 			required="true">
<cfargument name="encryption_charset" 	required="false" default="utf-8">
<cfargument name="ssl" 					required="false" default="false">
```

### ColdBox Module

This package also is a ColdBox module as well.  The module can be configured by creating an `s3sdk` configuration structure in your application configuration file: `config/Coldbox.cfc` with the following settings:

```
s3sdk = {
	// Your amazon access key
	accessKey = "",
	// Your amazon secret key
	secretKey = "",
	// The default encryption character set
	encryption_charset = "utf-8",
	// SSL mode or not on cfhttp calls.
	ssl = false
};
```

Then you can leverage the SDK CFC via the injection DSL: `AmazonS3@s3sdk`

## Usage

Please check out the included API Docs to see all the methods available to you using our S3 SDK.
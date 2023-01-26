/**
 * Copyright Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This module connects your application to Amazon S3
 **/
component {

	// Module Properties
	this.title         = "Amazon S3 SDK";
	this.author        = "Ortus Solutions, Corp";
	this.webURL        = "https://www.ortussolutions.com";
	this.description   = "This SDK will provide you with Amazon S3 connectivity for any ColdFusion (CFML) application.";
	// We will map the models
	this.autoMapModels = false;

	/**
	 * Configure
	 */
	function configure(){
		// Settings
		variables.settings = {
			accessKey                  : "",
			autoContentType            : false,
			autoMD5                    : false,
			awsDomain                  : "amazonaws.com",
			awsRegion                  : "us-east-1",
			debug                      : false,
			defaultACL                 : "public-read",
			defaultBucketName          : "",
			defaultCacheControl        : "no-store, no-cache, must-revalidate",
			defaultDelimiter           : "/",
			defaultStorageClass        : "STANDARD",
			defaultTimeOut             : 300,
			encryptionCharset          : "utf-8",
			retriesOnError             : 3,
			secretKey                  : "",
			serviceName                : "s3",
			signatureType              : "V4",
			ssl                        : true,
			throwOnRequestError        : true,
			defaultEncryptionAlgorithm : "",
			defaultEncryptionKey       : ""
		};
	}

	/**
	 * Fired when the module is registered and activated.
	 */
	function onLoad(){
		binder
			.map( "AmazonS3@s3sdk" )
			.to( "#moduleMapping#.models.AmazonS3" )
			.initArg( name = "accessKey", value = variables.settings.accessKey )
			.initArg( name = "secretKey", value = variables.settings.secretKey )
			.initArg( name = "awsDomain", value = variables.settings.awsDomain )
			.initArg( name = "awsRegion", value = variables.settings.awsregion )
			.initArg( name = "encryptionCharset", value = variables.settings.encryptionCharset )
			.initArg( name = "signatureType", value = variables.settings.signatureType )
			.initArg( name = "ssl", value = variables.settings.ssl )
			.initArg( name = "defaultTimeOut", value = variables.settings.defaultTimeOut )
			.initArg( name = "defaultDelimiter", value = variables.settings.defaultDelimiter )
			.initArg( name = "defaultBucketName", value = variables.settings.defaultBucketName )
			.initArg( name = "defaultCacheControl", value = variables.settings.defaultCacheControl )
			.initArg( name = "defaultStorageClass", value = variables.settings.defaultStorageClass )
			.initArg( name = "defaultACL", value = variables.settings.defaultACL )
			.initArg( name = "throwOnRequestError", value = variables.settings.throwOnRequestError )
			.initArg( name = "autoContentType", value = variables.settings.autoContentType )
			.initArg( name = "autoMD5", value = variables.settings.autoMD5 )
			.initArg( name = "serviceName", value = variables.settings.serviceName )
			.initArg( name = "debug", value = variables.settings.debug )
			.initArg( name = "defaultEncryptionAlgorithm", value = variables.settings.defaultEncryptionAlgorithm )
			.initArg( name = "defaultEncryptionKey", value = variables.settings.defaultEncryptionKey );
		binder.map( "Sv4Util@s3sdk" ).to( "#moduleMapping#.models.AmazonS3" );

		binder.map( "Sv2Util@s3sdk" ).to( "#moduleMapping#.models.AmazonS3" );
	}




	/**
	 * Fired when the module is unregistered and unloaded
	 */
	function onUnload(){
	}

}

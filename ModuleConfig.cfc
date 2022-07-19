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
			accessKey           : "",
			secretKey           : "",
			awsDomain           : "amazonaws.com",
			awsRegion           : "us-east-1",
			encryption_charset  : "utf-8",
			signatureType       : "V4",
			ssl                 : true,
			defaultTimeOut      : 300,
			defaultDelimiter    : "/",
			defaultBucketName   : "",
			defaultCacheControl : "no-store, no-cache, must-revalidate",
			defaultStorageClass : "STANDARD",
			defaultACL          : "public-read",
			throwOnRequestError : true,
			autoContentType     : false,
			autoMD5             : false,
			serviceName         : "s3",
			debug               : false
		};
	}

	/**
	 * Fired when the module is registered and activated.
	 */
	function onLoad(){
		binder
			.map( "AmazonS3@s3sdk" )
			.to( "#moduleMapping#.models.AmazonS3" )
			.initArg(
				name  = "accessKey",
				value = variables.settings.accessKey
			)
			.initArg(
				name  = "secretKey",
				value = variables.settings.secretKey
			)
			.initArg(
				name  = "awsDomain",
				value = variables.settings.awsDomain
			)
			.initArg(
				name  = "awsRegion",
				value = variables.settings.awsregion
			)
			.initArg(
				name  = "encryption_charset",
				value = variables.settings.encryption_charset
			)
			.initArg(
				name  = "signatureType",
				value = variables.settings.signatureType
			)
			.initArg(
				name  = "ssl",
				value = variables.settings.ssl
			)
			.initArg(
				name  = "defaultTimeOut",
				value = variables.settings.defaultTimeOut
			)
			.initArg(
				name  = "defaultDelimiter",
				value = variables.settings.defaultDelimiter
			)
			.initArg(
				name  = "defaultBucketName",
				value = variables.settings.defaultBucketName
			)
			.initArg(
				name  = "defaultCacheControl",
				value = variables.settings.defaultCacheControl
			)
			.initArg(
				name  = "defaultStorageClass",
				value = variables.settings.defaultStorageClass
			)
			.initArg(
				name  = "defaultACL",
				value = variables.settings.defaultACL
			)
			.initArg(
				name  = "throwOnRequestError",
				value = variables.settings.throwOnRequestError
			)
			.initArg(
				name  = "autoContentType",
				value = variables.settings.autoContentType
			)
			.initArg(
				name  = "autoMD5",
				value = variables.settings.autoMD5
			)
			.initArg(
				name  = "serviceName",
				value = variables.settings.serviceName
			)
			.initArg(
				name  = "debug",
				value = variables.settings.debug
			);

		binder.map( "Sv4Util@s3sdk" ).to( "#moduleMapping#.models.AmazonS3" );

		binder.map( "Sv2Util@s3sdk" ).to( "#moduleMapping#.models.AmazonS3" );
	}




	/**
	 * Fired when the module is unregistered and unloaded
	 */
	function onUnload(){
	}

}

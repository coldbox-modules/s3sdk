/**
 * Copyright Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This module connects your application to Amazon S3
 **/
component {

	// Module Properties
	this.title 				= "Amazon S3 SDK";
	this.author 			= "Ortus Solutions, Corp";
	this.webURL 			= "https://www.ortussolutions.com";
	this.description 		= "This SDK will provide you with Amazon S3 connectivity for any ColdFusion (CFML) application.";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup 	= true;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = true;
	this.autoMapModels 		= false;

	/**
	 * Configure
	 */
	function configure(){
		// Settings
		settings = {
			accessKey          : "",
			secretKey          : "",
			encryption_charset : "utf-8",
			ssl                : false,
			awsregion          : "us-east-1"
		};
	}

	/**
	 * Fired when the module is registered and activated.
	 */
	function onLoad(){
		binder.map( "AmazonS3@s3sdk" )
			.to( "#moduleMapping#.AmazonS3" )
			.initArg( name="accessKey", 			value=settings.accessKey )
			.initArg( name="secretKey", 			value=settings.secretKey )
			.initArg( name="encryption_charset", 	value=settings.encryption_charset )
			.initArg( name="ssl", 					value=settings.ssl )
			.initArg( name="awsRegion", 			value=settings.awsregion );

		binder.map( "Sv4Util@s3sdk" )
			.to( "#moduleMapping#.AmazonS3" )
			.initArg( name="accessKeyId", 			value=settings.accessKey )
			.initArg( name="secretAccessKey", 		value=settings.secretKey )
			.initArg( name="defaultRegionName", 	value=settings.awsregion )
			.initArg( name="defaultServiceName",	value="s3" );
	}

	/**
	* Fired when the module is unregistered and unloaded
	*/
	function onUnload(){
	}

}
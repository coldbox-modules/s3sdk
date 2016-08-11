/**
* Copyright Ortus Solutions, Corp
* www.ortussolutions.com
* ---
* This module connects your application to Akismet
**/
component {

	// Module Properties
	this.title 				= "Amazon S3 SDK";
	this.author 			= "Ortus Solutions, Corp";
	this.webURL 			= "https://www.ortussolutions.com";
	this.description 		= "This SDK will provide you with Amazon S3 connectivity for any ColdFusion (CFML) application.";
	this.version			= "@version.number@+@build.number@";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup 	= true;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = true;
	// Module Entry Point
	this.entryPoint			= "s3sdk";
	this.autoMapModels 		= false;

	/**
	 * Configure
	 */
	function configure(){

		// Settings
		settings = {
			accessKey = "",
			secretKey = "",
			encryption_charset = "utf-8",
			ssl = false
		};
	}

	/**
	* Fired when the module is registered and activated.
	*/
	function onLoad(){
		parseParentSettings();
		var s3settings = controller.getConfigSettings().s3sdk;
		
		// Map Akismet Library
		binder.map( "AmazonS3@s3sdk" )
			.to( "#moduleMapping#.AmazonS3" )
			.initArg( name="accessKey", 			value=s3settings.accessKey )
			.initArg( name="secretKey", 			value=s3settings.secretKey )
			.initArg( name="encryption_charset", 	value=s3settings.encryption_charset )
			.initArg( name="ssl", 					value=s3settings.ssl );
	}

	/**
	* Fired when the module is unregistered and unloaded
	*/
	function onUnload(){
	}

	/**
	* parse parent settings
	*/
	private function parseParentSettings(){
		var oConfig 		= controller.getSetting( "ColdBoxConfig" );
		var configStruct 	= controller.getConfigSettings();
		var s3DSL 			= oConfig.getPropertyMixin( "s3sdk", "variables", structnew() );

		//defaults
		configStruct.s3sdk = variables.settings;

		// incorporate settings
		structAppend( configStruct.s3sdk, s3DSL, true );
	}

}
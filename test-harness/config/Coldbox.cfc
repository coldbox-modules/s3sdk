component {

	// Configure ColdBox Application
	function configure(){
		// coldbox directives
		coldbox = {
			// Application Setup
			appName                 : "Module Tester",
			// Development Settings
			reinitPassword          : "",
			handlersIndexAutoReload : true,
			modulesExternalLocation : [],
			// Implicit Events
			defaultEvent            : "",
			requestStartHandler     : "",
			requestEndHandler       : "",
			applicationStartHandler : "",
			applicationEndHandler   : "",
			sessionStartHandler     : "",
			sessionEndHandler       : "",
			missingTemplateHandler  : "",
			// Error/Exception Handling
			exceptionHandler        : "",
			onInvalidEvent          : "",
			customErrorTemplate     : "/coldbox/system/exceptions/Whoops.cfm",
			// Application Aspects
			handlerCaching          : false,
			eventCaching            : false
		};

		settings = {
			"targetEngine"   : getSystemSetting( "ENGINE", "localhost" ),
			"coldBoxVersion" : getSystemSetting( "COLDBOX_VERSION", "" )
		};

		// environment settings, create a detectEnvironment() method to detect it yourself.
		// create a function with the name of the environment so it can be executed if that environment is detected
		// the value of the environment is a list of regex patterns to match the cgi.http_host.
		environments = { development : "localhost,127\.0\.0\.1" };

		// Module Directives
		modules = {
			// An array of modules names to load, empty means all of them
			include : [],
			// An array of modules names to NOT load, empty means none
			exclude : []
		};

		// Register interceptors as an array, we need order
		interceptors = [];

		// LogBox DSL
		logBox = {
			// Define Appenders
			appenders : {
				console : { class : "coldbox.system.logging.appenders.ConsoleAppender" },
				files   : {
					class      : "coldbox.system.logging.appenders.RollingFileAppender",
					properties : { filename : "tester", filePath : "/#appMapping#/logs" }
				}
			},
			// Root Logger
			root  : { levelmax : "DEBUG", appenders : "*" },
			// Implicit Level Categories
			info  : [ "coldbox.system" ],
			debug : [ "s3sdk" ]
		};

		moduleSettings = {
			s3sdk : {
				// Settings
				accessKey         : getSystemSetting( "AWS_ACCESS_KEY" ),
				secretKey         : getSystemSetting( "AWS_ACCESS_SECRET" ),
				defaultBucketName : getSystemSetting(
					"AWS_DEFAULT_BUCKET_NAME",
					"ortus3-s3sdk-bdd-#replace( settings.targetEngine, "@", "-" )#-#reReplace(
						settings.coldBoxVersion,
						"[^a-zA-Z0-9]",
						"",
						"all"
					)#"
				),
				awsRegion : getSystemSetting( "AWS_REGION" ),
				awsDomain : getSystemSetting( "AWS_DOMAIN" ),
				ssl       : getSystemSetting( "AWS_SSL", true ),
				urlStyle  : getsystemSetting( "AWS_URLSTYLE", "path" )
			}
		};
	}

	function afterAspectsLoad( event, interceptData ){
		controller
			.getModuleService()
			.registerModule( moduleName = request.MODULE_NAME, invocationPath = "moduleroot" );
	}

}

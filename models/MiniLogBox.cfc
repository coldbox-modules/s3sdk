component {

	MiniLogBox function init( boolean debug ){
		variables.debug = arguments.debug;
		variables.logs  = [];
		return this;
	}

	boolean function canDebug(){
		return variables.debug;
	}

	function debug( required string msg, data ){
		arrayAppend( variables.logs, arguments.msg );
		if ( structKeyExists( arguments, "data" ) ) {
			arrayAppend( variables.logs, arguments.data );
		}
	}

	function error( required string msg, data ){
		arrayAppend( variables.logs, "Error: " & arguments.msg );
		if ( structKeyExists( arguments, "data" ) ) {
			arrayAppend( variables.logs, arguments.data );
		}
	}

	array function getLogs(){
		return variables.logs;
	}

}

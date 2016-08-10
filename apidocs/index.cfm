<cfparam name="url.version" default="0">
<cfparam name="url.path" 	default="#expandPath( "./S3SDK-APIDocs" )#">
<cfscript>
	docName = "S3SDK-APIDocs";
	base 	= expandPath( "/s3sdk" );
	docbox 	= new docbox.DocBox( properties = {
		projectTitle 	= "S3SDK v#url.version#",
		outputDir 		= url.path
	} );
	docbox.generate( source=base, mapping="s3sdk", excludes="(tests|apidocs|testbox)" );
</cfscript>

<!---
<cfzip action="zip" file="#expandPath('.')#/#docname#.zip" source="#expandPath( docName )#" overwrite="true" recurse="yes">
<cffile action="move" source="#expandPath('.')#/#docname#.zip" destination="#url.path#">
--->

<cfoutput>
<h1>Done!</h1>
<a href="#docName#/index.html">Go to Docs!</a>
</cfoutput>


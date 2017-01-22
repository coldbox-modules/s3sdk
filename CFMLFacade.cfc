component accessors="true"{
	// ********************************************************************************
	// Copyright 2005-2007 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
	// www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
	// ********************************************************************************

	// CFML Facade to provide function equivaliency for S3 Operations
	property name="SDK"	inject="AmazonS3@s3sdk";
	property name="S3Bucket";
	property name="BucketURL";

	public function init( required string bucketName ){
		VARIABLES.s3Bucket = ARGUMENTS.bucketName;
		VARIABLES.tmpDir = expandPath( "/includes/tmp" );
		//protocol-agnostic public URL
		VARIABLES.BucketURL = "//" & arguments.bucketName & ".s3.amazonaws.com";

		if( !directoryExists( VARIABLES.tmpDir ) ){
			directoryCreate( VARIABLES.tmpDir );
		}
		
		return this;
	}

	public query function directoryList( 
		required string path,
		filter="", 
		sort=""
	){
		ARGUMENTS.path = urlEncodedFormat( arguments.path );

		if( left( ARGUMENTS.path, 1 ) == '/' ){
			ARGUMENTS.path = right( ARGUMENTS.path, len( ARGUMENTS.path ) - 1 );
		}
		if( right( ARGUMENTS.path, 1 ) == '/' ){
			ARGUMENTS.path = left( ARGUMENTS.path, len( ARGUMENTS.path ) - 1 );
		}

		var s3Listing = SDK.getBucket( VARIABLES.s3Bucket, ARGUMENTS.path );
		
		var qDirectory = queryNew( "name,size,type,dateLastModified,attributes,mode,directory" );

		for( var item in s3Listing ){

			if( item.key != ( urlDecode( ARGUMENTS.path ) & "/" ) && item.key != ( ARGUMENTS.path & "/" ) ){
				var row = queryAddRow( qDirectory, 1 );
				var fileName = listLast( item.key, "/");
				var directory = VARIABLES.getDirectoryFromPath( item.key );
				querySetCell( qDirectory, "name", fileName, row );
				querySetCell( qDirectory, "directory", directory, row );
				querySetCell( qDirectory, "dateLastModified", parseDateTime( item.lastModified ), row );
				querySetCell( qDirectory, "type", item.isDirectory ? "Dir" : "File", row );
				querySetCell( qDirectory, "size", item.size, row );
				querySetCell( qDirectory, "attributes", item.etag, row );
			}
		}

		if( len( ARGUMENTS.filter ) ){
			var qFilter = new query();
			qFilter.setDBType( "query" );
			qFilter.setAttributes( qDirectory=qDirectory );
			var sql = "SELECT * from qDirectory WHERE name LIKE :filter";
			qFilter.addParam( "filter", replace( ARGUMENTS.filter, "*", "%", "ALL" ) );
			qDirectory = qFilter.execute( sql=sql ).getResult();

		}

		if( len( ARGUMENTS.sort ) ){
			var qSort =  new query();
			qSort.setDBType( "query" );
			qSort.setAttributes( qDirectory=qDirectory );
			qDirectory =  qSort.execute( sql="SELECT * from qDirectory ORDER BY #ARGUMENTS.sort#" )
							.getResult();
		}

		return qDirectory;

	}

	public boolean function directoryExists( path ){
		var dirName = listLast( arguments.path, "/" );
		var tlListing = VARIABLES.directoryList( VARIABLES.getDirectoryFromPath( arguments.path ) );
		var q = new query();
		q.setDBType( "query" );
		var sql = "SELECT TOP 1 * as existing from tlListing WHERE type='Dir' AND name=:dirname";
		q.addParam( name="dirname", value=dirName, cfsqltype="cf_sql_varchar" );
		q.setAttributes( tlListing=tlListing );
		var qExists = q.execute( sql=sql ).getResult();

		return javacast( "boolean", qExists.recordcount );
	}

	public string function getDirectoryFromPath( path ){
		var tlPathArray = listToArray( arguments.path, "/" );
		var dirName = tlPathArray[ arraylen( tlPathArray ) ];
		arrayDeleteAt( tlPathArray, arraylen( tlPathArray ) );
		var tlPath = arrayToList( tlPathArray, "/" );

		return tlPath;
	}

	public function directoryCreate( path ){
		SDK.putObjectFolder( VARIABLES.s3Bucket, urlEncodedFormat( ARGUMENTS.path ) & "/" );
	}

	public function directoryDelete( path, recurse=false ){
		var dirName = listLast( arguments.path, "/" );

		var dirListing = VARIABLES.directoryList( VARIABLES.getDirectoryFromPath( urlEncodedFormat( arguments.path ) ) );

		for( var row in dirListing ){
			if( row.type == "Dir" && row.name == dirName ){
				return SDK.deleteObject( VARIABLES.s3Bucket, SDK.deleteObject( VARIABLES.s3Bucket, urlEncodedFormat( row.directory ) & "/" & urlEncodedFormat( row.name ) & "/" ) ); 
			}
		}

		throw( "The directory #arguments.path# does not exist in the S3 Bucket #VARIABLES.S3Bucket#" );
	}

	public any function getFileInfo( path ){

		var bFile = fileRead( "http://" & VARIABLES.s3Bucket & ".s3.amazonaws.com/" & arguments.path );

		if( len( bFile.toString() ) && !isXML( bfile.toString() ) ){
			var S3Info = SDK.getObjectInfo( VARIABLES.s3Bucket, ARGUMENTS.path );
			return S3Info;	
		}
	}

	public function fileExists( path ){
		return !isNull( VARIABLES.getFileInfo( urlEncodedFormat( path ) ) );
	}

	public function fileRead( path ){
		return fileRead( getBucketURL() & "/" & urlEncodedFormat( arguments.path ) );
	}

	public function fileReadBinary( path ){
		return fileReadBinary( getBucketURL() & "/" & urlEncodedFormat( arguments.path ) );
	}

	public function fileWrite( fileObj ,path ){

		if( fileExists( fileObj ) ){
			fileObj = fileReadBinary( fileObj );
		}

		return SDK.putObject( VARIABLES.s3Bucket, urlEncodedFormat( arguments.path ), fileObj  );
	
	}

	public function fileSetAccessMode( path, mode ){
		var acl = SDK.ACL_PRIVATE;
		switch( right( arguments.mode.toString(), 1 ) ){
			case "7":
			case "6":
				acl = SDK.ACL_PUBLIC_READ_WRITE;
				break;
			case "5":
				acl = SDK.ACL_PUBLIC_READ;
				break;
			case "0":
				acl = SDK.ACL_AUTH_READ;
				break;
			default:
				break;
		}

		return SDK.copyObject( VARIABLES.s3Bucket, arguments.path, VARIABLES.s3Bucket, arguments.path, acl  )
	}

	public function fileMove( currentPath, targetPath ){
		return SDK.renameObject( VARIABLES.s3Bucket, urlEncodedFormat( ARGUMENTS.currentPath ), VARIABLES.s3Bucket, urlEncodedFormat( ARGUMENTS.targetPath ) );
	}

	public function fileDelete( filepath ){
		return SDK.deleteObject( VARIABLES.s3Bucket, urlEncodedFormat( arguments.filepath ) );
	}

}
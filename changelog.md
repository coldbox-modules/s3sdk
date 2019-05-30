# Changelog

## v4.5.0

* Added configurable defaults, all defaults should keep functionality exactly the same as previous verions
* Added constructor `defaultTimeout` defaults to 300
* Added constructor `defaultCacheControl` defaults to "no-store, no-cache, must-revalidate"
* Added constructor `defaultStorageClass` defaults to "STANDARD"
* Added constructor `defaultACL` defaults to "public-read"
* Added cosntructor `throwOnRequestError` defaults to "true"
* Added constructor `signature` for V2 support, defaults to V4
* Added constructor `debug` for turning debugging on/off when logbox isn't available, defaults to false
* Added constructor `autoContentType` and `contentType="auto"` to detection mime-type from filename
* Added constructor `autoMD5` and `md5="auto"` to calculation hash
* Added simple internal logger object `variables.log` when `logbox` isn't available/injected in standalone mode
* Added v2 signature hashing `generateBasicSignatureData()` this is deprecated in S3 but more compatible with other s3 compatible endpoints
* Added storage classes `S3_STANDARD`, `S3_IA`, `S3_TIERING`, `S3_ONEZONE`, `S3_GLACIER`, `S3_ARCHIVE`, `S3_RRS`, `GS_STANDARD`, `GS_MULTI`, `GS_NEARLINE`, `GS_COLDLINE`
* Added `getObject()` & `downloadObject()` methods
* Changed `copyObject()` default ACL from private to `deafultACL`


## v4.4.0

* Reworked SSL setup to allow for dynamic creation of the URL entry point
* Removed ACF11 officially, it is impossible to deal with their cfhttp junk! It works, but at your own risk.

## v4.3.0

* Removal of debugging code

## v4.2.1

* Avoid double encoding on `copy`, `putObjectFile`, and `delete()` operations
* Consolidate ssl to use `variables` instead of `arguments`

## v4.2.0

* ACF compatiblities
* Fixes for auth on folder commands
* New constructor args: `defaultDelimiter` for folder operations, `defaultBucketname` so you can set a default bucket for all bucket related operations.
* Avoid nasty error on bucket deletion
* Add new method `objectExists()` boolean check for objects
* Fix URI encoding on signatures for headers and query params

## v4.1.1

* Left some dump/aborts

## v4.1.0

* DigitalOcean Spaces compatiblity
* Region naming support, you can now pass the `awsRegion` argument to the constructor to select the AWS or DO region
* SSL is now the default for all operations
* Addition of two new constructor params: `awsRegion` and `awsDomain` to support regions and multi-domains for AWS and Digital Ocean
* Added log debugging to calls and signatures if LogBox is on `debug` level

## v4.0.1

* Fixes to models location, oopsy!

## v4.0.0

* AWS Region Support
* Migrated Module Layout to use Ortus Standard Module Layout
* Added testing for all ACF Engines
* Rework as generic Box module (compatibility change), you must move your `s3sdk` top level settings in ColdBox Config to `moduleSettings.s3sdk`
* `deleteBucket()` returns **false** if bucket doesn't exist instead of throwing an exception
* Few optimizations and documentation of the API

## v3.0.1

* Travis Updates and self-publishing

## v3.0.0

* Ugprade to ColdBox 4 standards
* Upgrade to latest Amazon S3 SDK standards
* Travis build process

## v2.0

* Original Spec as a ColdBox Plugin
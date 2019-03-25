# Changelog

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
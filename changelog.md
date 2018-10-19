# Changelog

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
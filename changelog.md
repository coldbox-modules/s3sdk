# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

----
## [Unreleased]
## v5.7.1 => 2023-SEP-21
### Fixed
* Added `entryPoint`, `modelNamespace` and `cfmapping` keys to ModuleConfig, to ensure mappings for downstream modules are available during framework load
## v5.7.0 => 2023-MAY-03
### Changed
* Updates permission handling to account for updated AWS default bucket policies
## v5.6.0 => 2023-MAR-07
### Added
* Support for overriding response headers like content type for pre-signed URLs
## v5.5.2 => 2023-FEB-07
### Fixed
* Multi-part upload concurrency fixes
## v5.5.1 => 2023-FEB-03
### Added
* Support for multi-part file uploads to conserve memory usage

## v5.4.1 => 2023-FEB-02

## v5.3.1 => 2023-FEB-02
## v5.2.0 => 2023-JAN-26
### Added
* Add support for server side encryption
* Add retry support for S3 connection failures
## v5.1.2 => 2022-OCT-19
### Added
* Added property to ensure URLEndpointHostname can be retreived
## v5.1.1 => 2022-NOV-1
### Fixed
* Fixes an issue when header content types were not present in the arguments scope

## v5.0.0 => 2022-OCT-19

### Changed / Compatibility

* Dropped Adobe 2016 Support
* Configuration setting: `encryption_charset` changed to `encryptionCharset` for consistency. **Breaking change**

### Added

* Revamp of ACLs to allow any grant to be added to any object.
* Ability to request `PUT` signed URLs so you don't have to upload to a middle server and then S3.  You can now create a signed PUT operation that you can upload directly to S3.
* Encoding of signed URLs to avoid issues with weird filenames
* Preserve content type on copy
* Ability to choose how many times to retry s3 operations when they fail with a 500 or 503. This can happen due to throttling or rate limiting.  You can configure it with the new setting: `retriesOnError` and it defaults to 3.
* New ColdBox Module template
* Add bucket name to test suite
* Github actions migration
* Avoid error logs for `objectExists()`

### Fixed

* @bdw429s Fixed tons of issues with filename encodings. :party:
* 404 is not an "error" status when verifying for errors on requests
* The argument name in `putObject()` was incorrect "arguments.content" instead of "arguments.data", this only happens when md5 == "auto" so it probably slipped by for some time.

----

## v4.8.0 => 2021-JUL-06

### Added

* Migrations to github actions
* Added new argument to `downloadObject( getAsBinary : 'no' )` so you can get binary or non binary objects. Defaults to non binary.

----

## v4.7.0 => 2021-MAR-24

### Added

* Adobe 2021 to the testing matrix and supported engines

### Fixed

* Adobe 2021 issues with date formatting
* Watcher needed to use the root `.cfformat.json`

----

## v4.6.0 => 2021-FEB-18

### Added

* New method: `setAccessControlPolicy()` so you can add ACLs to buckets
* `getBucket()` has been updated to use the ListObjectsv2 API - which is recommended by AWS for more detailed information.
* Implements SigV4-signed requests thanks to @sbleon's amazing work!
* Added more formatting rules via cfformat
* Added a `gitattributes` for cross OS compatibilities
* Added a `markdownlint.json` for more control over markdown
* Added new package script : `format:watch` to format and watch :)

### Changed

* Updated tests to fire up in ColdBox 6
* Handles some cleanup of parameters which were being passed as resource strings ( which were then being encoded and blowing up ).
* Updated release recipe to match newer modules.

### Removed

* Cleanup of old cfml engine files
* Cleanup of old init code
* Removed some settings from test harness

----
## v4.5.0 => 2020-MAR-11

* `Feature` : `SV4Util` is now a singleton for added performance and more configuration expansion by adding the sdk reference
* `Improvement` : Better error messages when s3 goes :boom:
* `Bug` : Fix for ACF double encoding

----
## v4.4.0 => 2019-MAY-15

* Reworked SSL setup to allow for dynamic creation of the URL entry point
* Removed ACF11 officially, it is impossible to deal with their cfhttp junk! It works, but at your own risk.

----
## v4.3.0 => 2019-APR-05

* Removal of debugging code

----
## v4.2.1 => 2019-MAR-26

* Avoid double encoding on `copy`, `putObjectFile`, and `delete()` operations
* Consolidate ssl to use `variables` instead of `arguments`

----
## v4.2.0 => 2019-MAR-15

* ACF compatiblities
* Fixes for auth on folder commands
* New constructor args: `defaultDelimiter` for folder operations, `defaultBucketname` so you can set a default bucket for all bucket related operations.
* Avoid nasty error on bucket deletion
* Add new method `objectExists()` boolean check for objects
* Fix URI encoding on signatures for headers and query params

----
## v4.1.1 => 2019-MAR-26

* Left some dump/aborts

----
## v4.1.0 => 2019-MAR-13

* DigitalOcean Spaces compatiblity
* Region naming support, you can now pass the `awsRegion` argument to the constructor to select the AWS or DO region
* SSL is now the default for all operations
* Addition of two new constructor params: `awsRegion` and `awsDomain` to support regions and multi-domains for AWS and Digital Ocean
* Added log debugging to calls and signatures if LogBox is on `debug` level

----
## v4.0.1 => 2018-OCT-22

* Fixes to models location, oopsy!

----
## v4.0.0 => 2018-OCT-20

* AWS Region Support
* Migrated Module Layout to use Ortus Standard Module Layout
* Added testing for all ACF Engines
* Rework as generic Box module (compatibility change), you must move your `s3sdk` top level settings in ColdBox Config to `moduleSettings.s3sdk`
* `deleteBucket()` returns **false** if bucket doesn't exist instead of throwing an exception
* Few optimizations and documentation of the API

----
## v3.0.1

* Travis Updates and self-publishing

----
## v3.0.0

* Ugprade to ColdBox 4 standards
* Upgrade to latest Amazon S3 SDK standards
* Travis build process

----
## v2.0

* Original Spec as a ColdBox Plugin

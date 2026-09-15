# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

* * *

## [Unreleased]

## [6.0.0] - 2026-09-15

### Added

- AI Skills Integration
- Native BoxLang (`boxlang@1`) server and CI matrix entry, in addition to the existing `boxlang-cfml@1` (CFML compatibility) entry

### Changed

- CI test matrix now covers `boxlang@1`, `boxlang-cfml@1`, `lucee@6` and `adobe@2023`/`adobe@2025`. Dropped `lucee@5` and `adobe@2018`/`adobe@2021` (EOL)
- Minimum ColdBox version bumped to `^8`
- `devDependencies` : removed `commandbox-dotenv` and `commandbox-cfconfig`, added `commandbox-boxlang`
- Module description updated to: "This SDK will provide you with Amazon S3 connectivity for any ColdBox, BoxLang or CFML Application."
- `readme.md` rewritten and expanded, with BoxLang as the preferred/first-class engine
- `test-harness/box.json` : `testbox` devDependency bumped from `be` to `*` to pick up TestBox's `isBoxLang()`/`isLucee()`/`isAdobe()` engine-detection helpers (and the 7.1.0 fix for `isLucee()` incorrectly returning `true` on BoxLang)
- `test-harness/tests/specs/AmazonS3Spec.cfc` : replaced ad-hoc engine checks (`structKeyExists( server, "lucee" )`, `isNull( server.lucee )`, `server.keyExists( "boxlang" )`) with TestBox's `isAdobe()`/`isLucee()`/`isBoxLang()`
- The 6 "customer encryption key" (SSE-C) specs in `AmazonS3Spec.cfc` now exercise SSE-S3 (`encryptionAlgorithm`) instead of SSE-C (`encryptionKey`), since the CI test bucket's policy blocks SSE-C uploads. The SDK's SSE-C support itself (`encryptionKey` argument) is unchanged for callers whose bucket allows it

### Fixed

- Set all `hash` usage algorithms to MD5 for Adobe change to default algorithm
- `Sv4Util.cfc`, `Sv2Util.cfc` : optional `amzDate`/`dateStamp` override arguments were checked with `structKeyExists( arguments, ... )`, which is unreliable on engines with full-null support like BoxLang (an unpassed argument still exists as a `null` key). Now checked independently with `isNull()`, fixing spurious `SignatureDoesNotMatch` errors on BoxLang
- `MiniLogBox.cfc` : same `isNull()` fix applied to the optional `data` argument on `debug()`, `error()` and `warn()`
- `Sv4Util.cfc`, `Sv2Util.cfc` : the UTC date stamp was generated with `dateFormat( utcDateTime, "yyyymmdd" )`. Lowercase `mm` is minutes, not month, on some engines. Corrected to `yyyyMMdd`
- `copyObject()` ( and therefore `renameObject()`, which calls it internally ) manually set a `Content-Length: 0` header that duplicated the header CFHTTP already sends for a bodyless request. Adobe CF and BoxLang do not de-duplicate this, sending `content-length: 0,0` on the wire and breaking AWS's `SignatureDoesNotMatch` validation. Removed the redundant header
- `server-boxlang-cfml@1.json` had leftover module aliases (`/moduleroot/cbfs`) copied from another module; corrected to `/moduleroot/s3sdk`
- `test-harness/tests/specs/AmazonS3Spec.cfc` : `isOldACF()` unconditionally read `server.coldfusion.productVersion`, which doesn't exist on native BoxLang, crashing the whole test bundle on `boxlang@1`. Now guarded with `structKeyExists( server, "coldfusion" )`
- CI : force-install the latest `commandbox-cfconfig` before starting servers, since the version bundled with the CommandBox CLI has no config provider for `adobe@2025` yet
- `Sv4UtilSpec.cfc` test fixture helpers used `.listToArray()` member-function syntax, which Adobe ColdFusion doesn't resolve the same way Lucee/BoxLang do ("The listToArray method was not found"). Switched to the top-level `listToArray( string, delimiter )` function call, which is portable across all three engines
- `putObjectFile()`'s multi-part upload path called `java.nio.file.Files.newByteChannel( path, [] )` with an untyped, empty CFML array for the varargs `OpenOption...` parameter. Explicitly `javacast( "java.nio.file.OpenOption[]", [] )` now, for safer Java interop (this alone did not fix the underlying multi-part failure on Adobe; see below)
- CI : `Setup Java` was pinned to Java 11, but Adobe ColdFusion 2025's `cfpm` tooling requires Java 17+ (`UnsupportedClassVersionError: ... class file version 61.0 ... only recognizes ... up to 55.0`). Bumped to Temurin 17
- `server-boxlang@1.json` (native BoxLang) didn't install the `bx-esapi` module, so any call to `encodeForURL()` (used by `Sv4Util.cfc`'s `urlEncodePath()`) failed with `Function [encodeForURL] not found`, crashing the entire `AmazonS3Spec` bundle at `beforeAll()`. Added `onServerInitialInstall: install bx-esapi`, matching `server-boxlang-cfml@1.json`
- `requireBucketName()`, `getBucketLocation()`, `createBucket()`, `objectExists()`, `getAuthenticatedURL()` and `applyACLHeaders()` called `throw()` without an explicit `type`. Adobe/Lucee default the type to `Application`, but BoxLang defaults it to `Custom`, breaking tests asserting `toThrow( type = "application" )`. All now throw an explicit `type = "Application"`
- `server-adobe@2023.json`/`server-adobe@2025.json` : pinned the server's own JVM to `javaVersion: openjdk21_jre`, matching the BoxLang server configs, for consistent Java 21 runtime behavior across engines
- `Sv4UtilSpec.cfc` test fixture helpers named a parameter `file`, which is treated specially on Adobe ColdFusion ("Complex object types cannot be converted to simple values" when passed into `listToArray()`). Renamed to `requestContent`
- `server-adobe@2023.json`/`server-adobe@2025.json` : added JVM arg `--add-opens java.base/sun.nio.fs=ALL-UNNAMED`, matching the working config in `coldbox-modules/cbfs`, for safer Java NIO reflection on Java 17+
- CI : replaced the separate `Ortus-Solutions/setup-commandbox` action plus manual `box install --force commandbox-boxlang`/`commandbox-cfconfig` steps with `ortus-boxlang/setup-boxlang@main` (`with-commandbox: true`, installing `commandbox-boxlang`, `commandbox-cfconfig` and `testbox-cli`), matching `coldbox-modules/cbfs`'s setup. This also fixed `adobe@2025`'s server failing to start. Also bumped `Setup Java` from 17 to 21, matching cbfs and the server JVM pins
- `putObjectFile()`'s multi-part upload path optionally routed concurrent part uploads through `variables.asyncManager.allApply()`. On Adobe, ColdBox's async `cbproxies` `Function` wrapper does not correctly marshal the `part` struct argument across the async boundary, throwing `coldfusion.runtime.UndefinedElementException: Element UPLOADID is undefined in PART` inside the closure. This was silently caught by the surrounding `try/catch` and fell back to a non-multipart upload, with no visible error ("can perform a multi-part upload on a file over 5MB" failing only with the response not containing `"multipart"`). Always use the synchronous part-upload path now, until the ColdBox/Adobe async interop issue is resolved upstream
- `AmazonS3Spec.cfc`'s multi-part upload test pre-computed the expected uploaded file size before calling `fileWrite()`, then asserted the S3 object's `Content-Length` against that pre-computed value. On `adobe@2025` the file written to disk was 1 byte larger than expected, failing the assertion. Now reads the actual on-disk size via `getFileInfo()` after writing, so the assertion is correct regardless of any engine-specific `fileWrite()` behavior

## v5.7.1 => 2023-SEP-21

### Fixed

- Added `entryPoint`, `modelNamespace` and `cfmapping` keys to ModuleConfig, to ensure mappings for downstream modules are available during framework load

## v5.7.0 => 2023-MAY-03

### Changed

- Updates permission handling to account for updated AWS default bucket policies

## v5.6.0 => 2023-MAR-07

### Added

- Support for overriding response headers like content type for pre-signed URLs

## v5.5.2 => 2023-FEB-07

### Fixed

- Multi-part upload concurrency fixes

## v5.5.1 => 2023-FEB-03

### Added

- Support for multi-part file uploads to conserve memory usage

## v5.4.1 => 2023-FEB-02

## v5.3.1 => 2023-FEB-02

## v5.2.0 => 2023-JAN-26

### Added

- Add support for server side encryption
- Add retry support for S3 connection failures

## v5.1.2 => 2022-OCT-19

### Added

- Added property to ensure URLEndpointHostname can be retreived

## v5.1.1 => 2022-NOV-1

### Fixed

- Fixes an issue when header content types were not present in the arguments scope

## v5.0.0 => 2022-OCT-19

### Changed / Compatibility

- Dropped Adobe 2016 Support
- Configuration setting: `encryption_charset` changed to `encryptionCharset` for consistency. **Breaking change**

### Added

- Revamp of ACLs to allow any grant to be added to any object.
- Ability to request `PUT` signed URLs so you don't have to upload to a middle server and then S3.  You can now create a signed PUT operation that you can upload directly to S3.
- Encoding of signed URLs to avoid issues with weird filenames
- Preserve content type on copy
- Ability to choose how many times to retry s3 operations when they fail with a 500 or 503. This can happen due to throttling or rate limiting.  You can configure it with the new setting: `retriesOnError` and it defaults to 3.
- New ColdBox Module template
- Add bucket name to test suite
- Github actions migration
- Avoid error logs for `objectExists()`

### Fixed

- @bdw429s Fixed tons of issues with filename encodings. :party:
- 404 is not an "error" status when verifying for errors on requests
- The argument name in `putObject()` was incorrect "arguments.content" instead of "arguments.data", this only happens when md5 == "auto" so it probably slipped by for some time.

* * *

## v4.8.0 => 2021-JUL-06

### Added

- Migrations to github actions
- Added new argument to `downloadObject( getAsBinary : 'no' )` so you can get binary or non binary objects. Defaults to non binary.

* * *

## v4.7.0 => 2021-MAR-24

### Added

- Adobe 2021 to the testing matrix and supported engines

### Fixed

- Adobe 2021 issues with date formatting
- Watcher needed to use the root `.cfformat.json`

* * *

## v4.6.0 => 2021-FEB-18

### Added

- New method: `setAccessControlPolicy()` so you can add ACLs to buckets
- `getBucket()` has been updated to use the ListObjectsv2 API - which is recommended by AWS for more detailed information.
- Implements SigV4-signed requests thanks to @sbleon's amazing work!
- Added more formatting rules via cfformat
- Added a `gitattributes` for cross OS compatibilities
- Added a `markdownlint.json` for more control over markdown
- Added new package script : `format:watch` to format and watch :)

### Changed

- Updated tests to fire up in ColdBox 6
- Handles some cleanup of parameters which were being passed as resource strings ( which were then being encoded and blowing up ).
- Updated release recipe to match newer modules.

### Removed

- Cleanup of old cfml engine files
- Cleanup of old init code
- Removed some settings from test harness

* * *

## v4.5.0 => 2020-MAR-11

- `Feature` : `SV4Util` is now a singleton for added performance and more configuration expansion by adding the sdk reference
- `Improvement` : Better error messages when s3 goes :boom:
- `Bug` : Fix for ACF double encoding

* * *

## v4.4.0 => 2019-MAY-15

- Reworked SSL setup to allow for dynamic creation of the URL entry point
- Removed ACF11 officially, it is impossible to deal with their cfhttp junk! It works, but at your own risk.

* * *

## v4.3.0 => 2019-APR-05

- Removal of debugging code

* * *

## v4.2.1 => 2019-MAR-26

- Avoid double encoding on `copy`, `putObjectFile`, and `delete()` operations
- Consolidate ssl to use `variables` instead of `arguments`

* * *

## v4.2.0 => 2019-MAR-15

- ACF compatiblities
- Fixes for auth on folder commands
- New constructor args: `defaultDelimiter` for folder operations, `defaultBucketname` so you can set a default bucket for all bucket related operations.
- Avoid nasty error on bucket deletion
- Add new method `objectExists()` boolean check for objects
- Fix URI encoding on signatures for headers and query params

* * *

## v4.1.1 => 2019-MAR-26

- Left some dump/aborts

* * *

## v4.1.0 => 2019-MAR-13

- DigitalOcean Spaces compatiblity
- Region naming support, you can now pass the `awsRegion` argument to the constructor to select the AWS or DO region
- SSL is now the default for all operations
- Addition of two new constructor params: `awsRegion` and `awsDomain` to support regions and multi-domains for AWS and Digital Ocean
- Added log debugging to calls and signatures if LogBox is on `debug` level

* * *

## v4.0.1 => 2018-OCT-22

- Fixes to models location, oopsy!

* * *

## v4.0.0 => 2018-OCT-20

- AWS Region Support
- Migrated Module Layout to use Ortus Standard Module Layout
- Added testing for all ACF Engines
- Rework as generic Box module (compatibility change), you must move your `s3sdk` top level settings in ColdBox Config to `moduleSettings.s3sdk`
- `deleteBucket()` returns **false** if bucket doesn't exist instead of throwing an exception
- Few optimizations and documentation of the API

* * *

## v3.0.1

- Travis Updates and self-publishing

* * *

## v3.0.0

- Ugprade to ColdBox 4 standards
- Upgrade to latest Amazon S3 SDK standards
- Travis build process

* * *

## v2.0

- Original Spec as a ColdBox Plugin

[unreleased]: https://github.com/coldbox-modules/s3sdk/compare/v6.0.0...HEAD
[6.0.0]: https://github.com/coldbox-modules/s3sdk/compare/b6db7e57c66250d3e51d035fa313190d6190219b...v6.0.0

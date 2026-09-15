# AGENTS.md

Guidance for AI coding agents (and human contributors) working in this repository.

## What this is

`s3sdk` is a ColdBox module and standalone library providing Amazon S3 connectivity for ColdBox, BoxLang and CFML applications. It also works with any S3-compatible endpoint (DigitalOcean Spaces, Google Cloud Storage, MinIO).

* `models/AmazonS3.cfc` : the main SDK entry point, all public bucket/object operations
* `models/Sv4Util.cfc` : AWS Signature Version 4 request signing (default)
* `models/Sv2Util.cfc` : AWS Signature Version 2 request signing (legacy)
* `models/MiniLogBox.cfc` : lightweight logger used when the module runs standalone, outside of LogBox
* `ModuleConfig.cfc` : ColdBox module registration
* `test-harness/` : a full ColdBox test application used to run the TestBox test suite

## AI skills

This repository has a large collection of BoxLang, ColdBox, CommandBox, DocBox and TestBox skills in `.agents/skills/`. The skills directory is ignored from version control, while `skills-lock.json` records the installed skill sources. After a fresh checkout, restore the local skills with:

```bash
npx skills experimental_install
```

When working on a task, inspect and follow the relevant skill before changing code. Do not assume that an absent `.agents/skills/` directory means the repository has no applicable guidance.

Use this quick guide to choose a starting point:

* **BoxLang syntax and code:** `boxlang-language-fundamentals`, `boxlang-best-practices`, `boxlang-classes-and-oop`, or `boxlang-functional-programming`
* **BoxLang runtime features:** the matching `boxlang-*` skill for applications, configuration, caching, files, async work, schedulers, watchers, Java integration, or web development
* **ColdBox, CommandBox, and modules:** the matching `commandbox-*` or `boxlang-core-dev-*` skill for module development, interceptors, logging, components, BIFs, and runtime internals
* **Testing:** `boxlang-testing`, `commandbox-testing`, or `bx-web-support` for web-context tests
* **Documentation:** `boxlang-code-documenter`, `boxlang-docbox`, or `bx-docbox`
* **Deployment and operations:** `boxlang-deployment`, the relevant `boxlang-runtime-*` skill, or `commandbox-deploying`
* **Security:** `boxlang-security`, `bx-esapi`, `bx-csrf`, or `bx-password-encrypt`

Prefer the most specific skill, and consult more than one when a task crosses domains.

## Supported engines

CI (`.github/workflows/tests.yml`) runs the test suite against:

* BoxLang 1+, native (`server-boxlang@1.json`)
* BoxLang 1+, CFML compatibility mode (`server-boxlang-cfml@1.json`)
* Lucee 6+ (`server-lucee@6.json`)
* Adobe ColdFusion 2023 and 2025 (`server-adobe@2023.json`, `server-adobe@2025.json`)

Each engine has real, meaningful differences an agent must account for when changing code:

* **`arguments` scope and `isNull()`** : for an optional, no-default argument that was not passed, Lucee/Adobe omit the key entirely from `arguments` (so `structKeyExists( arguments, "x" )` returns `false`), while BoxLang keeps the key present with a `null` value (so `structKeyExists()` returns `true` even though nothing was passed). Always check optional arguments independently with `isNull( arguments.x )`, never with `structKeyExists( arguments, "x" )`.
* **`dateFormat()` masks are case-sensitive** : use `MM` for month and `mm` only for minutes (in `timeFormat()`). Do not use `yyyymmdd`, use `yyyyMMdd`.
* **CFHTTP header duplication** : do not manually set a header that an engine's own `cfhttp` tag will also compute automatically (e.g. `Content-Length` on a bodyless request). Some engines do not de-duplicate this and will send both values comma-joined on the wire, which breaks AWS's request signature validation with `SignatureDoesNotMatch`.

## Testing

This SDK makes real HTTP calls against **live AWS S3** (via `S3SDK_AWS_ACCESS_KEY` / `S3SDK_AWS_ACCESS_SECRET` secrets in CI) — there is no local S3 mock in this repo's test suite. Keep that in mind when diagnosing CI failures: a failure is either a real bug in the request/signing code, a transient AWS/network issue, or a test environment problem, not a mock configuration issue.

To run tests locally:

```bash
box install
cd test-harness && box install && cd ..
box server start serverConfigFile="server-boxlang@1.json"
box testbox run
```

Set `AWS_ACCESS_KEY` / `AWS_ACCESS_SECRET` (or a `.env` file) with valid AWS credentials before running tests locally, since they exercise real S3 calls.

## Formatting

This project uses `commandbox-cfformat`. Always run before committing:

```bash
box run-script format:check
# or, to auto-fix:
box run-script format
```

CI will fail if code is not correctly formatted — do not guess at formatting, run the actual tool.

## Making changes

* Prefer fixes that work identically across all supported engines over engine-specific branches.
* When fixing a signature/signing bug, verify against AWS's own echoed-back `CanonicalRequest`/`StringToSign` in the `SignatureDoesNotMatch` error response — it shows exactly what AWS reconstructed server-side, which is the fastest way to spot a header or encoding mismatch.
* Update `changelog.md` for any user-facing fix or change, following the existing `Keep a Changelog` format.
* Do not add a CFML engine to the CI matrix without also adding its `server-*.json` config file.

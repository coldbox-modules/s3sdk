# Contributing

## Prerequisites

- [CommandBox](https://www.ortussolutions.com/products/commandbox)
- Java 21 (the CI test matrix uses Temurin 21)
- An AWS S3 bucket and credentials for the integration tests

The test suite makes real requests to S3. It does not use a local S3 mock.

## Set up the test harness

From the repository root:

```bash
cp .env.example .env
# Edit .env and set AWS_ACCESS_KEY, AWS_ACCESS_SECRET,
# AWS_REGION, AWS_DOMAIN, and AWS_DEFAULT_BUCKET_NAME.
box install
cd test-harness && box install && cd ..
```

The root `.env` file is loaded by the test harness. Do not commit it; it may
contain AWS credentials.

## Run tests

Start one of the supported engine configurations from the repository root:

```bash
box server start serverConfigFile="server-boxlang@1.json" --noSaveSettings
```

Available configurations are:

- `server-boxlang@1.json` for native BoxLang 1+
- `server-boxlang-cfml@1.json` for BoxLang 1+ in CFML compatibility mode
- `server-lucee@6.json` for Lucee 6+
- `server-adobe@2023.json` for Adobe ColdFusion 2023
- `server-adobe@2025.json` for Adobe ColdFusion 2025

Run the TestBox suite from another terminal at the repository root:

```bash
box testbox run
```

To run the suite interactively, open
`http://localhost:60299/tests/runner.cfm` in a browser. Test result files can
be written to `test-harness/tests/results` with the same options used in CI:

```bash
mkdir -p test-harness/tests/results
box testbox run --verbose outputFile=test-harness/tests/results/test-results outputFormats=json,antjunit
```

## Format and build checks

Before submitting a change, run the formatter check:

```bash
box run-script format:check
```

Use `box run-script format` to apply formatting. Module and documentation
builds are available through:

```bash
box run-script build:module
box run-script build:docs
```

## Making changes

- Keep changes compatible with native BoxLang, BoxLang CFML compatibility
  mode, Lucee, and Adobe ColdFusion where possible.
- Add or update focused TestBox coverage for behavior changes.
- Update `changelog.md` for user-facing changes.
- Do not add credentials, generated server files, or test artifacts to a
  commit.

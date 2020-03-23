# Setting up your development environment

- Clone the repository
- `cd test-harness`
- `cp .env.example .env`
- Edit .env file appropriately
- `box server start serverConfigFile="server-lucee@5.json"`
  (See `test-harness/server-*.json` for other engine options)
- Run tests:
  - In browser, visit `http://localhost:60299/tests/runner.cfm`
  - On command line: TBD

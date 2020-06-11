# Setting up your development environment

- Clone the repository
- `cd test-harness`
- `cp .env.example .env`
- Edit .env file appropriately
- `box install`
- `box run-script start` # Will use Lucee 5 server config file by default
- Run tests:
  - In browser, visit `http://localhost:60299/tests/runner.cfm`
  - On command line: `box testbox run`

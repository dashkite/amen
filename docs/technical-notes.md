# Technical Notes

### Active Targets Filtering
You can filter which tests to run by utilizing active target filters. By setting the `active` option on a test group or setting the `active` property dynamically on a test suite instance at runtime, Amen will only evaluate the tests whose `targets` match the active filters (or whose descriptions contain a matching substring). If no active filters are configured, Amen defaults to running all tests.

### Process Exit Code Handling
Whenever a test fails, Amen automatically intercepts the failure and directly mutates `process.exitCode` to `1`. This deliberate mutation guarantees that CI/CD pipelines will halt correctly without requiring you to manually wire up exit codes yourself.

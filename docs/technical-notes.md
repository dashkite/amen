# Technical Notes

### Environment Targets Filtering
You can filter which tests to run by utilizing the `targets` environment variable. By setting this variable to a space-separated list of target tags and passing a corresponding `targets` array into the `test` function's `options`, Amen will only evaluate the tests that match. If you don't specify any targets in the environment, Amen defaults to running everything.

### Process Exit Code Handling
Whenever a test fails, Amen automatically intercepts the failure and directly mutates `process.exitCode` to `1`. This deliberate mutation guarantees that CI/CD pipelines will halt correctly without requiring you to manually wire up exit codes yourself.

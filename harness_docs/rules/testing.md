# Testing Rules

Replace the commands below with the project's actual verification commands.

## Default Harness

Example:

```bash
python3 -m pytest
```

The default verification path should stay lightweight and safe for a normal
checkout.

## Test Placement

- safe automated tests should live in a predictable place
- integration tests should be explicitly marked and documented
- manual scripts should not be collected by default

## Verification Standard

- run the narrowest useful check for the changed surface
- for docs-only changes, run a docs/link check if the project has one
- if a command cannot run, report why

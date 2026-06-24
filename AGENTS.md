# AGENTS.md

## Purpose

This repository contains a reusable Terraform module for creating a GitHub Actions OIDC IAM role in AWS.

Agent work in this repo should preserve the module's public contract unless the user explicitly asks for a breaking change.

## Source Of Truth

- Prefer reading the Terraform source directly instead of restating the module contract here.
- The repo is small enough that reading `variables.tf`, `locals.tf`, `data.tf`, `main.tf`, `outputs.tf`, `examples/`, and `module.tftest.hcl` is cheap and should be the default.
- Treat the Terraform files, tests, and runnable examples as the source of truth for current behavior.
- Use this file for workflow guidance and repo conventions, not for copying details that already live in code.

## Examples And Tests

- Runnable examples live under `examples/`.
- Example directories are intended to be CI validation targets and documentation at the same time.
- Keep examples minimal and representative. Prefer adding or updating example directories over expanding large inline README snippets.
- CI should validate the root module and each example directory with `terraform init -backend=false` and `terraform validate`.
- Root behavioral coverage lives in `module.tftest.hcl`.
- Do not assume `.tftest.hcl` supports iteration. Use explicit `run` blocks.

## Documentation Rules

- Keep the README aligned with the current module contract and example directory names.
- Prefer referencing `examples/` from the README rather than duplicating many large example snippets inline.
- When renaming public values, update code, tests, CI, and docs together.

## Change Discipline

- Avoid breaking changes unless the user asks for them explicitly.
- If a requested change conflicts with this file, call out the conflict clearly.
- When a user asks for work that goes against the current guidance, suggest updating `AGENTS.md` as part of the same change so the repo contract stays accurate.
- If the repo conventions change materially, update this file in the same task.

## Known Local Caveat

- `terraform validate` is the primary local verification path.
- `terraform test` may be blocked on some local machines by an AWS provider runtime issue unrelated to module syntax. Do not mistake that provider startup failure for a configuration error without checking the actual message.

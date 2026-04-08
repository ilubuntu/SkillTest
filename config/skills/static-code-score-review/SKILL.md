---
name: static-code-score-review
description: Evaluate repaired HarmonyOS projects from a static code quality perspective based on the original project, repaired project, and patch. Focus on correctness, readability, maintainability, unnecessary complexity, risky patterns, and obvious regressions introduced by the change set.
---

# Static Code Score Review

## Overview

Use this skill to evaluate the modified project from a static code quality perspective. Focus on code correctness, readability, maintainability, unnecessary complexity, risky patterns, and obvious regressions introduced by the change set.

## Inputs

- Original project path
- Modified project path
- Patch file path

## Review Rules

- Read the patch first to understand the intended modification scope.
- Compare the original project and modified project when patch context is not enough.
- Focus on changed files first, then inspect surrounding context only when needed.
- Do not invent runtime results that are not supported by the files.
- Prefer concrete findings with file paths and reasons.

## Output Requirements

- Give a final score from 0 to 100.
- List the major code quality findings.
- Explain the scoring basis briefly and concretely.
- If no obvious quality issue is found, state that explicitly.

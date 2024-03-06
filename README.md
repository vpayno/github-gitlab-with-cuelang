# github-gitlab-with-cuelang

[![Go Workflow](https://github.com/vpayno/github-gitlab-with-cuelang/actions/workflows/go.yml/badge.svg?branch=main)](https://github.com/vpayno/github-gitlab-with-cuelang/actions/workflows/go.yml)

Experiments in using Cuelang with GitHub Workflows/Actions and GitLab Pipelines.

## Notes

- This is a runnable [Runme](https://github.com/stateful/runme) playbook.

## Dependencies

- [Cue CLI](https://github.com/cue-lang/cue)

```bash { background=false category=dependencies closeTerminalOnSuccess=false excludeFromRunAll=true interactive=true interpreter=bash name=install-dependency-cue promptEnv=true terminalRows=10 }
go install cuelang.org/go/cmd/cue@latest
```

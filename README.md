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

## JSON Schemas to Cue

Schema sources:

- [GitHub Workflow](https://json.schemastore.org/github-workflow.json)

```bash { background=false category=schema-import closeTerminalOnSuccess=false excludeFromRunAll=true interactive=true interpreter=bash name=schema-import-github promptEnv=true terminalRows=10 }
set -ex

mkdir -pv ./cue.mod/pkg/json.schemastore.org/github

cd ./cue.mod/pkg/json.schemastore.org/github

wget -c https://json.schemastore.org/github-workflow.json

cue import --verbose --force --path '#Workflow:' --package github jsonschema: ./github-workflow.json

ls
```

## Importing Workflows to Cue

This should only be run once. It's here as documentation and it was used for the original import.

```bash { background=false category=github-import closeTerminalOnSuccess=false excludeFromRunAll=true interactive=true interpreter=bash name=workflow-import-github promptEnv=true terminalRows=20 }
set -ex

if [[ -f .runme-lock-github-workflow-import ]]; then
    gum confirm "GitHub Workflows were already imported. Re-Import?" || exit
fi

cd .github/workflows/

ls

cue import -f -p workflows -l 'strings.Replace(name, " ", "", -1)' ./*.yml

ls

touch "$(git rev-parse --show-toplevel)/.runme-lock-github-workflow-import"
```

## Running `cue vet`

To validate the cue files:

```bash { background=false category=github-validate closeTerminalOnSuccess=false excludeFromRunAll=true interactive=true interpreter=bash name=workflow-vet-github promptEnv=true terminalRows=10 }
set -ex

cd .github/workflows/

ls

cue vet || { printf "\n"; cue vet -c; }
```

## Running `cue export`

To test the cue files:

```bash { background=false category=github-validate closeTerminalOnSuccess=false excludeFromRunAll=true interactive=true interpreter=bash name=workflow-test-github promptEnv=true terminalRows=10 }
set -ex

cd .github/workflows/

ls

cue export | less
```

## Running `cue trim`

To trim the exported data:

```bash { background=false category=github-trim closeTerminalOnSuccess=false excludeFromRunAll=true interactive=true interpreter=bash name=workflow-trim-github promptEnv=true terminalRows=10 }
set -ex

cd .github/workflows/

ls

cue trim

ls

git diff .
```

## Generating Workflows from Cue Data

To export the workflows run the following command:

```bash { background=false category=github-export closeTerminalOnSuccess=false excludeFromRunAll=true interactive=true interpreter=bash name=workflow-export-github promptEnv=true terminalRows=10 }
set -ex

cd .github/workflows/

ls

cue cmd genworkflows

ls

git diff .
```

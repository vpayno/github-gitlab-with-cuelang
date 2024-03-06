package workflows

CueWorkflow: {
	name: "Cue Workflow"

	on: {
		push: branches: [
			"main",
			"develop",
		]
		pull_request: types: [
			"opened",
			"synchronize",
			"reopened",
		]
	}

	env: {
		GH_HEAD_REF:                "${{ github.head_ref }}"
		REVIEWDOG_GITHUB_API_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
	}

	defaults: run: shell: "bash"

	jobs: {
		"cue-change-check": {
			name:      "Change Check"
			"runs-on": "ubuntu-latest"
			outputs: docs_changed: "${{ steps.check_file_changed.outputs.docs_changed }}"
			steps: [{
				name: "Checkout Repo"
				id:   "checkout-repo"
				uses: "actions/checkout@v3"
				with: {
					"fetch-depth": 0
					ref:           "${{ github.ref }}"
					submodules:    "recursive"
				}
			}, {
				name: "Get Change List"
				id:   "check_file_changed"
				run: """
					# Diff HEAD with the previous commit then output to stdout.
					printf \"=== Which files changed? ===\\n\"
					GIT_DIFF=\"$(git diff --name-only HEAD^ HEAD)\"
					printf \"%s\\n\" \"${GIT_DIFF}\"
					printf \"\\n\"

					# Check if the files are present in the changed file list (added, modified, deleted) then output to stdout.
					HAS_DIFF=false
					printf \"=== Which Cue, Yaml, Json files changed? ===\\n\"
					if printf \"%s\\n\" \"${GIT_DIFF}\" | grep -E '^(.*[.](cue|json|yml|yaml)|cue[.](mod|sum)|.github/workflows/cue.yml)$'; then
					  HAS_DIFF=true
					fi
					printf \"\\n\"

					# Did Cue files change?
					printf \"=== Did Cue, Yaml, Json files change? ===\\n\"
					printf \"%s\\n\" \"${HAS_DIFF}\"
					printf \"\\n\"

					# Set the output named \"docs_changed\"
					printf \"%s=%s\\n\" \"docs_changed\" \"${HAS_DIFF}\" >> \"${GITHUB_OUTPUT}\"
					"""
			}]
		}

		cue_checks: {
			name: "Cue Checks"
			strategy: matrix: os: ["ubuntu-latest"]
			"runs-on": "${{ matrix.os }}"
			outputs: checks_completed: "${{ steps.cue_checks_end.outputs.checks_completed }}"
			needs: ["cue-change-check"]
			if: "needs.cue-change-check.outputs.docs_changed == 'True'"
			steps: [{
				name: "Checkout Repo"
				id:   "checkout-repo"
				uses: "actions/checkout@v4"
				with: {
					"fetch-depth": 0
					ref:           "${{ github.ref }}"
					submodules:    "recursive"
				}
			}, {
				name: "Set up Go (using version in go.mod)"
				id:   "setup-go"
				uses: "actions/setup-go@v5"
				with: "go-version-file": "./go.mod"
			}, {
				name: "Show Go version"
				id:   "go-version"
				run:  "go version"
			}, {
				name: "Install bash 5.0 under macOS for mapfile"
				id:   "update-bash-on-macos"
				if:   "contains( matrix.os, 'macos')"
				run: """
					printf \"Before:\\n\"
					command -v bash
					bash --version | head -n 1
					printf \"\\n\"
					brew install bash
					printf \"After:\\n\"
					command -v bash
					bash --version | head -n 1
					"""
			}, {
				name: "Setup Cue"
				uses: "cue-lang/setup-cue@v1.0.1"
				id:   "setup-cue"
				with: version: "latest"
			}, {
				name: "Cue Version"
				id:   "cue-version"
				run:  "cue version"
			}, {
				name: "Setup Reviewdog"
				id:   "reviewdog-setup"
				uses: "reviewdog/action-setup@v1"
			}, {
				name: "Cue Eval"
				id:   "cue-eval"
				if:   "matrix.os == 'ubuntu-latest'"
				run: """
					{
					  printf \"### Cue Eval\\n\\n\"
					  printf '```\\n'
					  cd .github/workflows
					  cue eval
					  printf '```\\n'
					  printf \"\\n\"
					} >> \"${GITHUB_STEP_SUMMARY}\"
					"""
			}, {
				name: "Cue Vet"
				id:   "cue-vet"
				if:   "matrix.os == 'ubuntu-latest'"
				run: """
					{
					  printf \"### Cue Vet\\n\\n\"
					  printf '```\\n'
					  cd .github/workflows
					  cue vet || cue vet -c
					  printf '```\\n'
					  printf \"\\n\"
					} >> \"${GITHUB_STEP_SUMMARY}\"
					"""
			}, {
				name: "Last Cue Check"
				id:   "cue_checks_end"
				run: """
					# Set the output named \"checks_completed\"
					printf \"%s=%s\\n\" \"checks_completed\" \"true\" >> \"${GITHUB_OUTPUT}\"
					"""
			}]
		}

		"go-check-barrier": {
			name:      "go-check-barrier-job"
			"runs-on": "ubuntu-latest"
			needs: ["cue_checks"]
			if: "needs.cue_checks.outputs.checks_completed == 'True'"
			steps: [{
				name: "Do nothing step to mark this workflow as \"completed\""
				run:  "true"
			}]
		}
	}
}

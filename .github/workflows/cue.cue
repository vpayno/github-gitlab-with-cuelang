package workflows

CueWorkflow: _#myWorkflow & {
	name: "Cue Workflow"

	jobs: {
		"cue-change-check": {
			name:      "Change Check"
			"runs-on": "ubuntu-latest"
			outputs: docs_changed: "${{ steps.check_file_changed.outputs.docs_changed }}"
			steps: [
				_#usesActionCheckout,
				{
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
			steps: [
				_#usesActionCheckout,
				_#useActionSetupGo & {
					with: "go-version-file": "./go.mod"
				},
				_#showGoVersion,
				_#setupMacosInstallBash, {
					name: "Setup Cue"
					uses: "cue-lang/setup-cue@v1.0.1"
					id:   "setup-cue"
					with: version: "latest"
				}, {
					name: "Cue Version"
					id:   "cue-version"
					run:  "cue version"
				},
				_#usesActionSetupReviewdog,
				_#showReviewdogVersion,
				{
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
						  if cue vet || cue vet -c; then
						    printf "No errors\\n"
						  fi
						  printf '```\\n'
						  printf \"\\n\"
						} >> \"${GITHUB_STEP_SUMMARY}\"
						"""
				}, {
					name: "Cue Yaml Regenerate"
					id:   "cue-yaml-regenerate"
					if:   "matrix.os == 'ubuntu-latest'"
					run: """
						{
						  printf \"### Cue Yaml Regenerate\\n\\n\"
						  printf '```\\n'
						  cd .github/workflows
						  if cue cmd genworkflows; then
						    printf "No errors\\n"
						  fi
						  printf '```\\n'
						  printf \"\\n\"
						} >> \"${GITHUB_STEP_SUMMARY}\"
						"""
				}, {
					name: "Is Git Checkout Dirty?"
					id:   "cue-yaml-regenerate-dirty"
					if:   "matrix.os == 'ubuntu-latest'"
					run: """
						declare -i retval=0
						{
						  printf \"### Cue Yaml Regenerate Dirty?\\n\\n\"
						  printf '```\\n'
						  if git diff --exit-code .github/workflows; then
						    printf "git diff is clean\\n"
						  else
						    ((retval+=1))
						  fi
						  if git diff --cached --exit-code .github/workflows; then
						    printf "git diff --cached is clean\\n"
						  else
						    ((retval+=2))
						  fi
						  printf '```\\n'
						  printf \"\\n\"
						} >> \"${GITHUB_STEP_SUMMARY}\"
						exit ${retval}
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

		"cue-check-barrier": {
			name:      "cue-check-barrier-job"
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

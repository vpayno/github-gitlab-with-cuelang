package workflows

GoWorkflow: {
	name: "Go Workflow"

	on: {
		push: branches: [
			"main",
			"develop",
		]
		pull_request: types: ["opened"]
	}

	env: {
		GH_HEAD_REF:                "${{ github.head_ref }}"
		REVIEWDOG_GITHUB_API_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
	}

	defaults: run: shell: "bash"

	jobs: {
		"go-change-check": {
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
					printf \"=== Which Golang files changed? ===\\n\"
					if printf \"%s\\n\" \"${GIT_DIFF}\" | grep -E '^(.*[.]go|go[.](mod|sum)|.github/workflows/go.yml)$'; then
					  HAS_DIFF=true
					fi
					printf \"\\n\"

					# Did Golang files change?
					printf \"=== Did Golang files change? ===\\n\"
					printf \"%s\\n\" \"${HAS_DIFF}\"
					printf \"\\n\"

					# Set the output named \"docs_changed\"
					printf \"%s=%s\\n\" \"docs_changed\" \"${HAS_DIFF}\" >> \"${GITHUB_OUTPUT}\"
					"""
			}]
		}

		go_checks: {
			name: "Go Checks"
			strategy: matrix: os: ["ubuntu-latest"]
			"runs-on": "${{ matrix.os }}"
			outputs: checks_completed: "${{ steps.go_checks_end.outputs.checks_completed }}"
			needs: ["go-change-check"]
			if: "needs.go-change-check.outputs.docs_changed == 'True'"
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
				name: "Setup Reviewdog"
				id:   "reviewdog-setup"
				uses: "reviewdog/action-setup@v1"
			}, {
				name: "Reviewdog Version"
				id:   "reviewdog-version"
				run:  "reviewdog -version"
			}, {
				name: "Checkout PR Branch"
				id:   "checkout-pr-branch"
				run: """
					if ! git branch --show-current | grep -q -E '^(main|develop)$'; then
					  git status
					  git fetch origin \"${GH_HEAD_REF}\"
					  git switch \"${GH_HEAD_REF}\"
					  git status
					fi
					"""
			}, {
				name: "Run go generate"
				id:   "go-generate"
				run:  "go generate ./..."
			}, {
				name: "Testing with revive"
				id:   "go-test-revive"
				if:   "matrix.os == 'ubuntu-latest'"
				run: """
					go install github.com/mgechev/revive@latest || go install github.com/mgechev/revive@master
					revive ./... | reviewdog -tee -efm=\"%f:%l:%c: %m\" -name=\"revive\" -reporter=github-check
					"""
			}, {
				name: "Analyzing the code with go vet"
				id:   "go-vet"
				if:   "matrix.os == 'ubuntu-latest'"
				run:  "go vet ./... | reviewdog -tee -f govet -reporter=github-check"
			}, {
				name: "Testing with gosec"
				id:   "go-test-security"
				if:   "matrix.os == 'ubuntu-latest'"
				run: """
					go install github.com/securego/gosec/v2/cmd/gosec@latest
					gosec ./... | reviewdog -tee -f gosec -reporter=github-check
					"""
			}, {
				name: "Testing with go test"
				id:   "go-test-run"
				run: """
					# go install github.com/rakyll/gotest@latest
					go install golang.org/x/tools/cmd/cover@latest
					mkdir -pv ./reports
					{
					  printf \"### Code Test Summary\\n\\n\"
					  printf '```\\n'
					  # shellcheck disable=SC2046
					  go test -v -covermode=count -coverprofile=./reports/.coverage.out $(go list ./... | grep -v /ci/)
					  printf '```\\n'
					  printf \"\\n\"
					} | tee -a \"${GITHUB_STEP_SUMMARY}\"
					"""
			}, {
				name: "Generate coverage.xml"
				id:   "go-generate-coverage-xml"
				if:   "matrix.os == 'ubuntu-latest'"
				run: """
					go install github.com/t-yuki/gocover-cobertura@latest
					gocover-cobertura < ./reports/.coverage.out > ./reports/coverage.xml
					wc ./reports/coverage.xml
					"""
			}, {
				name: "Test Coverage Report (txt)"
				id:   "go-test-coverage-txt"
				if:   "matrix.os == 'ubuntu-latest'"
				run:  "go tool cover -func=./reports/.coverage.out | tee reports/coverage.txt"
			}, {
				name: "Test Coverage Report (html)"
				id:   "go-test-coverage-html"
				run:  "go tool cover -html=./reports/.coverage.out -o=reports/coverage.html"
			}, {
				name: "Show Missing Coverage"
				id:   "go-test-coverage-annotate"
				run: """
					go install github.com/axw/gocov/gocov@latest
					gocov convert ./reports/.coverage.out | gocov annotate -ceiling=100 -color - | tee reports/coverage-annotations.txt
					"""
			}, {
				name: "gocov Coverage Report"
				id:   "go-test-coverage-report"
				run:  "gocov convert ./reports/.coverage.out | gocov report | tee reports/coverage-summary.txt"
			}, {
				name: "Action Summary"
				id:   "gh-action-summary"
				if:   "matrix.os == 'ubuntu-latest'"
				run: """
					{
					  printf \"### Code Coverage Summary\\n\\n\"
					  printf '```\\n'
					  cat reports/coverage-summary.txt
					  printf '```\\n'
					  printf \"\\n\"
					} >> \"${GITHUB_STEP_SUMMARY}\"
					{
					  printf \"### Code Coverage Annotations\\n\\n\"
					  printf '```\\n'
					  cat reports/coverage-annotations.txt
					  printf '```\\n'
					  printf \"\\n\"
					} >> \"${GITHUB_STEP_SUMMARY}\"
					"""
			}, {
				name: "Last Go Check"
				id:   "go_checks_end"
				run: """
					# Set the output named \"checks_completed\"
					printf \"%s=%s\\n\" \"checks_completed\" \"true\" >> \"${GITHUB_OUTPUT}\"
					"""
			}]
		}

		"go-check-barrier": {
			name:      "go-check-barrier-job"
			"runs-on": "ubuntu-latest"
			needs: ["go_checks"]
			if: "needs.go_checks.outputs.checks_completed == 'True'"
			steps: [{
				name: "Do nothing step to mark this workflow as \"completed\""
				run:  "true"
			}]
		}
	}
}

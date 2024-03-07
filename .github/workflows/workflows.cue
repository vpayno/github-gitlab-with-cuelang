// Adapted from Cue Demo: https://github.com/cue-examples/github-actions-example/blob/main/.github/workflows/workflows.cue
package workflows

import "json.schemastore.org/github"

workflows: [...{
	filename: string
	name:     github.#Workflow
}]

// TODO: drop when cuelang.org/issue/390 is fixed.
// https://github.com/cue-lang/cue/issues/390
// Declare definitions for sub-schemas so we can refer to them.
_#job:  ((github.#Workflow & {}).jobs & {x: _}).x
_#step: ((_#job & {steps:                   _}).steps & [_])[0]

workflows: [
	{
		filename: "cue.yml"
		name:     CueWorkflow
	},
	{
		filename: "go.yml"
		name:     GoWorkflow
	},
]
_#myWorkflow: github.#Workflow & {
	defaults: run: shell: "bash"

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
}

_#usesActionCheckout: _#step & {
	name: "Checkout Repo"
	id:   "checkout-repo"
	uses: "actions/checkout@v4"
	with: {
		"fetch-depth": 0
		ref:           "${{ github.ref }}"
		submodules:    "recursive"
	}
}

_#setupMacosInstallBash: _#step & {
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
}

_#useActionSetupGo: _#step & {
	name: "Set up Go (using version in go.mod)"
	id:   "setup-go"
	uses: "actions/setup-go@v5"
	with: "go-version-file": string
}

_#showGoVersion: _#step & {
	name: "Show Go version"
	id:   "go-version"
	run:  "go version"
}

_#usesActionSetupReviewdog: _#step & {
	name: "Setup Reviewdog"
	id:   "reviewdog-setup"
	uses: "reviewdog/action-setup@v1"
}

_#showReviewdogVersion: _#step & {
	name: "Show Reviewdog version"
	id:   "reviewdog-version"
	run:  "reviewdog -version"
}

// Adapted from Cue Demo: https://github.com/cue-examples/github-actions-example/blob/main/.github/workflows/workflows.cue
package workflows

import "json.schemastore.org/github"

workflows: [...{
	filename: string
	name:     github.#Workflow
}]

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

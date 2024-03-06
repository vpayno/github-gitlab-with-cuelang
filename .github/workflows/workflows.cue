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

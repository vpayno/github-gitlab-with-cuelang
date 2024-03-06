// Adapted from Cue Demo: https://github.com/cue-examples/github-actions-example/blob/main/.github/workflows/workflows.cue
package workflows

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

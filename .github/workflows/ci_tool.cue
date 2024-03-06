// ci_tool.cue is from a Cue demo: https://github.com/cue-examples/github-actions-example/blob/main/.github/workflows/ci_tool.cue
package workflows

import (
	"tool/file"
	"encoding/yaml"
)

command: genworkflows: {
	for w in workflows {
		"\(w.filename)": file.Create & {
			filename: w.filename
			contents: yaml.Marshal(w.name)
		}
	}
}

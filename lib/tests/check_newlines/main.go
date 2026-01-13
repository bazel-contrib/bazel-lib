package main

import (
	"bytes"
	"fmt"
	"os"
	"runtime"

	"github.com/bazelbuild/rules_go/go/runfiles"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintln(os.Stderr, "Usage: check_newlines <script>")
		os.Exit(1)
	}

	r, err := runfiles.New()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to initialize runfiles: %v\n", err)
		os.Exit(1)
	}

	script, err := r.Rlocation(os.Args[1])
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to locate %s in runfiles: %v\n", os.Args[1], err)
		os.Exit(1)
	}

	content, err := os.ReadFile(script)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to read %s: %v\n", script, err)
		os.Exit(1)
	}

	cr := bytes.Count(content, []byte("\r"))
	lf := bytes.Count(content, []byte("\n"))
	crlf := bytes.Count(content, []byte("\r\n"))
	if runtime.GOOS == "windows" {
		if cr != lf || cr != crlf {
			fmt.Fprintf(os.Stderr, "%s contains non-Windows line endings (\\r=%d, \\n=%d, \\r\\n=%d)\n", script, cr, lf, crlf)
			os.Exit(1)
		}
	} else if cr > 0 {
		fmt.Fprintf(os.Stderr, "%s contains Windows line endings (\\r=%d, \\n=%d, \\r\\n=%d)\n", script, cr, lf, crlf)
		os.Exit(1)
	}
}

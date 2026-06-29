package main

import "testing"

func TestParseArgs(t *testing.T) {
	cases := []struct {
		name    string
		args    []string
		want    options
		wantCmd []string
		wantErr bool
	}{
		{
			name:    "no flags",
			args:    []string{"--", "tool", "a", "b"},
			wantCmd: []string{"tool", "a", "b"},
		},
		{
			name:    "space-separated values",
			args:    []string{"--stdout", "o", "--stderr", "e", "--exit-code-out", "c", "--chdir", "d", "--silent-on-success", "--", "tool"},
			want:    options{stdoutPath: "o", stderrPath: "e", exitCodePath: "c", chdir: "d", silentOnSuccess: true},
			wantCmd: []string{"tool"},
		},
		{
			name:    "equals-separated values",
			args:    []string{"--stdout=o", "--chdir=d", "--", "tool", "--stdout=passed-through"},
			want:    options{stdoutPath: "o", chdir: "d"},
			wantCmd: []string{"tool", "--stdout=passed-through"},
		},
		{
			name:    "missing separator",
			args:    []string{"--stdout", "o"},
			wantErr: true,
		},
		{
			name:    "missing value",
			args:    []string{"--stdout"},
			wantErr: true,
		},
		{
			name:    "unknown flag",
			args:    []string{"--nope", "--", "tool"},
			wantErr: true,
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			opts, cmd, err := parseArgs(tc.args)
			if tc.wantErr {
				if err == nil {
					t.Fatalf("parseArgs(%v) = nil error, want error", tc.args)
				}
				return
			}
			if err != nil {
				t.Fatalf("parseArgs(%v) unexpected error: %v", tc.args, err)
			}
			if opts != tc.want {
				t.Errorf("options = %+v, want %+v", opts, tc.want)
			}
			if len(cmd) != len(tc.wantCmd) {
				t.Fatalf("cmd = %v, want %v", cmd, tc.wantCmd)
			}
			for i := range cmd {
				if cmd[i] != tc.wantCmd[i] {
					t.Fatalf("cmd = %v, want %v", cmd, tc.wantCmd)
				}
			}
		})
	}
}

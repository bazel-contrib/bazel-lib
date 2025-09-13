//go:build !(darwin || linux)

package common

func CloneFile(src, dst string) error {
	return ErrUnsupported
}

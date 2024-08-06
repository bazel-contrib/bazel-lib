//go:build !darwin

package common

func cloneFile(src, dst string) (supported bool, err error) {
	return false, nil
}

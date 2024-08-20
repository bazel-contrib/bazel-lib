bats_load_library 'bats-support'
bats_load_library 'bats-assert'

@test 'env' {
	run echo $USE_BAZEL_VERSION
	assert_output 'latest'
}

bats_load_library 'bats-support'
bats_load_library 'bats-assert'

@test 'assert_output() check for existence' {
	run echo 'have'
	assert_output 'have'
}

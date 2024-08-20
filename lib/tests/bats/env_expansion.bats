bats_load_library 'bats-support'
bats_load_library 'bats-assert'
bats_load_library 'bats-file'

@test 'env expansion' {
	run echo $DATA_PATH
	assert_output 'lib/tests/bats/data.bin'
	assert_file_exists 'lib/tests/bats/data.bin'
}

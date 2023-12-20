bats_load_library 'bats-support'
bats_load_library 'bats-assert'
bats_load_library 'bats-custom'

@test 'env' {
    custom_test_fn
}


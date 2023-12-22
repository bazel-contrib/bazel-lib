bats_load_library 'bats-support'
bats_load_library 'bats-assert'
bats_load_library 'bats-custom'

@test 'env' {
    run custom_test_fn
}


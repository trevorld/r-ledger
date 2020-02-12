test_that("to_numeric works", {
    expect_equal(to_numeric("2,000,000.00"), 2000000.0)
    expect_equal(to_numeric("2 000 000,00"), 2000000.0)
    expect_equal(to_numeric("2 000 000.00"), 2000000.0)
    expect_equal(to_numeric("2.000.000,00"), 2000000.0)
    expect_equal(to_numeric("20.0"), 20.0)
})

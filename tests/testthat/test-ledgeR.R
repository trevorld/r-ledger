# Copyright 2018 Trevor L Davis <trevor.l.davis@gmail.com>

files <- paste0("example.", c("ledger", "hledger", "beancount"))
files <- system.file("extdata", files, package = "ledgeR")
binaries <- c("ledger", "hledger", "bean-report")

for (ii in 1:length(binaries)) {
    binary <- binaries[ii]
    test_that(paste(binary, "register works as expected"), {
        file <- files[ii]
        if(!.is_binary_on_path(binary)) {
            throws_error(register(file))
            skip(paste(binary, "not on path"))
        }
        df <- register(file)
        expect_equal(sum(dplyr::filter(df, account == "Expenses:Taxes:Federal")$amount), 82.55)
        expect_equal(unique(dplyr::filter(df, description == "Federal Income Tax Withholding")$mark), "*")
        expect_equal(dplyr::filter(df, description == "Deposit to Checking Account", account == "Assets:JT-Checking")$mark, "!")
        expect_equal(dplyr::filter(df, account == "Assets:JT-Brokerage")$amount, 4)
        expect_equal(dplyr::filter(df, account == "Assets:JT-Brokerage")$historical_cost, 1000)
        if (binary != "ledger") {
            expect_equal(dplyr::filter(df, account == "Assets:JT-Brokerage")$market_value, 2000)
            df <- register(file, flags="tag:Tag=#restaurant")
            expect_equal(dplyr::filter(df, account == "Expenses:Food:Restaurant")$amount, 20.07)
            # df <- register(file, flags="tag:Link=\\^grocery")
            # expect_equal(dplyr::filter(df, account == "Expenses:Food:Restaurant")$amount, 500.54)
        } else {
            expect_equal(dplyr::filter(df, account == "Assets:JT-Brokerage")$market_value, NULL)
            throws_error(register(file, flags="tag:Tag=#restaurant"))
            throws_error(register(file, flags="tag:Link=^grocery"))
        }
        if (exists('import', where=asNamespace('rio'), mode='function')) {
            df <- rio::import(file)
            expect_equal(sum(dplyr::filter(df, account == "Expenses:Taxes:Federal")$amount), 82.55)
        }
    })
}

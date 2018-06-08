# Copyright 2018 Trevor L Davis <trevor.l.davis@gmail.com>

files <- paste0("example.", c("ledger", "hledger", "beancount"))
files <- system.file("extdata", files, package = "ledgeR")
empty_files <- paste0("empty.", c("ledger", "hledger", "beancount"))
empty_files <- system.file("extdata", empty_files, package = "ledgeR")
binaries <- c("ledger", "hledger", "bean-report")

for (ii in 1:length(binaries)) {
    binary <- binaries[ii]
    test_that(paste(binary, "register works as expected"), {
        file <- files[ii]
        empty_file <- empty_files[ii]
        if(!.is_binary_on_path(binary)) {
            expect_error(register(file))
            skip(paste(binary, "not on path"))
        }
        df <- register(file)
        expect_equal(sum(dplyr::filter(df, account == "Expenses:Taxes:Federal")$amount), 3*82.55)
        expect_equal(unique(dplyr::filter(df, description == "Federal Income Tax Withholding")$mark), "*")
        mark <- dplyr::filter(df, date == "2018-01-05", description == "Deposit to Checking Account",
                              account == "Assets:JT-Checking")$mark
        expect_equal(mark, "!")
        investment <- dplyr::filter(df, account == "Assets:JT-Brokerage")
        expect_equal(investment$amount, 4)
        expect_equal(net_worth(file)$net_worth, 8125.39)
        expect_equal(net_worth(file, c("2016-01-01", "2017-01-01", "2018-01-01"))$net_worth,
                     c(5000, 4361.39, 6743.39))
        if (binary != "ledger") {
            expect_equal(investment$historical_cost, 1000)
            expect_equal(investment$market_value, 2000)
            df <- register(file, flags="tag:Tag=#restaurant")
            expect_equal(dplyr::filter(df, account == "Expenses:Food:Restaurant")$amount, 20.07)
            # df <- register(file, flags="tag:Link=\\^grocery")
            # expect_equal(dplyr::filter(df, account == "Expenses:Food:Restaurant")$amount, 500.54)
            df <- register(empty_file)
            expect_equal(nrow(df), 0)
        } else {
            expect_equal(dplyr::filter(df, account == "Assets:JT-Brokerage")$market_value, NULL)
            expect_error(register(file, flags="tag:Tag=#restaurant"))
            expect_error(register(file, flags="tag:Link=^grocery"))
            expect_error(register(empty_file))
        }
        if (exists('import', where=asNamespace('rio'), mode='function')) {
            df <- rio::import(file)
            expect_equal(sum(dplyr::filter(df, account == "Expenses:Taxes:Federal")$amount), 3*82.55)
        }
        if (binary == "bean-report") {
            skip_on_cran()
            example_beancount_file <- tempfile(fileext = ".beancount")
            on.exit(unlink(example_beancount_file))
            system(paste("bean-example -o", example_beancount_file), ignore.stderr=TRUE)
            expect_error(net_worth(example_beancount_file), "Non-unique market value commodity")
        }
    })
}

test_that(".assert_binary works as expected", {
    expect_error(.assert_binary("does-not-exist"), "does-not-exist not found on path")
})
test_that("register works as expected", {
    expect_error(register("test.docx"), "File extension docx is not supported")
})

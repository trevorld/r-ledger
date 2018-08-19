# Copyright 2018 Trevor L Davis <trevor.l.davis@gmail.com>

lfile <- system.file("extdata", "example.ledger", package = "ledger")
hfile <- system.file("extdata", "example.hledger", package = "ledger")
bfile <- system.file("extdata", "example.beancount", package = "ledger")
lefile <- system.file("extdata", "empty.ledger", package = "ledger")
hefile <- system.file("extdata", "empty.hledger", package = "ledger")
befile <- system.file("extdata", "empty.beancount", package = "ledger")
df_file <- data.frame(file = c(rep(c(lfile, hfile, bfile), each=2)),
                      efile = c(rep(c(lefile, hefile, befile), each=2)),
                      toolchain = c(rep(c("ledger", "hledger"), 2),
                                    "bean-report_ledger", "bean-report_hledger"),
                      stringsAsFactors=FALSE)

context("Various assertions work as expected")
test_that(".assert_toolchain works as expected", {
    expect_error(.assert_toolchain("does-not-exist"), "does-not-exist binaries not found on path")
})
test_that("default_toolchain works as expected", {
    expect_error(ledger::register("test.docx"), "Couldn't find an acceptable toolchain for docx")
})
test_that("register works as expected", {
    expect_error(ledger::register("test.docx", toolchain="docx"), "docx binaries not found on path")
    if(.is_toolchain_supported("ledger"))
        expect_error(ledger::register("test.docx", toolchain="ledger"), "ledger had an import error")
})
test_that("default_toolchain works as expected", {
    if(.is_toolchain_supported("ledger"))
        expect_equal(default_toolchain("test.ledger"), "ledger")
    if(.is_toolchain_supported("hledger"))
        expect_equal(default_toolchain("test.hledger"), "hledger")
    if(.is_toolchain_supported("bean-report_hledger"))
        expect_equal(default_toolchain("test.beancount"), "bean-report_hledger")
})

skip_toolchain <- function(file, toolchain) {
    if(!.is_toolchain_supported(toolchain)) {
        expect_error(ledger::register(file, toolchain=toolchain))
        skip(paste(toolchain, "binaries not found"))
    }
}

skip_hledger <- function(file, toolchain) {
    ext <- tools::file_ext(file)
    if (ext == "ledger" && toolchain == "hledger") {
        # expect_error(ledger::register(file))
        skip("hledger sometimes can't read in example.ledger")
    }
}

for (ii in 1:nrow(df_file)) {
    toolchain <- df_file$toolchain[ii]
    file <- df_file$file[ii]
    empty_file <- df_file$efile[ii]
    context(paste(file, toolchain, "works as expected"))
    register <- function(...) { ledger::register(..., toolchain=toolchain) }
    net_worth <- function(...) { ledger::net_worth(..., toolchain=toolchain) }

    test_that(paste("register works as expected on", basename(file), "using", toolchain), {
        skip_toolchain(file, toolchain)
        skip_hledger(file, toolchain)

        df <- register(file)
        expect_equal(sum(dplyr::filter(df, account == "Expenses:Taxes:Federal")$amount), 3*82.55)

        mark <- unique(dplyr::filter(df, description == "Federal Income Tax Withholding")$mark)
        expect_equal(mark, "*")
        mark <- dplyr::filter(df, date == "2018-01-05", description == "Deposit to Checking Account",
                              account == "Assets:JT-Checking")$mark
        expect_equal(mark, "!")

        investment <- dplyr::filter(df, account == "Assets:JT-Brokerage")
        expect_equal(investment$amount, 4)

        if (exists('import', where=asNamespace('rio'), mode='function')) {
            df2 <- rio::import(file, toolchain=toolchain)
            ftax_sum <- sum(dplyr::filter(df2, account == "Expenses:Taxes:Federal")$amount)
            expect_equal(ftax_sum, 3*82.55)
            expect_equal(df, df2)
        }

        if (! toolchain %in% c("ledger", "bean-report_ledger")) {
            expect_equal(investment$historical_cost, 1000)
            expect_equal(investment$market_value, 2000)
            df <- register(file, flags="tag:Tag=#restaurant")
            expect_equal(dplyr::filter(df, account == "Expenses:Food:Restaurant")$amount, 20.07)
            # df <- register(file, flags="tag:Link=\\^grocery")
            # expect_equal(dplyr::filter(df, account == "Expenses:Food:Restaurant")$amount, 500.54)
        } else {
            expect_equal(dplyr::filter(df, account == "Assets:JT-Brokerage")$market_value, NULL)
            expect_error(register(file, flags="tag:Tag=#restaurant"))
            expect_error(register(file, flags="tag:Link=^grocery"))
        }
    })

    test_that(paste("net_worth works as expected on", basename(file), "using", toolchain), {
        skip_toolchain(file, toolchain)
        skip_hledger(file, toolchain)

        if(!.is_toolchain_supported(toolchain)) {
            expect_error(register(file))
            skip(paste(toolchain, "not supported"))
        }
        expect_equal(net_worth(file)$net_worth, 8125.39)
        expect_equal(net_worth(file, include=".*", exclude=c("^Equity", "^Income", "^Expenses"))$net_worth, 8125.39)
        expect_equal(net_worth(file, c("2016-01-01", "2017-01-01", "2018-01-01"))$net_worth,
                     c(5000, 4361.39, 6743.39))
    })

    test_that(paste("register works as expected on", basename(file), "using", toolchain), {
        skip_toolchain(file, toolchain)

        if (! toolchain %in% c("ledger", "bean-report_ledger")) {
            df <- register(empty_file)
            expect_equal(nrow(df), 0)
        } else {
            expect_error(register(empty_file))
        }
    })
}

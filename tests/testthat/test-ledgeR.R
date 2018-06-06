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
        if (exists('import', where=asNamespace('rio'), mode='function')) {
            df <- rio::import(file)
            expect_equal(sum(dplyr::filter(df, account == "Expenses:Taxes:Federal")$amount), 82.55)
        }

    })
}

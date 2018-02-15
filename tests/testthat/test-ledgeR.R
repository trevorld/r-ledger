# Copyright 2018 Trevor L Davis <trevor.l.davis@gmail.com>

context("Testing reading ledger register works")
test_that("register works as expected", {
    skip_if_not(any(Sys.which("ledger") != ""), "ledger not on path")
    register(system.file("extdata", "example.ledger", package = "ledgeR"))
})

context("Testing reading hledger register works")
test_that("register works as expected", {
    skip_if_not(any(Sys.which("hledger") != ""), "hledger not on path")
    register(system.file("extdata", "example.hledger", package = "ledgeR"))
})

context("Testing reading beancount register works")
test_that("register works as expected", {
    skip_if_not(any(Sys.which("bean-report") != ""), "bean-report not on path")
    register(system.file("extdata", "example.beancount", package = "ledgeR"))
})

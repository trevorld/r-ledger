context("prune_coa works as expected")

library("dplyr")
filter <- dplyr::filter
test_that("prune_coa works as expected", {
    string <- c("A:B:C:D:E", "A", "A:B")
    expect_equal(prune_coa_string(string), rep("A", 3))
    expect_equal(prune_coa_string(string, 2), c("A:B", "A", "A:B"))
    expect_equal(prune_coa_string(string, 3), c("A:B:C", "A", "A:B"))

    df <- tibble::tribble(~account, ~amount,
                          "Assets:Checking:BankA", 1000,
                          "Assets:Checking:BankB", 1000,
                          "Assets:Savings:BankA", 1000,
                          "Assets:Savings:BankC", 1000)

    sum_amount <- function(df, account_string) {
        sum(filter(df, account == account_string)$amount)
    }

    expect_equal(prune_coa(df) %>% sum_amount("Assets"), 4000)
    expect_equal(prune_coa(df) %>% sum_amount("Assets:Checking"), 0)
    expect_equal(prune_coa(df, 2) %>% sum_amount("Assets:Checking"), 2000)
    expect_equal(prune_coa(df, 2, account, account) %>% sum_amount("Assets:Checking"), 2000)
    expect_equal(prune_coa(df, 2) %>% sum_amount("Assets:Savings:BankA"), 0)
    expect_equal(prune_coa(df, 3) %>% sum_amount("Assets:Savings:BankA"), 1000)
    expect_equal(prune_coa(df, 3) %>% sum_amount("Assets:Savings:BankA"), 1000)
    expect_equal(prune_coa(df, 4) %>% sum_amount("Assets:Savings:BankA"), 1000)
})

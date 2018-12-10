#' Prune plaintext "Chart of Accounts" names to a given maximum depth
#'
#' \code{prune_coa} is a convenience function that modifies a data frame
#'  by either editing in place or making 
#'   a new variable containing the plaintext "Chart of Accounts" pruned to a given maximum depth
#'  e.g. "Assets:Checking:Credit-Union:Account1" at a maximum depth of 2 will be converted to "Assets:Checking".
#' \code{prune_coa} uses tidyverse non-standard evaluation (NSE).
#' \code{prune_coa_string} is a convenience function which does the pruning operation on character vectors.
#'
#' @param df A data frame
#' @param depth How deep should the account structure be.
#' @param variable Which variable to make less deep (default is to use "account")
#' @param name New variable name (default is to edit the variable argument in place)
#'
#' @examples
#' df <- tibble::tribble(~account, ~amount,
#'                      "Assets:Checking:BankA", 1000,
#'                      "Assets:Checking:BankB", 1000,
#'                      "Assets:Savings:BankA", 1000,
#'                      "Assets:Savings:BankC", 1000)
#' prune_coa(df)
#' prune_coa(df, 2)
#' prune_coa(df, 3)
#' prune_coa(df, 4)
#' prune_coa(df, 2, account, account2)
#' prune_coa(prune_coa(df, 2, account, account2), 3, account2, account3)
#' prune_coa_string(df$account, 2)
#' 
#' @importFrom rlang :=
#' @importFrom rlang sym
#' @importFrom rlang enquo
#' @export
prune_coa <- function(df, depth=1, variable, name) {
    if (missing(variable))
        variable <- sym("account")
    else
        variable <- enquo(variable)
    if (missing(name))
        name <- variable
    else
        name <- enquo(name)
    mutate(df, !!name := prune_coa_string(!!variable, depth=depth))
}

#' @rdname prune_coa
#' @param x Character vector
#' @importFrom stringr str_split
#' @export
prune_coa_string <- function(x, depth=1) {
    mm <- str_split(x, pattern=":", simplify=TRUE)
    mm <- mm[, 1:min(depth, ncol(mm)), drop=FALSE]
    rr <- apply(mm, 1, function(x) paste(x, collapse=":"))
    gsub(":+$", "", rr)
}


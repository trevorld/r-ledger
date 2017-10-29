globalVariables(c("description", "amount", "payee", "account", "commodity"))

#' Import a hledger or beancount register
#'
#' \code{register} imports the register from an hledger or beancount file 
#' as a data frame.  ledger files can work if compatible with hledger.
#' 
#' @param file Filename for an hledger or beancount file.
#'     ledger files that are compatible with hledger should work.
#' @param include_cleared Include cleared transactions
#' @param include_pending Include pending transactions
#' @param include_unmarked Include unmarked transactions 
#'        (effectively ignored for beancount files)
#' @param convert_to_cost  Convert transactions to their cost
#' @param convert_to_market_value  Convert transactions to their market value
#' @param tags Character vector of tags to filter.  
#'     Beancount tags include initial \code{#} and links include initial \code{^}.
#'     If \code{NULL} (the default) don't filter based on any tags.
#' @return  \code{register} returns a data frame.
#'    
#' @import dplyr
#' @importFrom utils read.csv
#' @export
#' @examples
#'    \dontrun{
#'      example_beancount_file <- tempfile(fileext = ".beancount")
#'      system(paste("bean-example -o", example_beancount_file), ignore.stderr=TRUE)
#'      df <- register(example_beancount_file)
#'      head(df)   
#'    }
register <- function(file, include_cleared = TRUE, 
                 include_pending = TRUE,
                 include_unmarked = TRUE, 
                 convert_to_cost = FALSE,
                 convert_to_market_value = FALSE,
                 tags = NULL) {
    if (grepl("bean$|beancount$", file)) {
        hfile <- tempfile(fileext = ".hledger")
        system(paste("bean-report","-o", hfile, file, "hledger"))
        if(!is.null(tags)) 
            tags <- paste0("Tag=", tags)
    } else {
        hfile <- file
    }
    hledger_flags <- ""
    if (include_cleared)
        hledger_flags <- paste(hledger_flags, "--cleared")
    if (include_pending)
        hledger_flags <- paste(hledger_flags, "--pending")
    if (include_unmarked)
        hledger_flags <- paste(hledger_flags, "--unmarked")
    if(convert_to_cost)
        hledger_flags <- paste(hledger_flags, "--cost")
    if(convert_to_market_value)
        hledger_flags <- paste(hledger_flags, "--market_value")
    if(!is.null(tags)) {
        tags <- paste0("tag:", tags)
        hledger_flags <- paste(hledger_flags, paste(tags, collapse=" "))
    }

    cfile <- tempfile(fileext = ".csv")
    system(paste("hledger register -f", hfile, "-o", cfile, hledger_flags))
    df <- read.csv(cfile)
    df <- dplyr::mutate(df, 
                date = as.Date(date, "%Y/%m/%d"),
                description = ifelse(grepl("\\|", description), description,
                                     paste(" | ", description)),
                payee = sapply(strsplit(description, " \\| "), function(x) x[1]),
                description = sapply(strsplit(description, " \\| "), function(x) x[2]),
                commodity = sapply(strsplit(amount, " "), function(x) x[2]),
                amount = as.numeric(sapply(strsplit(amount, " "), function(x) x[1]))
                )
    df <- dplyr::select(df, date, payee, description, account, amount, commodity)
    df
}

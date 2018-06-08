#' Compute net worth
#'
#' Compute net worth
#' 
#' @param file Filename for a ledger, hledger, or beancount file.
#' @param date Vector of dates to compute net worth for 
#'    (technically computes net worth of the day before each date).
#' @param regex Regular expression string.
#' @param flags Extra flags to pass to \code{register}.
#' @return  \code{net_worth} returns a data frame
#' @examples
#'    \dontrun{
#'      example_beancount_file <- system.file("extdata", "example.beancount", package = "ledgeR") 
#'      net_worth(example_beancount_file)
#'      net_worth(example_beancount_file, c("2016-01-01", "2017-01-01", "2018-01-01"))
#'    }
#'    
#' @export
net_worth <- function(file, date=Sys.Date()+1, regex = "^Assets|^Liabilities|<Revalued>", flags=NULL) {
    df <- data.frame(date=as.Date(date), net_worth = sapply(date, .net_worth_helper, file, regex, flags))
    rownames(df) <- NULL
    df
}

.net_worth_helper <- function(date, file, regex, flags) {
    mv_flag <- switch(file_ext(file), ledger = "--market", "--value")
    flags <- paste(flags, paste0("--end=", date), mv_flag)
    df <- dplyr::filter(register(file, flags), grepl(regex, .data$account))
    if(length(unique(df$commodity)) > 1)
        stop("Non-unique market value commodity")
    sum(df$amount)
}

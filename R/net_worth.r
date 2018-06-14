# Copyright (c) 2018 Trevor L. Davis <trevor.l.davis@gmail.com>  
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#' Compute net worth
#'
#' Computes net worth for a vector of dates.  
#' Computes net worth at the beginning of the day before any transactions have occurred.
#' 
#' @param file Filename for a ledger, hledger, or beancount file.
#' @param date Vector of dates to compute net worth for.
#' @param include Character vector of regular expressions of accounts to include in the net worth calculation.  
#'      Use \code{".*"} to include everything.
#' @param exclude Character vector of regular expressions of accounts to exclude from the net worth calculation.  
#'      Use \code{NULL} to exclude nothing.
#' @param flags Extra flags to pass to \code{register}.
#'    If using \code{ledger} may want to try something like \code{"-X USD"}.
#' @param toolchain Toolchain used to read in register. 
#'     Either "ledger", "hledger", "bean-report_ledger", or "bean-report_hledger".
#' @param ignore_case logical value of whether to ignore case in regular expressions or not.
#' @return  \code{net_worth} returns a data frame
#' @examples
#'    \dontrun{
#'      example_beancount_file <- system.file("extdata", "example.beancount", package = "ledger") 
#'      net_worth(example_beancount_file)
#'      net_worth(example_beancount_file, c("2016-01-01", "2017-01-01", "2018-01-01"))
#'    }
#' @export
net_worth <- function(file, date=Sys.Date()+1, include = c("^asset","^liabilit","^<revalued>"), exclude=NULL,
                      flags="-V", toolchain = default_toolchain(file), ignore_case=TRUE) {
    df <- dplyr::bind_rows(lapply(date, .net_worth_helper, 
                                  file, include, exclude, flags, toolchain, ignore_case))
    for (name in names(df)) {
        if (! name %in% c("commodity", "date"))
            df[[name]] <- ifelse(is.na(df[[name]]), 0, df[[name]])
    }
    df
}

#' @importFrom tidyr spread
.net_worth_helper <- function(date, file, include, exclude, flags, toolchain, ignore_case) {
    flags <- c(flags, paste0("--end=", date))
    df <- register(file, flags, toolchain)
    include <- paste(include, collapse="|")
    df <- dplyr::filter(df, grepl(include, .data$account, ignore.case=ignore_case))
    if (!is.null(exclude)) {
        exclude <- paste(exclude, collapse="|")
        df <- dplyr::filter(df, !grepl(exclude, .data$account, ignore.case=ignore_case))
    }
    df <- dplyr::filter(df, grepl(include, .data$account, ignore.case=ignore_case))
    df <- dplyr::mutate(df, account = tolower(gsub("^([[:alnum:]]*)?:.*", "\\1", .data$account)))
    df <- dplyr::mutate(df, account = gsub("<revalued>", "revalued", .data$account))
    df_by <- summarize(group_by(df, .data$account, .data$commodity), total = sum(.data$amount))
    df_by <- spread(df_by, .data$account, .data$total)
    old_names <- names(df_by)
    df_nw <- summarize(group_by(df, .data$commodity), net_worth = sum(.data$amount))
    df_nw <- left_join(df_by, df_nw, by="commodity")
    df_nw$date <- as.Date(date)
    df_nw <- dplyr::select(df_nw, "date", "commodity", "net_worth", one_of(old_names))
    df_nw
}

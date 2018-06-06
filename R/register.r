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
#'     For beancount tags include the initial \code{#} and 
#'     for beancount links include initial \code{^}.
#'     If \code{NULL} (the default) don't filter based on any tags.
#' @return  \code{register} returns a data frame.
#'    
#' @import dplyr
#' @importFrom utils read.csv
#' @importFrom rlang .data
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
    if (grepl(".bean$|.beancount$", file)) {
        .assert_binary("bean-report")
        hfile <- tempfile(fileext = ".hledger")
        system(paste("bean-report","-o", hfile, file, "hledger"))
        if(!is.null(tags)) 
            tags <- paste0("Tag=", tags)
        .register_hledger(hfile, include_cleared = include_cleared,
                          include_pending = include_pending,
                          include_unmarked = include_unmarked,
                          convert_to_cost = convert_to_cost,
                          convert_to_market_value = convert_to_market_value,
                          tags = tags)
    } else if (grepl(".hledger$", file)) {
        .assert_binary("hledger")
        .register_hledger(file, include_cleared = include_cleared,
                          include_pending = include_pending,
                          include_unmarked = include_unmarked,
                          convert_to_cost = convert_to_cost,
                          convert_to_market_value = convert_to_market_value,
                          tags = tags)
    } else if (grepl(".ledger$", file)) {
        .assert_binary("ledger")
        .register_ledger(file, include_cleared = include_cleared,
                          include_pending = include_pending,
                          include_unmarked = include_unmarked,
                          convert_to_cost = convert_to_cost,
                          convert_to_market_value = convert_to_market_value,
                          tags = tags)
    } else {
        stop(paste("File", file, "is not supported"))
    }
}

.register_hledger <- function(hfile, 
                     include_cleared, 
                     include_pending,
                     include_unmarked, 
                     convert_to_cost,
                     convert_to_market_value,
                     tags) {
    flags <- ""
    if (include_cleared)
        flags <- paste(flags, "--cleared")
    if (include_pending)
        flags <- paste(flags, "--pending")
    if (include_unmarked)
        flags <- paste(flags, "--unmarked")
    if(convert_to_cost)
        flags <- paste(flags, "--cost")
    if(convert_to_market_value)
        flags <- paste(flags, "--market_value")
    if(!is.null(tags)) {
        tags <- paste0("tag:", tags)
        flags <- paste(flags, paste(tags, collapse=" "))
    }

    cfile <- tempfile(fileext = ".csv")
    system(paste("hledger register -f", hfile, " -o", cfile, " ", flags))
    df <- read.csv(cfile, stringsAsFactors = FALSE)
    df <- dplyr::mutate(df, date = as.Date(date, "%Y/%m/%d"))
    df <- dplyr::mutate(df, description = ifelse(grepl("\\|$", .data$description), 
                                                 paste0(.data$description, " "),
                                                 .data$description))
    df <- dplyr::mutate(df, description = ifelse(grepl("\\|", .data$description),
                                                 .data$description,
                                                 paste0(" | ", .data$description)))
    df <- dplyr::mutate(df, payee = .left_of_split(.data$description, " \\| "))
    df <- dplyr::mutate(df, description = .right_of_split(.data$description, " \\| "))
    df <- dplyr::mutate(df, payee = ifelse(.data$payee == "", NA, .data$payee),
                description = ifelse(.data$description == "", NA, .data$description))
    df <- dplyr::mutate(df, commodity = .right_of_split(.data$amount, " "))
    df <- dplyr::mutate(df, amount = as.numeric(.left_of_split(.data$amount, " ")))
    df <- dplyr::select(df, date, .data$payee, .data$description, .data$account, .data$amount, .data$commodity)
    df
}

.left_of_split <- function(strings, split) {
    sapply(strsplit(strings, split), function(x) { x[1]})
}
.right_of_split <- function(strings, split) {
    sapply(strsplit(strings, split), function(x) { x[2]})
}

.register_ledger <- function(lfile, 
                     include_cleared, 
                     include_pending,
                     include_unmarked, 
                     convert_to_cost,
                     convert_to_market_value,
                     tags) {
    flags <- ""
    if(convert_to_cost)
        flags <- paste(flags, "--cost")
    if(convert_to_market_value)
        flags <- paste(flags, "--market")
    if(!is.null(tags)) {
        warning("tags == NULL is currently not supported for ledger format")
    }

    cfile <- tempfile(fileext = ".csv")
    system(paste("ledger csv -f", lfile, "-o", cfile, flags))
    df <- read.csv(cfile, header=FALSE, stringsAsFactors = FALSE)
    names(df) <- c("date", "V2", "description", "account", "commodity", "amount", "mark", "V8")
    if (!include_cleared)
        df <- dplyr::filter(df, .data$mark != "\\*")
    if (include_pending)
        df <- dplyr::filter(df, .data$mark != "!")
    if (include_unmarked)
        df <- dplyr::filter(df, .data$mark != "")

    df <- dplyr::mutate(df, 
                date = as.Date(date, "%Y/%m/%d"),
                description = ifelse(grepl("\\|$", .data$description), paste0(.data$description, " "),
                                     .data$description),
                description = ifelse(grepl("\\|", .data$description), .data$description,
                                     paste0(" | ", .data$description)),
                payee = .left_of_split(.data$description, " \\| "),
                description = .right_of_split(.data$description, " \\| "),
                payee = ifelse(.data$payee == "", NA, .data$payee),
                description = ifelse(.data$description == "", NA, .data$description),
                )
    df <- dplyr::select(df, date, .data$payee, .data$description, .data$account, .data$amount, .data$commodity)
    df
}

.is_binary_on_path <- function(binary) {
    any(Sys.which(binary) != "")
}

.assert_binary <- function(binary) {
    if(!.is_binary_on_path(binary))
        stop(paste(binary, "not found on path"))
}

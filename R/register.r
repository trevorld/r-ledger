#' Import a hledger or beancount register
#'
#' \code{register} imports the register from a ledger, hledger, or beancount file as a data frame.
#' 
#' @param file Filename for a ledger, hledger, or beancount file.
#' @param flags Character vector of additional command line flags to pass 
#'     to either \code{ledger csv} or \code{hledger register}.
#' @return  \code{register} returns a data frame.
#'    
#' @import dplyr
#' @importFrom utils read.csv
#' @importFrom tools file_ext
#' @importFrom rlang .data
#' @export
#' @examples
#'    \dontrun{
#'      example_beancount_file <- system.file("extdata", "example.beancount", package = "ledgeR") 
#'      dfb <- register(example_beancount_file)
#'      head(df)   
#'
#'      dfb2 <- rio::import(example_beancount_file)
#'      all.equal(dfb, dfb2)
#'
#'      example_hledger_file <- system.file("extdata", "example.hledger", package = "ledgeR") 
#'      dfh <- register(example_hledger_file)
#'      head(dfh)
#'
#'      example_ledger_file <- system.file("extdata", "example.ledger", package = "ledgeR") 
#'      dfl <- register(example_ledger_file)
#'      head(dfl)
#'    }
register <- function(file, flags = NULL) {
    flags <- paste(flags, collapse=" ")
    ext <- tools::file_ext(file)
    if (ext %in% c("bean", "beancount")) {
        .assert_binary("bean-report")
        .assert_binary("hledger")
        hfile <- tempfile(fileext = ".hledger")
        on.exit(unlink(hfile))
        system(paste("bean-report","-o", hfile, file, "hledger"))
        df <- .register_hledger(hfile, flags)
    } else if (ext == "hledger") {
        .assert_binary("hledger")
        df <- .register_hledger(file, flags)
    } else if (ext == "ledger") {
        .assert_binary("ledger")
        df <- .register_ledger(file, flags)
    } else {
        stop(paste("File extension", ext, "is not supported"))
    }
    dplyr::select(df, "date", "mark", "payee", "description", "account", "amount",
                  "commodity", matches("historical_cost"), matches("hc_commodity"),
                  matches("market_value"), matches("mv_commodity"))
}

.register_hledger <- function(hfile, flags) {
    df <- .register_hledger_helper(hfile, flags)
    df_c <- .register_hledger_helper(hfile, paste(flags, "--cost"))
    df$historical_cost <- df_c$amount
    df$hc_commodity <- df_c$commodity
    df_m <- .register_hledger_helper(hfile, paste(flags, "--value"))
    df$market_value <- df_m$amount
    df$mv_commodity <- df_m$commodity
    df
}

.register_hledger_helper <- function(hfile, flags="") {
    df_c <- .read_hledger(hfile, paste(flags, "--cleared"))
    df_c <- dplyr::mutate(df_c, mark = "*")
    df_p <- .read_hledger(hfile, paste(flags, "--pending"))
    df_p <- dplyr::mutate(df_p, mark = "!")
    df_u <- .read_hledger(hfile, paste(flags, "--unmarked"))
    df_u <- dplyr::mutate(df_u, mark = "")
    df <- dplyr::bind_rows(df_c, df_p, df_u)
    .clean_hledger(df)
}

.read_hledger <- function(hfile, flags) {
    cfile <- tempfile(fileext = ".csv")
    on.exit(unlink(cfile))
    cmd <- paste("hledger register -f", hfile, " -o", cfile, " ", flags)
    system(cmd)
    read.csv(cfile, stringsAsFactors = FALSE)
}

.clean_hledger <- function(df) {
    if (nrow(df)) {
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
    } else {
        df <- dplyr::mutate(df, payee = .data$description, commodity = .data$amount)
    }
    df
}


.left_of_split <- function(strings, split) {
    sapply(strsplit(strings, split), function(x) { x[1]})
}
.right_of_split <- function(strings, split) {
    sapply(strsplit(strings, split), function(x) { x[2]})
}

.register_ledger <- function(lfile, flags) {
    df <- .read_ledger(lfile, flags)
    df
}

.read_ledger <- function(lfile, flags) {
    cfile <- tempfile(fileext = ".csv")
    on.exit(unlink(cfile))
    cmd <- paste("ledger csv -f", lfile, "-o", cfile, flags)
    system(cmd)
    .clean_ledger(read.csv(cfile, header=FALSE, stringsAsFactors = FALSE))
}

.clean_ledger <- function(df) {
    names(df) <- c("date", "V2", "description", "account", "commodity", "amount", "mark", "V8")

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
    df
}

.is_binary_on_path <- function(binary) {
    any(Sys.which(binary) != "")
}

.assert_binary <- function(binary) {
    if(!.is_binary_on_path(binary))
        stop(paste(binary, "not found on path"))
}

#' @importFrom rio .import
#' @export
.import.rio_beancount <- register 

#' @export
.import.rio_bean <- register

#' @export
.import.rio_ledger <- register

#' @export
.import.rio_hledger <- register

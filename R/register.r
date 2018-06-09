#' Determine default tool chain used for reading in register
#'
#' \code{default_toolchain} determines default tool chain used for reading in register.
#'
#' @param file Filename for a ledger, hledger, or beancount file.
#'
#' @export
default_toolchain <- function(file) {
    ext <- tools::file_ext(file)
    toolchain <- NULL
    if (ext == "ledger") {
        if (.is_toolchain_supported("ledger")) {
            toolchain <- "ledger"
        } else if (.is_toolchain_supported("hledger")) {
            warning("ledger not found on path trying hledger instead")
            toolchain <- "hledger"
        }
    } else if (ext == "hledger") {
        if (.is_toolchain_supported("hledger")) {
            toolchain <- "hledger"
        } else if (.is_toolchain_supported("ledger")) {
            warning("hledger not found on path trying ledger instead")
            toolchain <- "ledger"
        }
    } else if (ext %in% c("bean", "beancount")) {
        if (.is_toolchain_supported("bean-report_hledger")) {
            toolchain <- "bean-report_hledger"
        } else if (.is_toolchain_supported("bean-report_ledger")) {
            toolchain <- "bean-report_ledger"
        }
    }
    if (is.null(toolchain))
        stop(paste("Couldn't find an acceptable toolchain for", ext))
    toolchain
}

#' Import a hledger or beancount register
#'
#' \code{register} imports the register from a ledger, hledger, or beancount file as a data frame.
#' 
#' @param file Filename for a ledger, hledger, or beancount file.
#' @param flags Character vector of additional command line flags to pass 
#'     to either \code{ledger csv} or \code{hledger register}.
#' @param toolchain Toolchain used to read in register. 
#'     Either "ledger", "hledger", "bean-report_ledger", or "bean-report_hledger".
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
register <- function(file, flags = NULL, toolchain = default_toolchain(file)) {
    .assert_toolchain(toolchain)
    flags <- paste(flags, collapse=" ")
    if (toolchain == "ledger") {
        df <- .register_ledger(file, flags)
    } else if (toolchain == "hledger") {
        df <- .register_hledger(file, flags)
    } else if (toolchain == "bean-report_ledger") {
        file <- .bean_report(file, "ledger")
        on.exit(unlink(file))
        df <- .register_ledger(file, flags)
    } else if (toolchain == "bean-report_hledger") {
        file <- .bean_report(file, "hledger")
        on.exit(unlink(file))
        df <- .register_hledger(file, flags)
    } 
    dplyr::select(df, "date", "mark", "payee", "description", "account", "amount",
                  "commodity", matches("historical_cost"), matches("hc_commodity"),
                  matches("market_value"), matches("mv_commodity"))
}

.bean_report <- function(file, format) {
    tfile <- tempfile(fileext = paste0(".", format))
    system(paste("bean-report", "-o", tfile, file, format))
    tfile
}

.register_hledger <- function(hfile, flags) {
    df <- .register_hledger_helper(hfile, flags)
    df_c <- .register_hledger_helper(hfile, paste(flags, "--cost"))
    df$historical_cost <- df_c$amount
    df$hc_commodity <- df_c$commodity
    df_m <- .register_hledger_helper(hfile, paste(flags, "-V"))
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
    system(cmd, ignore.stderr=TRUE)
    if (!file.exists(cfile))
        stop("hledger had an import error")
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
    system(cmd, ignore.stderr=TRUE)
    if (!file.exists(cfile))
        stop("ledger had an import error")
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
.is_toolchain_supported <- function(toolchain) {
    if (toolchain == "ledger") {
        .is_binary_on_path("ledger")
    } else if (toolchain == "hledger") {
        .is_binary_on_path("ledger")
    } else if (toolchain == "bean-report_ledger") {
        .is_binary_on_path("ledger") && .is_binary_on_path("bean-report")
    } else if (toolchain == "bean-report_hledger") {
        .is_binary_on_path("hledger") && .is_binary_on_path("bean-report")
    } else {
        FALSE
    }
}

.assert_toolchain <- function(toolchain) {
    if(!.is_toolchain_supported(toolchain))
        stop(paste(toolchain, "binaries not found on path"))
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

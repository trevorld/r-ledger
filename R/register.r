# Copyright (c) 2018 Trevor L. Davis <trevor.l.davis@gmail.com>  
# Copyright (c) 2018 Jenya Sovetkin <e.sovetkin@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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
#' \code{register} imports the register from a ledger, hledger, or beancount file as a tibble.
#' 
#' @param file Filename for a ledger, hledger, or beancount file.
#' @param ... Arguments passed on to either \code{register_ledger}, \code{register_hledger}, or \code{register_beancount}
#' @param flags Character vector of additional command line flags to pass 
#'     to either \code{ledger csv} or \code{hledger register}.
#' @param toolchain Toolchain used to read in register. 
#'     Either "ledger", "hledger", "bean-report_ledger", or "bean-report_hledger".
#' @param date End date.  
#'     Only transactions (and price statements) before this date are used.  
#' @return  \code{register} returns a tibble.
#'    
#' @import dplyr
#' @importFrom tools file_ext
#' @importFrom rlang .data
#' @export
#' @examples
#'    \dontrun{
#'
#'      example_ledger_file <- system.file("extdata", "example.ledger", package = "ledger") 
#'      dfl <- register(example_ledger_file)
#'      head(dfl)
#'
#'      example_hledger_file <- system.file("extdata", "example.hledger", package = "ledger") 
#'      dfh <- register(example_hledger_file)
#'      head(dfh)
#'
#'      example_beancount_file <- system.file("extdata", "example.beancount", package = "ledger") 
#'      dfb <- register(example_beancount_file)
#'      head(dfb)
#'    }
register <- function(file, ..., toolchain = default_toolchain(file), date=NULL) {
    .assert_toolchain(toolchain)
    if (toolchain == "ledger") {
        df <- register_ledger(file, ..., date=date)
    } else if (toolchain == "hledger") {
        df <- register_hledger(file, ..., date=date)
    } else if (toolchain == "bean-report_ledger") {
        file <- .bean_report(file, "ledger")
        on.exit(unlink(file))
        df <- register_ledger(file, ..., date=date)
    } else if (toolchain == "bean-report_hledger") {
        file <- .bean_report(file, "hledger")
        on.exit(unlink(file))
        df <- register_hledger(file, ..., date=date)
    } 
}

.select_columns <- function(df) {
    dplyr::select(df, "date", matches("mark$"), "payee", "description", "account", "amount",
                  "commodity", matches("historical_cost"), matches("hc_commodity"),
                  matches("market_value"), matches("mv_commodity"), matches("comment"))
}

.nf <- function(filename) { shQuote(normalizePath(filename, mustWork=FALSE)) }

.bean_report <- function(file, format) {
    tfile <- tempfile(fileext = paste0(".", format))
    args <- c("-o", .nf(tfile), .nf(file), format)
    if ( .Platform$OS.type == "windows") {
        # bean-report on Windows seems to choke when called from system2
        shell(paste("bean-report -o", .nf(tfile), .nf(file), format), mustWork=TRUE)
    } else {
        .system("bean-report", args)
    }
    tfile
}

#' @rdname register
#' @param add_mark Whether to add a column with the mark information.  Only relevant for hledger files.
#' @param add_cost Whether to add historical cost columns.  Only relevant for hledger files.
#' @param add_value Whether to add market value columns.  Only relevant for hledger files.
#' @export 
register_hledger <- function(file, flags="", date=NULL, add_mark=TRUE, add_cost=TRUE, add_value=TRUE) {
    if(!is.null(date))
        flags <- c(flags, paste0("--end=", date))
    df <- .register_hledger_helper(file, flags, add_mark)
    if (add_cost) {
        df_c <- .register_hledger_helper(file, c(flags, "--cost"), add_mark)
        df$historical_cost <- df_c$amount
        df$hc_commodity <- df_c$commodity
    }
    if (add_value) {
        df_m <- .register_hledger_helper(file, c(flags, "-V"), add_mark)
        df$market_value <- df_m$amount
        df$mv_commodity <- df_m$commodity
    }
    .select_columns(df)
}

.register_hledger_helper <- function(hfile, flags="", add_mark=TRUE) {
    if(add_mark) {
        df_c <- .read_hledger(hfile, c(flags, "--cleared"))
        df_c <- dplyr::mutate(df_c, mark = "*")
        df_p <- .read_hledger(hfile, c(flags, "--pending"))
        df_p <- dplyr::mutate(df_p, mark = "!")
        df_u <- .read_hledger(hfile, c(flags, "--unmarked"))
        df_u <- dplyr::mutate(df_u, mark = "")
        df <- dplyr::bind_rows(df_c, df_p, df_u)
    } else {
        df <- .read_hledger(hfile, flags)
    }
    .clean_hledger(df)
}

.read_hledger <- function(hfile, flags) {
    cfile <- tempfile(fileext = ".csv")
    on.exit(unlink(cfile))
    args <- c("register", "-f", .nf(hfile), "-o", .nf(cfile), flags)
    .system("hledger", args)
    .read_csv(cfile)
}

#' @importFrom tibble as_tibble
#' @importFrom utils read.csv
.read_csv <- function(cfile, ...) {
    as_tibble(read.csv(cfile, stringsAsFactors=FALSE, ...))
}

.system <- function(cmd, args) {
    tryCatch(system2(cmd, args, stdout=TRUE, stderr=TRUE),
             warning = function(w) {
                stop(paste(c(paste(cmd, "had an import error:"), w), collapse="\n"))
             })
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

#' @rdname register
#' @export
register_ledger <- function(file, flags="", date=NULL) {
    if(!is.null(date))
        flags <- c(flags, paste0("--end=", date))
    df <- .read_ledger(file, flags)
    .select_columns(df)
}

.read_ledger <- function(lfile, flags) {
    cfile <- tempfile(fileext = ".csv")
    on.exit(unlink(cfile))
    if ( .Platform$OS.type == "windows") {
        # ledger on Windows seems to choke on absolute file paths 
        tlfile <- tempfile(fileext = ".ledger")
        on.exit(unlink(tlfile))
        file.copy(lfile, tlfile)
        wd <- getwd()
        on.exit(setwd(wd))
        setwd(tempdir())
        args <- c("csv", "-f", basename(tlfile), "-o", basename(cfile), flags)
    } else {
        args <- c("csv", "-f", .nf(lfile), "-o", .nf(cfile), flags)
    }
    .system("ledger", args)
    .clean_ledger(.read_csv(cfile, header=FALSE))
}

.clean_ledger <- function(df) {
    names(df) <- c("date", "V2", "description", "account", "commodity", "amount", "mark", "comment")

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
    Sys.which(binary) != ""
}
.is_toolchain_supported <- function(toolchain) {
    if (toolchain == "ledger") {
        .is_binary_on_path("ledger")
    } else if (toolchain == "hledger") {
        .is_binary_on_path("hledger")
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

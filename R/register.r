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
    toolchain <- switch(ext,
                        ledger = "ledger",
                        hledger = "hledger",
                        bean = "beancount",
                        beancount = "beancount",
                        NULL)
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
#'     Either "ledger", "hledger", "beancount", "bean-report_ledger", or "bean-report_hledger".
#' @param date End date.  
#'     Only transactions (and implicitly price statements) before this date are used.  
#' @return  \code{register} returns a tibble.
#'    
#' @importFrom dplyr bind_rows
#' @importFrom dplyr mutate
#' @importFrom dplyr select
#' @importFrom tools file_ext
#' @importFrom rlang .data
#' @export
#' @examples
#'  if (Sys.which("ledger") != "") {
#'      example_ledger_file <- system.file("extdata", "example.ledger", package = "ledger") 
#'      dfl <- register(example_ledger_file)
#'      head(dfl)
#'  }
#'  if (Sys.which("hledger") != "") {
#'      example_hledger_file <- system.file("extdata", "example.hledger", package = "ledger") 
#'      dfh <- register(example_hledger_file)
#'      head(dfh)
#'  }
#'  if (Sys.which("bean-query") != "") {
#'      example_beancount_file <- system.file("extdata", "example.beancount", package = "ledger") 
#'      dfb <- register(example_beancount_file)
#'      head(dfb)
#'  }
register <- function(file, ..., toolchain = default_toolchain(file), date=NULL) {
    .assert_toolchain(toolchain)
    switch(toolchain,
        "ledger" = register_ledger(file, ..., date=date),
        "hledger" = register_hledger(file, ..., date=date),
        "beancount" = register_beancount(file, ..., date=date),
        "bean-report_ledger" = {
            file <- .bean_report(file, "ledger")
            on.exit(unlink(file))
            df <- register_ledger(file, ..., date=date)
        },
        "bean-report_hledger" = {
            file <- .bean_report(file, "hledger")
            on.exit(unlink(file))
            df <- register_hledger(file, ..., date=date)
        }
    )
}

#' @importFrom tidyselect matches
.select_columns <- function(df) {
    select(df, "date", tidyselect::matches("mark$"),
              "payee", "description", "account", "amount", "commodity",
             tidyselect::matches("historical_cost"), 
             tidyselect::matches("hc_commodity"),
             tidyselect::matches("market_value"),
             tidyselect::matches("mv_commodity"), 
             tidyselect::matches("comment"),
             tidyselect::matches("tags"))
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

#' @importFrom stringr str_squish
#' @importFrom stringr str_trim
#' @importFrom tidyr separate
#' @rdname register
#' @export
register_beancount <- function(file, date=NULL) {
    cfile <- tempfile(fileext = paste0(".csv"))
    query <- paste("select date, flag as mark, account, payee,",
                  "narration as description,",
                  "number as amount, currency as commodity,",
                  "number(cost(position)) as historical_cost,",
                  "currency(cost(position)) as hc_commodity,",
                  "tags,")
    #            "value(position), tags") 
    if (!is.null(date)) {
       query <- paste(query, 
                  sprintf("number(value(position,%s)) as market_value,", date),
                  sprintf("currency(value(position,%s)) as mv_commodity", date),
                  "from close on", date) 
    } else {
       query <- paste(query, "number(value(position)) as market_value,",
                      "currency(value(position)) as mv_commodity") 
    }

    args <- c("-f", "csv", "-o", .nf(cfile), .nf(file), shQuote(query))

    if ( .Platform$OS.type == "windows") {
        # bean-report on Windows seems to choke when called from system2
        shell(paste("bean-query -f csv -o", .nf(cfile), .nf(file), shQuote(query)), mustWork=TRUE)
    } else {
        .system("bean-query", args)
    }
    df <- .read_csv(cfile)
    if(nrow(df) == 0) {
        df <- tibble(date = as.Date(character()),
                             mark = character(),
                             account = character(),
                             payee = character(),
                             description = character(),
                             amount = numeric(),
                             commodity = character(),
                             historical_cost = numeric(),
                             hc_commodity = character(),
                             market_value = numeric(),
                             mv_commodity = character(),
                             tags = character())
    }
    df <- mutate(df,
                        mark = str_trim(.data$mark),
                        account = str_trim(.data$account),
                        payee = str_trim(.data$payee),
                        description = str_trim(.data$description),
                        commodity = str_trim(.data$commodity),
                        hc_commodity = str_trim(.data$hc_commodity),
                        mv_commodity = str_trim(.data$mv_commodity),
                        tags = str_squish(.data$tags))
    .select_columns(df)
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
        df_c <- mutate(df_c, mark = "*")
        df_p <- .read_hledger(hfile, c(flags, "--pending"))
        df_p <- mutate(df_p, mark = "!")
        df_u <- .read_hledger(hfile, c(flags, "--unmarked"))
        df_u <- mutate(df_u, mark = "")
        df <- bind_rows(df_c, df_p, df_u)
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

#' @importFrom tibble tibble
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
        df <- mutate(df, date = as.Date(date, "%Y/%m/%d"))
        df <- mutate(df, description = ifelse(grepl("\\|$", .data$description), 
                                                     paste0(.data$description, " "),
                                                     .data$description))
        df <- mutate(df, description = ifelse(grepl("\\|", .data$description),
                                                     .data$description,
                                                     paste0(" | ", .data$description)))
        df <- mutate(df, payee = .left_of_split(.data$description, " \\| "))
        df <- mutate(df, description = .right_of_split(.data$description, " \\| "))
        df <- mutate(df, payee = ifelse(.data$payee == "", NA, .data$payee),
                    description = ifelse(.data$description == "", NA, .data$description))
        df <- mutate(df, commodity = .right_of_split(.data$amount, " "))
        df <- mutate(df, amount = as.numeric(.left_of_split(.data$amount, " ")))
    } else {
        df <- mutate(df, payee = .data$description, commodity = .data$amount)
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
    flags <- c(flags, "--empty")
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

    df <- mutate(df, 
                date = as.Date(date, "%Y/%m/%d"),
                description = ifelse(grepl("\\|$", .data$description), paste0(.data$description, " "),
                                     .data$description),
                description = ifelse(grepl("\\|", .data$description), .data$description,
                                     paste0(" | ", .data$description)),
                payee = .left_of_split(.data$description, " \\| "),
                description = .right_of_split(.data$description, " \\| "),
                payee = ifelse(.data$payee == "", NA, .data$payee),
                description = ifelse(.data$description == "", NA, .data$description),
                payee = as.character(.data$payee),
                comment = as.character(.data$comment)
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
    } else if (toolchain == "beancount") {
        .is_binary_on_path("bean-query")
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

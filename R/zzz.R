.import.rio_beancount <- register # nolint
.import.rio_bean <- register # nolint
.import.rio_ledger <- register # nolint
.import.rio_hledger <- register # nolint

.onLoad <- function(...) {
    register_s3_method("rio", ".import", "rio_beancount")
    register_s3_method("rio", ".import", "rio_bean")
    register_s3_method("rio", ".import", "rio_hledger")
    register_s3_method("rio", ".import", "rio_ledger")

    invisible(NULL)
}

register_s3_method <- function(pkg, generic, class) {
    fun <- get(paste0(generic, ".", class), envir = parent.frame())
    if (requireNamespace(pkg, quietly = TRUE))
        registerS3method(generic, class, fun, envir = asNamespace(pkg))
    invisible(NULL)
}

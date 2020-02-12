to_numeric <- function(x) {
    x <- sub("[,.]([0-9]*)$", ";\\1", x)
    x <- gsub("[,. ]", "", x)
    x <- sub(";", ".", x)
    as.numeric(x)
}

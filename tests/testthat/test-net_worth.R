# Copyright 2021 Trevor L Davis <trevor.l.davis@gmail.com>

lfile <- system.file("extdata", "example.ledger", package = "ledger")
hfile <- system.file("extdata", "example.hledger", package = "ledger")
bfile <- system.file("extdata", "example.beancount", package = "ledger")
lefile <- system.file("extdata", "empty.ledger", package = "ledger")
hefile <- system.file("extdata", "empty.hledger", package = "ledger")
befile <- system.file("extdata", "empty.beancount", package = "ledger")
df_file <- data.frame(
	file = c(lfile, hfile, bfile, bfile, bfile),
	efile = c(lefile, hefile, befile, befile, befile),
	toolchain = c("ledger", "hledger", "beancount", "bean-report_ledger", "bean-report_hledger"),
	stringsAsFactors = FALSE
)

skip_toolchain <- function(file, toolchain) {
	if (!.is_toolchain_supported(toolchain)) {
		expect_error(ledger::register(file, toolchain = toolchain))
		skip(paste(toolchain, "binaries not found"))
	}
	if (toolchain == "bean-report_hledger") skip_on_appveyor()
}

for (ii in seq_len(nrow(df_file))) {
	toolchain <- df_file$toolchain[ii]
	file <- df_file$file[ii]
	context(paste(file, toolchain, "works as expected"))
	net_worth_ <- function(...) ledger::net_worth(..., toolchain = toolchain)

	test_that(paste("net_worth works as expected on", basename(file), "using", toolchain), {
		skip_toolchain(file, toolchain)

		if (!.is_toolchain_supported(toolchain)) {
			expect_error(ledger::register(file, toolchain = toolchain))
			skip(paste(toolchain, "not supported"))
		}
		df <- net_worth_(file)
		expect_true(tibble::is_tibble(df))
		expect_equal(df$net_worth, 8125.39)
		expect_equal(
			net_worth_(
				file,
				include = ".*",
				exclude = c("^Equity", "^Income", "^Expenses")
			)$net_worth,
			8125.39
		)
		expect_equal(
			net_worth_(file, c("2016-01-01", "2017-01-01", "2018-01-01"))$net_worth,
			c(5000, 4361.39, 6743.39)
		)
	})
}

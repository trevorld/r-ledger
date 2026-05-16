# Copyright 2021 Trevor L Davis <trevor.l.davis@gmail.com>

lfile <- system.file("extdata", "example.ledger", package = "ledger")
hfile <- system.file("extdata", "example.hledger", package = "ledger")
bfile <- system.file("extdata", "example.beancount", package = "ledger")
lefile <- system.file("extdata", "empty.ledger", package = "ledger")
hefile <- system.file("extdata", "empty.hledger", package = "ledger")
befile <- system.file("extdata", "empty.beancount", package = "ledger")
df_file <- data.frame(
	file = c(lfile, hfile, bfile, bfile, bfile, bfile, bfile),
	efile = c(lefile, hefile, befile, befile, befile, befile, befile),
	toolchain = c(
		"ledger",
		"hledger",
		"beancount",
		"bean-query",
		"rledger",
		"bean-report_ledger",
		"bean-report_hledger"
	),
	stringsAsFactors = FALSE
)

test_that(".assert_toolchain works as expected", {
	expect_error(.assert_toolchain("does-not-exist"), "does-not-exist binaries not found on path")
})
test_that("default_toolchain works as expected", {
	expect_error(ledger::register("test.docx"), "Couldn't find an acceptable toolchain for docx")
})
test_that("register works as expected", {
	expect_error(
		ledger::register("test.docx", toolchain = "docx"),
		"docx binaries not found on path"
	)
	if (.is_toolchain_supported("ledger")) {
		expect_error(
			ledger::register("test.docx", toolchain = "ledger"),
			"ledger had an import error"
		)
	}
})
test_that("default_toolchain works as expected", {
	if (.is_toolchain_supported("ledger")) {
		expect_equal(default_toolchain("test.ledger"), "ledger")
	}
	if (.is_toolchain_supported("hledger")) {
		expect_equal(default_toolchain("test.hledger"), "hledger")
	}
	if (.is_toolchain_supported("beancount")) {
		expect_equal(default_toolchain("test.beancount"), "beancount")
	}
})

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
	empty_file <- df_file$efile[ii]
	deprecated_toolchains <- c("bean-report_ledger", "bean-report_hledger")
	register_ <- function(...) {
		if (toolchain %in% deprecated_toolchains) {
			suppressWarnings(ledger::register(..., toolchain = toolchain))
		} else {
			ledger::register(..., toolchain = toolchain)
		}
	}

	test_that(paste("register works as expected on", basename(file), "using", toolchain), {
		skip_toolchain(file, toolchain)

		df <- register_(file)
		expect_equal(sum(dplyr::filter(df, account == "Expenses:Taxes:Federal")$amount), 3 * 82.55)
		expect_true(tibble::is_tibble(df))

		mark <- unique(dplyr::filter(df, description == "Federal Income Tax Withholding")$mark)
		expect_equal(mark, "*")

		if (toolchain == "ledger") {
			# code column
			code <- dplyr::filter(
				df,
				description == "Federal Income Tax Withholding",
				date == "2016-01-05"
			)$code
			expect_equal(unique(code), "TAX-001")
			code_na <- dplyr::filter(
				df,
				description == "Federal Income Tax Withholding",
				date == "2017-01-05"
			)$code
			expect_true(all(is.na(code_na)))
			# mark is correctly extracted from description when code is present
			tax_mark <- unique(dplyr::filter(df, code == "TAX-001")$mark)
			expect_equal(tax_mark, "*")
			dep_mark <- unique(dplyr::filter(df, code == "DEP-001")$mark)
			expect_equal(dep_mark, "!")
			# description does not contain leftover mark prefix
			expect_false(any(grepl("^[*!] ", df$description), na.rm = TRUE))
		}
		mark <- dplyr::filter(
			df,
			date == "2018-01-05",
			description == "Deposit to Checking Account",
			account == "Assets:JT-Checking"
		)$mark
		expect_equal(mark, "!")

		investment <- dplyr::filter(df, account == "Assets:JT-Brokerage")
		expect_equal(investment$amount, 4)

		if (require("rio")) {
			df2 <- rio::import(file, toolchain = toolchain)
			df2 <- tibble::as_tibble(df2)
			ftax_sum <- sum(dplyr::filter(df2, account == "Expenses:Taxes:Federal")$amount)
			expect_equal(ftax_sum, 3 * 82.55)
			expect_equal(df, df2)
		}

		if (toolchain %in% c("hledger", "bean-report_hledger")) {
			expect_equal(investment$historical_cost, 1000)
			expect_equal(investment$market_value, 2000)
			df <- register_(file, flags = "tag:restaurant")
			expect_equal(dplyr::filter(df, account == "Expenses:Food:Restaurant")$amount, 20.07)
		} else {
			expect_error(register_(file, flags = "tag:restaurant"))
			expect_error(register_(file, flags = "tag:Link=grocery"))
		}
		if (toolchain %in% c("beancount", "bean-query", "rledger")) {
			expect_equal(investment$historical_cost, 1000)
			expect_equal(investment$market_value, 2000)
		}
		if (toolchain %in% c("ledger", "bean-report_ledger")) {
			expect_warning(investment$market_value)
		}
	})

	test_that(paste("register works as expected on empty file using", toolchain), {
		skip_toolchain(file, toolchain)

		if (!toolchain %in% c("ledger", "bean-report_ledger")) {
			df <- register_(empty_file)
			expect_equal(nrow(df), 0)
		} else {
			expect_error(register_(empty_file))
		}
	})
}

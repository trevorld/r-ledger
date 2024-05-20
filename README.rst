ledger
======



.. |CRAN-status| image:: https://www.r-pkg.org/badges/version/ledger
    :target: https://cran.r-project.org/package=ledger
    :alt: CRAN Status Badge
.. |R-CMD-check| image:: https://github.com/trevorld/r-ledger/workflows/R-CMD-check/badge.svg
    :target: https://github.com/trevorld/r-ledger/actions
    :alt: R-CMD-check
.. |codecov| image:: https://codecov.io/github/trevorld/r-ledger/branch/master/graph/badge.svg
    :target: https://app.codecov.io/github/trevorld/r-ledger?branch=master
    :alt: Coverage Status
.. |downloads| image:: https://cranlogs.r-pkg.org/badges/ledger
    :target: https://cran.r-project.org/package=ledger
    :alt: RStudio CRAN mirror downloads

|CRAN-status| |R-CMD-check| |codecov| |downloads|

``ledger`` is an R package to import data from `plain text accounting <https://plaintextaccounting.org/>`_ software like `Ledger <https://ledger-cli.org/>`_, `HLedger <https://hledger.org/>`_, and `Beancount <https://github.com/beancount/beancount>`_ into an R data frame for convenient analysis, plotting, and export.

Right now it supports reading in the register from ``ledger``, ``hledger``, and ``beancount`` files.  

.. contents::

Installation
------------

To install the last version released to CRAN use the following command in R:

.. code:: r

    install.packages("ledger")

To install the development version of the ``ledger`` package (and its R package dependencies) use the ``install_github`` function from the ``remotes`` package in R:

.. code:: r
    
    install.packages("remotes")
    remotes::install_github("trevorld/r-ledger")

This package also has some system dependencies that need to be installed depending on which plaintext accounting files you wish to read to be able to read in:

ledger
    `ledger <https://ledger-cli.org/>`_ (>= 3.1)

hledger
    `hledger <https://hledger.org/>`_ (>= 1.4)

beancount
    `beancount <https://github.com/beancount/beancount>`_ (>= 2.0)

To install hledger run the following in your shell:

.. code:: bash

    stack update && stack install --resolver=lts-14.3 hledger-lib-1.15.2 hledger-1.15.2 hledger-web-1.15 hledger-ui-1.15 --verbosity=error 

To install beancount run the following in your shell:

.. code:: bash

    pip3 install beancount

`Several pre-compiled Ledger binaries are available <https://ledger-cli.org/download.html>`_ (often found in several open source repos).

To run the unit tests you'll also need the suggested R package ``testthat``.

Examples
--------

API
+++

The main function of this package is ``register`` which reads in the register of a plaintext accounting file.  This package also registers S3 methods so one can use ``rio::import`` to read in a register, a ``net_worth`` convenience function, and a ``prune_coa`` convenience function.

``register()``
~~~~~~~~~~~~~~

Here are some examples of very basic files stored within the package:


.. code:: r
    

    library("ledger")
    ledger_file <- system.file("extdata", "example.ledger", package = "ledger") 
    register(ledger_file)


::

    ## # A tibble: 42 × 8
    ##    date       mark  payee       description     account amount commodity comment
    ##    <date>     <chr> <chr>       <chr>           <chr>    <dbl> <chr>     <chr>  
    ##  1 2015-12-31 *     <NA>        Opening Balanc… Assets…  5000  USD       ""     
    ##  2 2015-12-31 *     <NA>        Opening Balanc… Equity… -5000  USD       ""     
    ##  3 2016-01-01 *     Landlord    Rent            Assets… -1500  USD       ""     
    ##  4 2016-01-01 *     Landlord    Rent            Expens…  1500  USD       ""     
    ##  5 2016-01-01 *     Brokerage   Buy Stock       Assets… -1000  USD       ""     
    ##  6 2016-01-01 *     Brokerage   Buy Stock       Equity…  1000  USD       ""     
    ##  7 2016-01-01 *     Brokerage   Buy Stock       Assets…     4  SP        ""     
    ##  8 2016-01-01 *     Brokerage   Buy Stock       Equity… -1000  USD       ""     
    ##  9 2016-01-01 *     Supermarket Grocery store   Expens…   501. USD       "Link:…
    ## 10 2016-01-01 *     Supermarket Grocery store   Liabil…  -501. USD       "Link:…
    ## # ℹ 32 more rows


.. code:: r
    

    hledger_file <- system.file("extdata", "example.hledger", package = "ledger") 
    register(hledger_file)


::

    ## # A tibble: 42 × 12
    ##    date       mark  payee   description account amount commodity historical_cost
    ##    <date>     <chr> <chr>   <chr>       <chr>    <dbl> <chr>               <dbl>
    ##  1 2015-12-31 *     <NA>    Opening Ba… Assets…  5000  USD                 5000 
    ##  2 2015-12-31 *     <NA>    Opening Ba… Equity… -5000  USD                -5000 
    ##  3 2016-01-01 *     Landlo… Rent        Assets… -1500  USD                -1500 
    ##  4 2016-01-01 *     Landlo… Rent        Expens…  1500  USD                 1500 
    ##  5 2016-01-01 *     Broker… Buy Stock   Assets… -1000  USD                -1000 
    ##  6 2016-01-01 *     Broker… Buy Stock   Equity…  1000  USD                 1000 
    ##  7 2016-01-01 *     Broker… Buy Stock   Assets…     4  SP                  1000 
    ##  8 2016-01-01 *     Broker… Buy Stock   Equity… -1000  USD                -1000 
    ##  9 2016-01-01 *     Superm… Grocery st… Expens…   501. USD                  501.
    ## 10 2016-01-01 *     Superm… Grocery st… Liabil…  -501. USD                 -501.
    ## # ℹ 32 more rows
    ## # ℹ 4 more variables: hc_commodity <chr>, market_value <dbl>,
    ## #   mv_commodity <chr>, id <chr>


.. code:: r
    

    beancount_file <- system.file("extdata", "example.beancount", package = "ledger") 
    register(beancount_file)


::

    ## # A tibble: 42 × 13
    ##    date       mark  payee   description account amount commodity historical_cost
    ##    <date>     <chr> <chr>   <chr>       <chr>    <dbl> <chr>               <dbl>
    ##  1 2015-12-31 *     ""      Opening Ba… Assets…  5000  USD                 5000 
    ##  2 2015-12-31 *     ""      Opening Ba… Equity… -5000  USD                -5000 
    ##  3 2016-01-01 *     "Landl… Rent        Assets… -1500  USD                -1500 
    ##  4 2016-01-01 *     "Landl… Rent        Expens…  1500  USD                 1500 
    ##  5 2016-01-01 *     "Broke… Buy Stock   Assets… -1000  USD                -1000 
    ##  6 2016-01-01 *     "Broke… Buy Stock   Equity…  1000  USD                 1000 
    ##  7 2016-01-01 *     "Broke… Buy Stock   Assets…     4  SP                  1000 
    ##  8 2016-01-01 *     "Broke… Buy Stock   Equity… -1000  USD                -1000 
    ##  9 2016-01-01 *     "Super… Grocery st… Expens…   501. USD                  501.
    ## 10 2016-01-01 *     "Super… Grocery st… Liabil…  -501. USD                 -501.
    ## # ℹ 32 more rows
    ## # ℹ 5 more variables: hc_commodity <chr>, market_value <dbl>,
    ## #   mv_commodity <chr>, tags <chr>, id <chr>



Here is an example reading in a beancount file generated by ``bean-example``:


.. code:: r
    

    bean_example_file <- tempfile(fileext = ".beancount")
    system(paste("bean-example -o", bean_example_file), ignore.stderr=TRUE)
    df <- register(bean_example_file)
    print(df)


::

    ## # A tibble: 2,907 × 13
    ##    date       mark  payee  description account  amount commodity historical_cost
    ##    <date>     <chr> <chr>  <chr>       <chr>     <dbl> <chr>               <dbl>
    ##  1 2022-01-01 *     ""     Opening Ba… Assets…  3.78e3 USD                3783. 
    ##  2 2022-01-01 *     ""     Opening Ba… Equity… -3.78e3 USD               -3783. 
    ##  3 2022-01-01 *     ""     Allowed co… Income… -1.85e4 IRAUSD           -18500  
    ##  4 2022-01-01 *     ""     Allowed co… Assets…  1.85e4 IRAUSD            18500  
    ##  5 2022-01-04 *     "BANK… Monthly ba… Assets… -4   e0 USD                  -4  
    ##  6 2022-01-04 *     "BANK… Monthly ba… Expens…  4   e0 USD                   4  
    ##  7 2022-01-05 *     "Rive… Paying the… Assets… -2.4 e3 USD               -2400  
    ##  8 2022-01-05 *     "Rive… Paying the… Expens…  2.4 e3 USD                2400  
    ##  9 2022-01-05 *     "Jewe… Eating out  Liabil… -3.74e1 USD                 -37.4
    ## 10 2022-01-05 *     "Jewe… Eating out  Expens…  3.74e1 USD                  37.4
    ## # ℹ 2,897 more rows
    ## # ℹ 5 more variables: hc_commodity <chr>, market_value <dbl>,
    ## #   mv_commodity <chr>, tags <chr>, id <chr>


.. code:: r
    

    suppressPackageStartupMessages(library("dplyr"))
    dplyr::filter(df, grepl("Expenses", account), grepl("trip", tags)) %>% 
        group_by(trip = tags, account) %>% 
        summarize(trip_total = sum(amount), .groups = "drop")


::

    ## # A tibble: 6 × 3
    ##   trip                  account                  trip_total
    ##   <chr>                 <chr>                         <dbl>
    ## 1 trip-los-angeles-2022 Expenses:Food:Alcohol          23.4
    ## 2 trip-los-angeles-2022 Expenses:Food:Coffee           41.9
    ## 3 trip-los-angeles-2022 Expenses:Food:Restaurant      613. 
    ## 4 trip-los-angeles-2023 Expenses:Food:Alcohol          14.8
    ## 5 trip-los-angeles-2023 Expenses:Food:Coffee           12.8
    ## 6 trip-los-angeles-2023 Expenses:Food:Restaurant      739.



Using ``rio::import()`` and ``rio::convert()``
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If one has loaded in the ``ledger`` package one can also use ``rio::import`` to read in the register:


.. code:: r
    

    df2 <- rio::import(bean_example_file)
    all.equal(df, tibble::as_tibble(df2))


::

    ## [1] TRUE



The main advantage of this is that it allows one to use ``rio::convert`` to easily convert plaintext accounting files to several other file formats such as a csv file.  Here is a shell example:

.. code:: bash

    bean-example -o example.beancount
    Rscript --default-packages=ledger,rio -e 'convert("example.beancount", "example.csv")'

``net_worth()``
~~~~~~~~~~~~~~~

Some examples of using the ``net_worth`` function using the example files from the ``register`` examples:


.. code:: r
    

    dates <- seq(as.Date("2016-01-01"), as.Date("2018-01-01"), by="years")
    net_worth(ledger_file, dates)


::

    ## # A tibble: 3 × 6
    ##   date       commodity net_worth assets liabilities revalued
    ##   <date>     <chr>         <dbl>  <dbl>       <dbl>    <dbl>
    ## 1 2016-01-01 USD           5000    5000          0         0
    ## 2 2017-01-01 USD           4361.   4882       -521.        0
    ## 3 2018-01-01 USD           6743.   6264       -521.     1000


.. code:: r
    

    net_worth(hledger_file, dates)


::

    ## # A tibble: 3 × 5
    ##   date       commodity net_worth assets liabilities
    ##   <date>     <chr>         <dbl>  <dbl>       <dbl>
    ## 1 2016-01-01 USD           5000    5000          0 
    ## 2 2017-01-01 USD           4361.   4882       -521.
    ## 3 2018-01-01 USD           6743.   7264       -521.


.. code:: r
    

    net_worth(beancount_file, dates)


::

    ## # A tibble: 3 × 5
    ##   date       commodity net_worth assets liabilities
    ##   <date>     <chr>         <dbl>  <dbl>       <dbl>
    ## 1 2016-01-01 USD           5000    5000          0 
    ## 2 2017-01-01 USD           4361.   4882       -521.
    ## 3 2018-01-01 USD           6743.   7264       -521.


.. code:: r
    

    dates <- seq(min(as.Date(df$date)), max(as.Date(df$date)), by="years")
    net_worth(bean_example_file, dates)


::

    ## # A tibble: 6 × 5
    ##   date       commodity net_worth assets liabilities
    ##   <date>     <chr>         <dbl>  <dbl>       <dbl>
    ## 1 2023-01-01 IRAUSD           0      0           0 
    ## 2 2023-01-01 USD          38821. 40256       -1435.
    ## 3 2023-01-01 VACHR           26     26           0 
    ## 4 2024-01-01 IRAUSD           0      0           0 
    ## 5 2024-01-01 USD          83645. 85451.      -1806.
    ## 6 2024-01-01 VACHR           52     52           0



``prune_coa()``
~~~~~~~~~~~~~~~

Some examples using the ``prune_coa`` function to simplify the "Chart of Account" names to a given maximum depth:


.. code:: r
    

    suppressPackageStartupMessages(library("dplyr"))
    df <- register(bean_example_file) %>% dplyr::filter(!is.na(commodity))
    df %>% prune_coa() %>% 
        group_by(account, mv_commodity) %>% 
        summarize(market_value = sum(market_value), .groups = "drop")


::

    ## # A tibble: 11 × 3
    ##    account     mv_commodity market_value
    ##    <chr>       <chr>               <dbl>
    ##  1 Assets      IRAUSD              6500 
    ##  2 Assets      USD                99028.
    ##  3 Assets      VACHR                102 
    ##  4 Equity      USD                -3783.
    ##  5 Expenses    IRAUSD             49000 
    ##  6 Expenses    USD               224444.
    ##  7 Expenses    VACHR                208 
    ##  8 Income      IRAUSD            -55500 
    ##  9 Income      USD              -313541.
    ## 10 Income      VACHR               -310 
    ## 11 Liabilities USD                -2382.


.. code:: r
    

    df %>% prune_coa(2) %>% 
        group_by(account, mv_commodity) %>%
        summarize(market_value = sum(market_value), .groups = "drop")


::

    ## # A tibble: 17 × 3
    ##    account                     mv_commodity market_value
    ##    <chr>                       <chr>               <dbl>
    ##  1 Assets:US                   IRAUSD              6500 
    ##  2 Assets:US                   USD                99028.
    ##  3 Assets:US                   VACHR                102 
    ##  4 Equity:Opening-Balances     USD                -3783.
    ##  5 Expenses:Financial          USD                  438.
    ##  6 Expenses:Food               USD                17109.
    ##  7 Expenses:Health             USD                 6008.
    ##  8 Expenses:Home               USD                72865.
    ##  9 Expenses:Taxes              IRAUSD             49000 
    ## 10 Expenses:Taxes              USD               124784.
    ## 11 Expenses:Transport          USD                 3240 
    ## 12 Expenses:Vacation           VACHR                208 
    ## 13 Income:US                   IRAUSD            -55500 
    ## 14 Income:US                   USD              -313541.
    ## 15 Income:US                   VACHR               -310 
    ## 16 Liabilities:AccountsPayable USD                    0 
    ## 17 Liabilities:US              USD                -2382.


    
Basic personal accounting reports
+++++++++++++++++++++++++++++++++

Here is some examples using the functions in the package to help generate
various personal accounting reports of the 
beancount example generated by ``bean-example``.

First we load the (mainly tidyverse) libraries we'll be using and adjusting terminal output:


.. code:: r
    

    library("ledger")
    library("dplyr")
    filter <- dplyr::filter
    library("ggplot2")
    library("scales")
    library("tidyr")
    library("zoo")
    filename <- tempfile(fileext = ".beancount")
    system(paste("bean-example -o", filename), ignore.stderr=TRUE)
    df <- register(filename) %>% mutate(yearmon = zoo::as.yearmon(date)) %>%
          filter(commodity=="USD")
    nw <- net_worth(filename)


Then we'll write some convenience functions we'll use over and over again:


.. code:: r
    

    print_tibble_rows <- function(df) {
        print(df, n=nrow(df))
    }
    count_beans <- function(df, filter_str = "", ..., 
                            amount = "amount",
                            commodity="commodity", 
                            cutoff=1e-3) {
        commodity <- sym(commodity)
        amount_var <- sym(amount)
        filter(df, grepl(filter_str, account)) %>% 
            group_by(account, !!commodity, ...) %>%
            summarize(!!amount := sum(!!amount_var), .groups = "drop") %>% 
            filter(abs(!!amount_var) > cutoff & !is.na(!!amount_var)) %>%
            arrange(desc(abs(!!amount_var)))
    }

    
Basic balance sheets
~~~~~~~~~~~~~~~~~~~~

Here is some basic balance sheets (using the market value of our assets):


.. code:: r
    

    print_balance_sheet <- function(df) {
        assets <- count_beans(df, "^Assets", 
                     amount="market_value", commodity="mv_commodity")
        print_tibble_rows(assets)
        liabilities <- count_beans(df, "^Liabilities", 
                           amount="market_value", commodity="mv_commodity")
        print_tibble_rows(liabilities)
    }
    print(nw)


::

    ## # A tibble: 3 × 5
    ##   date       commodity net_worth  assets liabilities
    ##   <date>     <chr>         <dbl>   <dbl>       <dbl>
    ## 1 2024-05-19 IRAUSD        6500    6500           0 
    ## 2 2024-05-19 USD         100688. 102388.      -1701.
    ## 3 2024-05-19 VACHR          110     110           0


.. code:: r
    

    print_balance_sheet(prune_coa(df, 2))


::

    ## # A tibble: 1 × 3
    ##   account   mv_commodity market_value
    ##   <chr>     <chr>               <dbl>
    ## 1 Assets:US USD                 2273.
    ## # A tibble: 1 × 3
    ##   account        mv_commodity market_value
    ##   <chr>          <chr>               <dbl>
    ## 1 Liabilities:US USD                -1701.


.. code:: r
    

    print_balance_sheet(df)


::

    ## # A tibble: 3 × 3
    ##   account                 mv_commodity market_value
    ##   <chr>                   <chr>               <dbl>
    ## 1 Assets:US:BofA:Checking USD              1857.   
    ## 2 Assets:US:ETrade:Cash   USD               417.   
    ## 3 Assets:US:Vanguard:Cash USD                -0.180
    ## # A tibble: 1 × 3
    ##   account                    mv_commodity market_value
    ##   <chr>                      <chr>               <dbl>
    ## 1 Liabilities:US:Chase:Slate USD                -1701.



Basic net worth chart
~~~~~~~~~~~~~~~~~~~~~

Here is a basic chart of one's net worth from the beginning of the plaintext accounting file to today by month:


.. code:: r
    

    next_month <- function(date) {
        zoo::as.Date(zoo::as.yearmon(date) + 1/12)
    }
    nw_dates <- seq(next_month(min(df$date)), next_month(Sys.Date()), by="months")
    df_nw <- net_worth(filename, nw_dates) %>% filter(commodity=="USD")
    ggplot(df_nw, aes(x=date, y=net_worth, colour=commodity, group=commodity)) + 
      geom_line() + scale_y_continuous(labels=scales::dollar)

.. figure:: man/figures/README-net_worth_chart-1.png
    :alt: Basic net worth chart

    Basic net worth chart

Basic income sheets
~~~~~~~~~~~~~~~~~~~


.. code:: r
    

    month_cutoff <- zoo::as.yearmon(Sys.Date()) - 2/12
    compute_income <- function(df) {
        count_beans(df, "^Income", yearmon) %>% 
            mutate(income = -amount) %>%
            select(-amount) %>% ungroup()
    }
    print_income <- function(df) {
        compute_income(df) %>% 
            filter(yearmon >= month_cutoff) %>%
            spread(yearmon, income, fill=0) %>%
            print_tibble_rows()
    }
    compute_expenses <- function(df) {
        count_beans(df, "^Expenses", yearmon) %>% 
            mutate(expenses = amount) %>%
            select(-amount) %>% ungroup()
    }
    print_expenses <- function(df) {
        compute_expenses(df) %>%
            filter(yearmon >= month_cutoff) %>%
            spread(yearmon, expenses, fill=0) %>%
            print_tibble_rows()
    }
    compute_total <- function(df) {
    full_join(compute_income(prune_coa(df)) %>% select(-account),
              compute_expenses(prune_coa(df)) %>% select(-account), 
              by=c("yearmon", "commodity")) %>%
        mutate(income = ifelse(is.na(income), 0, income),
               expenses = ifelse(is.na(expenses), 0, expenses),
               net = income - expenses) %>%
        gather(type, amount, -yearmon, -commodity)
    }
    print_total <- function(df) {
        compute_total(df) %>%
            filter(yearmon >= month_cutoff) %>%
            spread(yearmon, amount, fill=0) %>%
            print_tibble_rows()
    }
    print_total(df)


::

    ## # A tibble: 3 × 5
    ##   commodity type     `Mar 2024` `Apr 2024` `May 2024`
    ##   <chr>     <chr>         <dbl>      <dbl>      <dbl>
    ## 1 USD       expenses      8706.      7496.      2248.
    ## 2 USD       income       11115.     10479.      5240.
    ## 3 USD       net           2410.      2984.      2992.


.. code:: r
    

    print_income(prune_coa(df, 2))


::

    ## # A tibble: 1 × 5
    ##   account   commodity `Mar 2024` `Apr 2024` `May 2024`
    ##   <chr>     <chr>          <dbl>      <dbl>      <dbl>
    ## 1 Income:US USD           11115.     10479.      5240.


.. code:: r
    

    print_expenses(prune_coa(df, 2))


::

    ## # A tibble: 6 × 5
    ##   account            commodity `Mar 2024` `Apr 2024` `May 2024`
    ##   <chr>              <chr>          <dbl>      <dbl>      <dbl>
    ## 1 Expenses:Financial USD             39.8         4        13.0
    ## 2 Expenses:Food      USD            649.        592.      146. 
    ## 3 Expenses:Health    USD            194.        194.       96.9
    ## 4 Expenses:Home      USD           2612.       2602.        0  
    ## 5 Expenses:Taxes     USD           5092.       3984.     1992. 
    ## 6 Expenses:Transport USD            120         120         0


.. code:: r
    

    print_income(df)


::

    ## # A tibble: 5 × 5
    ##   account                         commodity `Mar 2024` `Apr 2024` `May 2024`
    ##   <chr>                           <chr>          <dbl>      <dbl>      <dbl>
    ## 1 Income:US:BayBook:GroupTermLife USD             48.6       48.6       24.3
    ## 2 Income:US:BayBook:Match401k     USD           1800       1200        600  
    ## 3 Income:US:BayBook:Salary        USD           9231.      9231.      4615. 
    ## 4 Income:US:ETrade:GLD:Dividend   USD             95.9        0          0  
    ## 5 Income:US:ETrade:PnL            USD            -59.8        0          0


.. code:: r
    

    print_expenses(df)


::

    ## # A tibble: 21 × 5
    ##    account                            commodity `Mar 2024` `Apr 2024` `May 2024`
    ##    <chr>                              <chr>          <dbl>      <dbl>      <dbl>
    ##  1 Expenses:Financial:Commissions     USD            35.8        0          8.95
    ##  2 Expenses:Financial:Fees            USD             4          4          4   
    ##  3 Expenses:Food:Groceries            USD           282.       270.        66.2 
    ##  4 Expenses:Food:Restaurant           USD           367.       321.        79.4 
    ##  5 Expenses:Health:Dental:Insurance   USD             5.8        5.8        2.9 
    ##  6 Expenses:Health:Life:GroupTermLife USD            48.6       48.6       24.3 
    ##  7 Expenses:Health:Medical:Insurance  USD            54.8       54.8       27.4 
    ##  8 Expenses:Health:Vision:Insurance   USD            84.6       84.6       42.3 
    ##  9 Expenses:Home:Electricity          USD            65         65          0   
    ## 10 Expenses:Home:Internet             USD            80.1       80.0        0   
    ## 11 Expenses:Home:Phone                USD            66.4       57.1        0   
    ## 12 Expenses:Home:Rent                 USD          2400       2400          0   
    ## 13 Expenses:Taxes:Y2023:US:Federal    USD           632.         0          0   
    ## 14 Expenses:Taxes:Y2023:US:State      USD           476.         0          0   
    ## 15 Expenses:Taxes:Y2024:US:CityNYC    USD           350.       350.       175.  
    ## 16 Expenses:Taxes:Y2024:US:Federal    USD          2126.      2126.      1063.  
    ## 17 Expenses:Taxes:Y2024:US:Medicare   USD           213.       213.       107.  
    ## 18 Expenses:Taxes:Y2024:US:SDI        USD             2.24       2.24       1.12
    ## 19 Expenses:Taxes:Y2024:US:SocSec     USD           563.       563.       282.  
    ## 20 Expenses:Taxes:Y2024:US:State      USD           730.       730.       365.  
    ## 21 Expenses:Transport:Tram            USD           120        120          0



And here is a plot of income, expenses, and net income over time:


.. code:: r
    

    ggplot(compute_total(df), aes(x=yearmon, y=amount, group=commodity, colour=commodity)) +
      facet_grid(type ~ .) +
      geom_line() + geom_hline(yintercept=0, linetype="dashed") +
      scale_x_continuous() + scale_y_continuous(labels=scales::comma) 

.. figure:: man/figures/README-income_chart-1.png
    :alt: Monthly income chart

    Monthly income chart

ledger
======

.. image:: https://www.r-pkg.org/badges/version/ledger
    :target: https://cran.r-project.org/package=ledger
    :alt: CRAN Status Badge

.. image:: https://travis-ci.org/trevorld/r-ledger.png?branch=master
    :target: https://travis-ci.org/trevorld/r-ledger
    :alt: Travis-CI Build Status

.. image:: https://ci.appveyor.com/api/projects/status/github/trevorld/r-ledger?branch=master&svg=true
    :target: https://ci.appveyor.com/project/trevorld/r-ledger
    :alt: AppVeyor Build Status

.. image:: https://img.shields.io/codecov/c/github/trevorld/r-ledger/master.svg
    :target: https://codecov.io/github/trevorld/r-ledger?branch=master
    :alt: Coverage Status

.. image:: https://cranlogs.r-pkg.org/badges/ledger
    :target: https://cran.r-project.org/package=ledger
    :alt: RStudio CRAN mirror downloads

.. image:: http://www.repostatus.org/badges/latest/inactive.svg
   :alt: Project Status: Inactive – The project has reached a stable, usable state but is no longer being actively developed: support/maintenance will be provided as time allows.
   :target: http://www.repostatus.org/#inactive

``ledger`` is an R package to import data from `plain text accounting <https://plaintextaccounting.org/>`_ software like `Ledger <https://www.ledger-cli.org/>`_, `HLedger <http://hledger.org/>`_, and `Beancount <http://furius.ca/beancount/>`_ into an R data frame for convenient analysis, plotting, and export.

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
    `ledger <https://www.ledger-cli.org/>`_ (>= 3.1) 

hledger
    `hledger <http://hledger.org/>`_ (>= 1.4)

beancount
    `beancount <http://furius.ca/beancount/>`_ (>= 2.0)

To install hledger and beancount run the following in your shell:

.. code:: bash

    stack install --resolver=lts-12 megaparsec-7.0.4 cassava-megaparsec-2.0.0 config-ini-0.2.3.0 hledger-lib-1.12 hledger-1.12
    pip3 install beancount

`Several pre-compiled Ledger binaries are available <https://www.ledger-cli.org/download.html>`_ (often found in several open source repos).

To run the unit tests you'll also need the suggested R package ``testthat``.

Examples
--------

API
+++

The main function of this package is ``register`` which reads in the register of a plaintext accounting file.  This package also exports S3 methods so one can use ``rio::import`` to read in a register, a ``net_worth`` convenience function, and a ``prune_coa`` convenience function.

register
~~~~~~~~

Here are some examples of very basic files stored within the package:


.. sourcecode:: r
    

    library("ledger")
    options(width=180)
    ledger_file <- system.file("extdata", "example.ledger", package = "ledger") 
    register(ledger_file)


::

    ## # A tibble: 42 x 8
    ##    date       mark  payee       description                     account                    amount commodity comment
    ##    <date>     <chr> <chr>       <chr>                           <chr>                       <dbl> <chr>     <chr>  
    ##  1 2015-12-31 *     <NA>        Opening Balances                Assets:JT-Checking          5000  USD       <NA>   
    ##  2 2015-12-31 *     <NA>        Opening Balances                Equity:Opening             -5000  USD       <NA>   
    ##  3 2016-01-01 *     Landlord    Rent                            Assets:JT-Checking         -1500  USD       <NA>   
    ##  4 2016-01-01 *     Landlord    Rent                            Expenses:Shelter:Rent       1500  USD       <NA>   
    ##  5 2016-01-01 *     Brokerage   Buy Stock                       Assets:JT-Checking         -1000  USD       <NA>   
    ##  6 2016-01-01 *     Brokerage   Buy Stock                       Equity:Transfer             1000  USD       <NA>   
    ##  7 2016-01-01 *     Brokerage   Buy Stock                       Assets:JT-Brokerage            4  SP        <NA>   
    ##  8 2016-01-01 *     Brokerage   Buy Stock                       Equity:Transfer            -1000  USD       <NA>   
    ##  9 2016-01-01 *     Supermarket Grocery store ;; Link: ^grocery Expenses:Food:Grocery        501. USD       <NA>   
    ## 10 2016-01-01 *     Supermarket Grocery store ;; Link: ^grocery Liabilities:JT-Credit-Card  -501. USD       <NA>   
    ## # … with 32 more rows


.. sourcecode:: r
    

    hledger_file <- system.file("extdata", "example.hledger", package = "ledger") 
    register(hledger_file)


::

    ## # A tibble: 42 x 11
    ##    date       mark  payee       description      account                    amount commodity historical_cost hc_commodity market_value mv_commodity
    ##    <date>     <chr> <chr>       <chr>            <chr>                       <dbl> <chr>               <dbl> <chr>               <dbl> <chr>       
    ##  1 2015-12-31 *     <NA>        Opening Balances Assets:JT-Checking          5000  USD                 5000  USD                 5000  USD         
    ##  2 2015-12-31 *     <NA>        Opening Balances Equity:Opening             -5000  USD                -5000  USD                -5000  USD         
    ##  3 2016-01-01 *     Landlord    Rent             Assets:JT-Checking         -1500  USD                -1500  USD                -1500  USD         
    ##  4 2016-01-01 *     Landlord    Rent             Expenses:Shelter:Rent       1500  USD                 1500  USD                 1500  USD         
    ##  5 2016-01-01 *     Brokerage   Buy Stock        Assets:JT-Checking         -1000  USD                -1000  USD                -1000  USD         
    ##  6 2016-01-01 *     Brokerage   Buy Stock        Equity:Transfer             1000  USD                 1000  USD                 1000  USD         
    ##  7 2016-01-01 *     Brokerage   Buy Stock        Assets:JT-Brokerage            4  SP                  1000  USD                 2000  USD         
    ##  8 2016-01-01 *     Brokerage   Buy Stock        Equity:Transfer            -1000  USD                -1000  USD                -1000  USD         
    ##  9 2016-01-01 *     Supermarket Grocery store    Expenses:Food:Grocery        501. USD                  501. USD                  501. USD         
    ## 10 2016-01-01 *     Supermarket Grocery store    Liabilities:JT-Credit-Card  -501. USD                 -501. USD                 -501. USD         
    ## # … with 32 more rows


.. sourcecode:: r
    

    beancount_file <- system.file("extdata", "example.beancount", package = "ledger") 
    register(beancount_file)


::

    ## # A tibble: 42 x 12
    ##    date       mark  payee       description      account                    amount commodity historical_cost hc_commodity market_value mv_commodity tags 
    ##    <chr>      <chr> <chr>       <chr>            <chr>                       <dbl> <chr>               <dbl> <chr>               <dbl> <chr>        <chr>
    ##  1 2015-12-31 *     ""          Opening Balances Assets:JT-Checking          5000  USD                 5000  USD                 5000  USD          ""   
    ##  2 2015-12-31 *     ""          Opening Balances Equity:Opening             -5000  USD                -5000  USD                -5000  USD          ""   
    ##  3 2016-01-01 *     Landlord    Rent             Assets:JT-Checking         -1500  USD                -1500  USD                -1500  USD          ""   
    ##  4 2016-01-01 *     Landlord    Rent             Expenses:Shelter:Rent       1500  USD                 1500  USD                 1500  USD          ""   
    ##  5 2016-01-01 *     Brokerage   Buy Stock        Assets:JT-Checking         -1000  USD                -1000  USD                -1000  USD          ""   
    ##  6 2016-01-01 *     Brokerage   Buy Stock        Equity:Transfer             1000  USD                 1000  USD                 1000  USD          ""   
    ##  7 2016-01-01 *     Brokerage   Buy Stock        Assets:JT-Brokerage            4  SP                  1000  USD                 2000  USD          ""   
    ##  8 2016-01-01 *     Brokerage   Buy Stock        Equity:Transfer            -1000  USD                -1000  USD                -1000  USD          ""   
    ##  9 2016-01-01 *     Supermarket Grocery store    Expenses:Food:Grocery        501. USD                  501. USD                  501. USD          ""   
    ## 10 2016-01-01 *     Supermarket Grocery store    Liabilities:JT-Credit-Card  -501. USD                 -501. USD                 -501. USD          ""   
    ## # … with 32 more rows



Here is an example reading in a beancount file generated by ``bean-example``:


.. sourcecode:: r
    

    bean_example_file <- tempfile(fileext = ".beancount")
    system(paste("bean-example -o", bean_example_file), ignore.stderr=TRUE)
    df <- register(bean_example_file)
    options(width=240)
    print(df)


::

    ## # A tibble: 2,639 x 12
    ##    date       mark  payee       description                          account                        amount commodity historical_cost hc_commodity market_value mv_commodity tags 
    ##    <chr>      <chr> <chr>       <chr>                                <chr>                           <dbl> <chr>               <dbl> <chr>               <dbl> <chr>        <chr>
    ##  1 2017-01-01 *     ""          Opening Balance for checking account Assets:US:BofA:Checking        3810.  USD                3810.  USD                3810.  USD          ""   
    ##  2 2017-01-01 *     ""          Opening Balance for checking account Equity:Opening-Balances       -3810.  USD               -3810.  USD               -3810.  USD          ""   
    ##  3 2017-01-01 *     ""          Allowed contributions for one year   Income:US:Federal:PreTax401k -18500   IRAUSD           -18500   IRAUSD           -18500   IRAUSD       ""   
    ##  4 2017-01-01 *     ""          Allowed contributions for one year   Assets:US:Federal:PreTax401k  18500   IRAUSD            18500   IRAUSD            18500   IRAUSD       ""   
    ##  5 2017-01-04 *     BANK FEES   Monthly bank fee                     Assets:US:BofA:Checking          -4   USD                  -4   USD                  -4   USD          ""   
    ##  6 2017-01-04 *     BANK FEES   Monthly bank fee                     Expenses:Financial:Fees           4   USD                   4   USD                   4   USD          ""   
    ##  7 2017-01-04 *     Chichipotle Eating out with work buddies         Liabilities:US:Chase:Slate      -34.5 USD                 -34.5 USD                 -34.5 USD          ""   
    ##  8 2017-01-04 *     Chichipotle Eating out with work buddies         Expenses:Food:Restaurant         34.5 USD                  34.5 USD                  34.5 USD          ""   
    ##  9 2017-01-05 *     BayBook     Payroll                              Assets:US:BofA:Checking        1351.  USD                1351.  USD                1351.  USD          ""   
    ## 10 2017-01-05 *     BayBook     Payroll                              Assets:US:Vanguard:Cash        1200   USD                1200   USD                1200   USD          ""   
    ## # … with 2,629 more rows


.. sourcecode:: r
    

    suppressPackageStartupMessages(library("dplyr"))
    dplyr::filter(df, grepl("Expenses", account), grepl("trip", tags)) %>% 
        group_by(trip = tags, account) %>% 
        summarise(trip_total = sum(amount))


::

    ## # A tibble: 2 x 3
    ## # Groups:   trip [1]
    ##   trip               account                  trip_total
    ##   <chr>              <chr>                         <dbl>
    ## 1 trip-new-york-2018 Expenses:Food:Coffee           79.4
    ## 2 trip-new-york-2018 Expenses:Food:Restaurant      838.



Using rio::import and rio::convert
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If one has loaded in the ``ledger`` package one can also use ``rio::import`` to read in the register:


.. sourcecode:: r
    

    df <- rio::import(beancount_file)
    all.equal(register(ledger_file), rio::import(ledger_file))


::

    ## [1] TRUE



The main advantage of this is that it allows one to use ``rio::convert`` to easily convert plaintext accounting files to several other file formats such as a csv file.  Here is a shell example:

.. code:: bash

    bean-example -o example.beancount
    Rscript --default-packages=ledger,rio -e 'convert("example.beancount", "example.csv")'

net_worth
~~~~~~~~~

Some examples of using the ``net_worth`` function using the example files from the ``register`` examples:


.. sourcecode:: r
    

    dates <- seq(as.Date("2016-01-01"), as.Date("2018-01-01"), by="years")
    net_worth(ledger_file, dates)


::

    ## # A tibble: 3 x 6
    ##   date       commodity net_worth assets liabilities revalued
    ##   <date>     <chr>         <dbl>  <dbl>       <dbl>    <dbl>
    ## 1 2016-01-01 USD           5000    5000          0         0
    ## 2 2017-01-01 USD           4361.   4882       -521.        0
    ## 3 2018-01-01 USD           6743.   6264       -521.     1000


.. sourcecode:: r
    

    net_worth(hledger_file, dates)


::

    ## # A tibble: 3 x 5
    ##   date       commodity net_worth assets liabilities
    ##   <date>     <chr>         <dbl>  <dbl>       <dbl>
    ## 1 2016-01-01 USD           5000    5000          0 
    ## 2 2017-01-01 USD           4361.   4882       -521.
    ## 3 2018-01-01 USD           6743.   7264       -521.


.. sourcecode:: r
    

    net_worth(beancount_file, dates)


::

    ## # A tibble: 3 x 5
    ##   date       commodity net_worth assets liabilities
    ##   <date>     <chr>         <dbl>  <dbl>       <dbl>
    ## 1 2016-01-01 USD           5000    5000          0 
    ## 2 2017-01-01 USD           4361.   4882       -521.
    ## 3 2018-01-01 USD           6743.   7264       -521.


.. sourcecode:: r
    

    net_worth(bean_example_file, dates)


::

    ## # A tibble: 3 x 5
    ##   date       commodity net_worth assets liabilities
    ##   <date>     <chr>         <dbl>  <dbl>       <dbl>
    ## 1 2018-01-01 IRAUSD           0      0           0 
    ## 2 2018-01-01 USD          42524. 43114.       -590.
    ## 3 2018-01-01 VACHR          130    130           0



prune_coa
~~~~~~~~~

Some examples using the ``prune_coa`` function to simplify the "Chart of Account" names to a given maximum depth:


.. sourcecode:: r
    

    suppressPackageStartupMessages(library("dplyr"))
    df <- register(bean_example_file) %>% dplyr::filter(!is.na(commodity))
    df %>% prune_coa() %>% 
        group_by(account, mv_commodity) %>% 
        summarize(market_value = sum(market_value))


::

    ## # A tibble: 11 x 3
    ## # Groups:   account [5]
    ##    account     mv_commodity market_value
    ##    <chr>       <chr>               <dbl>
    ##  1 Assets      IRAUSD             11300 
    ##  2 Assets      USD                99651.
    ##  3 Assets      VACHR                130 
    ##  4 Equity      USD                -3810.
    ##  5 Expenses    IRAUSD             44200 
    ##  6 Expenses    USD               207412.
    ##  7 Expenses    VACHR                160 
    ##  8 Income      IRAUSD            -55500 
    ##  9 Income      USD              -292148.
    ## 10 Income      VACHR               -290 
    ## 11 Liabilities USD                -1800.


.. sourcecode:: r
    

    df %>% prune_coa(2) %>% 
        group_by(account, mv_commodity) %>%
        summarize(market_value = sum(market_value))


::

    ## # A tibble: 17 x 3
    ## # Groups:   account [12]
    ##    account                     mv_commodity market_value
    ##    <chr>                       <chr>               <dbl>
    ##  1 Assets:US                   IRAUSD             11300 
    ##  2 Assets:US                   USD                99651.
    ##  3 Assets:US                   VACHR                130 
    ##  4 Equity:Opening-Balances     USD                -3810.
    ##  5 Expenses:Financial          USD                  412.
    ##  6 Expenses:Food               USD                14856.
    ##  7 Expenses:Health             USD                 5620.
    ##  8 Expenses:Home               USD                67746.
    ##  9 Expenses:Taxes              IRAUSD             44200 
    ## 10 Expenses:Taxes              USD               115658.
    ## 11 Expenses:Transport          USD                 3120 
    ## 12 Expenses:Vacation           VACHR                160 
    ## 13 Income:US                   IRAUSD            -55500 
    ## 14 Income:US                   USD              -292148.
    ## 15 Income:US                   VACHR               -290 
    ## 16 Liabilities:AccountsPayable USD                    0 
    ## 17 Liabilities:US              USD                -1800.


    
Basic personal accounting reports
+++++++++++++++++++++++++++++++++

Here is some examples using the functions in the package to help generate
various personal accounting reports of the 
beancount example generated by ``bean-example``.

First we load the (mainly tidyverse) libraries we'll be using and adjusting terminal output:


.. sourcecode:: r
    

    options(width=240) # tibble output looks better in wide terminal output
    library("ledger")
    library("dplyr")
    filter <- dplyr::filter
    library("ggplot2")
    library("scales")
    library("tidyr")
    library("zoo")
    filename <- tempfile(fileext = ".beancount")
    system(paste("bean-example -o", filename), ignore.stderr=TRUE)
    df <- register(filename) %>% mutate(yearmon = zoo::as.yearmon(date))
    nw <- net_worth(filename)


Then we'll write some convenience functions we'll use over and over again:


.. sourcecode:: r
    

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
            summarize(!!amount := sum(!!amount_var)) %>% 
            filter(abs(!!amount_var) > cutoff & !is.na(!!amount_var)) %>%
            arrange(desc(abs(!!amount_var)))
    }

    
Basic balance sheets
~~~~~~~~~~~~~~~~~~~~

Here is some basic balance sheets (using the market value of our assets):


.. sourcecode:: r
    

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

    ## # A tibble: 3 x 5
    ##   date       commodity net_worth assets liabilities
    ##   <date>     <chr>         <dbl>  <dbl>       <dbl>
    ## 1 2019-03-23 IRAUSD       11300  11300           0 
    ## 2 2019-03-23 USD          95772. 97671.      -1900.
    ## 3 2019-03-23 VACHR           66     66           0


.. sourcecode:: r
    

    print_balance_sheet(prune_coa(df, 2))


::

    ## # A tibble: 3 x 3
    ## # Groups:   account [1]
    ##   account   mv_commodity market_value
    ##   <chr>     <chr>               <dbl>
    ## 1 Assets:US USD                97671.
    ## 2 Assets:US IRAUSD             11300 
    ## 3 Assets:US VACHR                 66 
    ## # A tibble: 1 x 3
    ## # Groups:   account [1]
    ##   account        mv_commodity market_value
    ##   <chr>          <chr>               <dbl>
    ## 1 Liabilities:US USD                -1900.


.. sourcecode:: r
    

    print_balance_sheet(df)


::

    ## # A tibble: 11 x 3
    ## # Groups:   account [11]
    ##    account                      mv_commodity market_value
    ##    <chr>                        <chr>               <dbl>
    ##  1 Assets:US:Vanguard:RGAGX     USD              45730.  
    ##  2 Assets:US:Vanguard:VBMPX     USD              27230.  
    ##  3 Assets:US:Federal:PreTax401k IRAUSD           11300   
    ##  4 Assets:US:ETrade:ITOT        USD              11205.  
    ##  5 Assets:US:ETrade:GLD         USD               5226.  
    ##  6 Assets:US:ETrade:VEA         USD               3155   
    ##  7 Assets:US:ETrade:VHT         USD               2870.  
    ##  8 Assets:US:BofA:Checking      USD               1664.  
    ##  9 Assets:US:ETrade:Cash        USD                592.  
    ## 10 Assets:US:Hoogle:Vacation    VACHR               66   
    ## 11 Assets:US:Vanguard:Cash      USD                 -0.04
    ## # A tibble: 1 x 3
    ## # Groups:   account [1]
    ##   account                    mv_commodity market_value
    ##   <chr>                      <chr>               <dbl>
    ## 1 Liabilities:US:Chase:Slate USD                -1900.



Basic net worth chart
~~~~~~~~~~~~~~~~~~~~~

Here is a basic chart of one's net worth from the beginning of the plaintext accounting file to today by month:

.. code:: r

    next_month <- function(date) {
        zoo::as.Date(zoo::as.yearmon(date) + 1/12)
    }
    nw_dates <- seq(next_month(min(df$date)), next_month(Sys.Date()), by="months")
    df_nw <- net_worth(filename, nw_dates) %>% filter(!is.na(commodity))
    ggplot(df_nw, aes(x=date, y=net_worth, colour=commodity, group=commodity)) + 
      geom_line() + scale_y_continuous(labels=scales::dollar)

.. image:: https://www.trevorldavis.com/share/ledger/basic_net_worth_plot.svg
   :alt: Monthly net worth chart

Basic income sheets
~~~~~~~~~~~~~~~~~~~


.. sourcecode:: r
    

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

    ## # A tibble: 9 x 5
    ##   commodity type     `Jan 2019` `Feb 2019` `Mar 2019`
    ##   <chr>     <chr>         <dbl>      <dbl>      <dbl>
    ## 1 IRAUSD    expenses      3600       2400       1200 
    ## 2 IRAUSD    income       18500          0          0 
    ## 3 IRAUSD    net          14900      -2400      -1200 
    ## 4 USD       expenses      9438.      7294.      2552.
    ## 5 USD       income       15119.     10479.      6136.
    ## 6 USD       net           5681.      3186.      3584.
    ## 7 VACHR     expenses         0          0          0 
    ## 8 VACHR     income          15         10          5 
    ## 9 VACHR     net             15         10          5


.. sourcecode:: r
    

    print_income(prune_coa(df, 2))


::

    ## # A tibble: 3 x 5
    ##   account   commodity `Jan 2019` `Feb 2019` `Mar 2019`
    ##   <chr>     <chr>          <dbl>      <dbl>      <dbl>
    ## 1 Income:US IRAUSD        18500          0          0 
    ## 2 Income:US USD           15119.     10479.      6136.
    ## 3 Income:US VACHR            15         10          5


.. sourcecode:: r
    

    print_expenses(prune_coa(df, 2))


::

    ## # A tibble: 7 x 5
    ##   account            commodity `Jan 2019` `Feb 2019` `Mar 2019`
    ##   <chr>              <chr>          <dbl>      <dbl>      <dbl>
    ## 1 Expenses:Financial USD             21.9         4        21.9
    ## 2 Expenses:Food      USD            438.        396.      441. 
    ## 3 Expenses:Health    USD            291.        194.       96.9
    ## 4 Expenses:Home      USD           2590.       2596.        0  
    ## 5 Expenses:Taxes     IRAUSD        3600        2400      1200  
    ## 6 Expenses:Taxes     USD           5977.       3984.     1992. 
    ## 7 Expenses:Transport USD            120         120         0


.. sourcecode:: r
    

     print_income(df)


::

    ## # A tibble: 7 x 5
    ##   account                        commodity `Jan 2019` `Feb 2019` `Mar 2019`
    ##   <chr>                          <chr>          <dbl>      <dbl>      <dbl>
    ## 1 Income:US:ETrade:Dividends     USD              0          0        138. 
    ## 2 Income:US:ETrade:Gains         USD              0          0        158. 
    ## 3 Income:US:Federal:PreTax401k   IRAUSD       18500          0          0  
    ## 4 Income:US:Hoogle:GroupTermLife USD             73.0       48.6       24.3
    ## 5 Income:US:Hoogle:Match401k     USD           1200       1200       1200  
    ## 6 Income:US:Hoogle:Salary        USD          13846.      9231.      4615. 
    ## 7 Income:US:Hoogle:Vacation      VACHR           15         10          5


.. sourcecode:: r
    

    print_expenses(df)


::

    ## # A tibble: 20 x 5
    ##    account                                    commodity `Jan 2019` `Feb 2019` `Mar 2019`
    ##    <chr>                                      <chr>          <dbl>      <dbl>      <dbl>
    ##  1 Expenses:Financial:Commissions             USD            17.9        0         17.9 
    ##  2 Expenses:Financial:Fees                    USD             4          4          4   
    ##  3 Expenses:Food:Groceries                    USD           157.       148.       214.  
    ##  4 Expenses:Food:Restaurant                   USD           281.       248.       228.  
    ##  5 Expenses:Health:Dental:Insurance           USD             8.7        5.8        2.9 
    ##  6 Expenses:Health:Life:GroupTermLife         USD            73.0       48.6       24.3 
    ##  7 Expenses:Health:Medical:Insurance          USD            82.1       54.8       27.4 
    ##  8 Expenses:Health:Vision:Insurance           USD           127.        84.6       42.3 
    ##  9 Expenses:Home:Electricity                  USD            65         65          0   
    ## 10 Expenses:Home:Internet                     USD            79.9       80.0        0   
    ## 11 Expenses:Home:Phone                        USD            45.5       50.8        0   
    ## 12 Expenses:Home:Rent                         USD          2400       2400          0   
    ## 13 Expenses:Taxes:Y2019:US:CityNYC            USD           525.       350.       175.  
    ## 14 Expenses:Taxes:Y2019:US:Federal            USD          3189.      2126.      1063.  
    ## 15 Expenses:Taxes:Y2019:US:Federal:PreTax401k IRAUSD       3600       2400       1200   
    ## 16 Expenses:Taxes:Y2019:US:Medicare           USD           320.       213.       107.  
    ## 17 Expenses:Taxes:Y2019:US:SDI                USD             3.36       2.24       1.12
    ## 18 Expenses:Taxes:Y2019:US:SocSec             USD           845.       563.       282.  
    ## 19 Expenses:Taxes:Y2019:US:State              USD          1095.       730.       365.  
    ## 20 Expenses:Transport:Tram                    USD           120        120          0



And here is a plot of income, expenses, and net income over time:

.. code:: r

    ggplot(compute_total(df), aes(x=yearmon, y=amount, group=commodity, colour=commodity)) +
      facet_grid(type ~ .) +
      geom_line() + geom_hline(yintercept=0, linetype="dashed") +
      scale_x_continuous() + scale_y_continuous(labels=scales::comma) 

.. image:: https://www.trevorldavis.com/share/ledger/basic_income_plot.svg
   :alt: Monthly income chart


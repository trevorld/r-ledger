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

.. image:: http://www.repostatus.org/badges/latest/active.svg
   :alt: Project Status: Active – The project has reached a stable, usable state and is being actively developed.
   :target: http://www.repostatus.org/#active

``ledger`` is an R package to import data from `plain text accounting <https://plaintextaccounting.org/>`_ software like `Ledger <https://www.ledger-cli.org/>`_, `HLedger <http://hledger.org/>`_, and `Beancount <http://furius.ca/beancount/>`_ into an R data frame for convenient analysis, plotting, and export.

Right now it supports reading in the register from ``ledger``, ``hledger``, and ``beancount`` files.  

.. contents::

Installation
------------

To install the last version released to CRAN use the following command::

    > install.packages("ledger")

To install the development version of the ``ledger`` package (and its R package dependencies) use the ``install_github`` function from the ``remotes`` package in R::
    
    > remotes::install_github("trevorld/r-ledger")

This package also has some system dependencies that need to be installed depending on which plaintext accounting files you wish to read to be able to read in:

ledger
    * `ledger <https://www.ledger-cli.org/>`_ (>= 3.1) 

hledger
    * `hledger <http://hledger.org/>`_ (>= 1.4)

beancount
    * `beancount <http://furius.ca/beancount/>`_ (>= 2.0)

To install hledger and beancount run::

    $ stack install --resolver=lts-12 hledger-lib-1.12 hledger-1.12
    $ pip3 install beancount

`Several pre-compiled Ledger binaries are available <https://www.ledger-cli.org/download.html>`_ (often found in several open source repos).

To run the unit tests you'll also need the suggested R package ``testthat``.

Examples
--------

API
+++

The main function of this package is ``register`` which reads in the register of a plaintext accounting file.  This package also exports S3 methods so one can use ``rio::import`` to read in a register, a ``net_worth`` convenience function, and a ``prune_coa`` convenience function.

register
~~~~~~~~

Here are some examples of very basic files stored within the package::

    > library("ledger")
    > options(width=180)
    > example_ledger_file <- system.file("extdata", "example.ledger", package = "ledger") 
    > register(example_ledger_file)
    # A tibble: 42 x 8
       date       mark  payee       description                     account                    amount commodity comment
       <date>     <chr> <chr>       <chr>                           <chr>                       <dbl> <chr>     <chr>  
     1 2015-12-31 *     NA          Opening Balances                Assets:JT-Checking          5000  USD       NA     
     2 2015-12-31 *     NA          Opening Balances                Equity:Opening             -5000  USD       NA     
     3 2016-01-01 *     Landlord    Rent                            Assets:JT-Checking         -1500  USD       NA     
     4 2016-01-01 *     Landlord    Rent                            Expenses:Shelter:Rent       1500  USD       NA     
     5 2016-01-01 *     Brokerage   Buy Stock                       Assets:JT-Checking         -1000  USD       NA     
     6 2016-01-01 *     Brokerage   Buy Stock                       Equity:Transfer             1000  USD       NA     
     7 2016-01-01 *     Brokerage   Buy Stock                       Assets:JT-Brokerage            4  SP        NA     
     8 2016-01-01 *     Brokerage   Buy Stock                       Equity:Transfer            -1000  USD       NA     
     9 2016-01-01 *     Supermarket Grocery store ;; Link: ^grocery Expenses:Food:Grocery        501. USD       NA     
    10 2016-01-01 *     Supermarket Grocery store ;; Link: ^grocery Liabilities:JT-Credit-Card  -501. USD       NA  

::

    > example_hledger_file <- system.file("extdata", "example.hledger", package = "ledger") 
    > register(example_hledger_file)
    # A tibble: 42 x 11
       date       mark  payee       description      account                    amount commodity historical_cost hc_commodity market_value mv_commodity
       <date>     <chr> <chr>       <chr>            <chr>                       <dbl> <chr>               <dbl> <chr>               <dbl> <chr>       
     1 2015-12-31 *     NA          Opening Balances Assets:JT-Checking          5000  USD                 5000  USD                 5000  USD         
     2 2015-12-31 *     NA          Opening Balances Equity:Opening             -5000  USD                -5000  USD                -5000  USD         
     3 2016-01-01 *     Landlord    Rent             Assets:JT-Checking         -1500  USD                -1500  USD                -1500  USD         
     4 2016-01-01 *     Landlord    Rent             Expenses:Shelter:Rent       1500  USD                 1500  USD                 1500  USD         
     5 2016-01-01 *     Brokerage   Buy Stock        Assets:JT-Checking         -1000  USD                -1000  USD                -1000  USD         
     6 2016-01-01 *     Brokerage   Buy Stock        Equity:Transfer             1000  USD                 1000  USD                 1000  USD         
     7 2016-01-01 *     Brokerage   Buy Stock        Assets:JT-Brokerage            4  SP                  1000  USD                 2000  USD         
     8 2016-01-01 *     Brokerage   Buy Stock        Equity:Transfer            -1000  USD                -1000  USD                -1000  USD         
     9 2016-01-01 *     Supermarket Grocery store    Expenses:Food:Grocery        501. USD                  501. USD                  501. USD         
    10 2016-01-01 *     Supermarket Grocery store    Liabilities:JT-Credit-Card  -501. USD                 -501. USD                 -501. USD         
    # ... with 32 more rows

::

    > example_beancount_file <- system.file("extdata", "example.beancount", package = "ledger") 
    > register(example_beancount_file)
    # A tibble: 42 x 12
       date       mark  payee       description      account                    amount commodity historical_cost hc_commodity market_value mv_commodity tags 
       <chr>      <chr> <chr>       <chr>            <chr>                       <dbl> <chr>               <dbl> <chr>               <dbl> <chr>        <chr>
     1 2015-12-31 *     ""          Opening Balances Assets:JT-Checking          5000  USD                 5000  USD                 5000  USD          ""   
     2 2015-12-31 *     ""          Opening Balances Equity:Opening             -5000  USD                -5000  USD                -5000  USD          ""   
     3 2016-01-01 *     Landlord    Rent             Assets:JT-Checking         -1500  USD                -1500  USD                -1500  USD          ""   
     4 2016-01-01 *     Landlord    Rent             Expenses:Shelter:Rent       1500  USD                 1500  USD                 1500  USD          ""   
     5 2016-01-01 *     Brokerage   Buy Stock        Assets:JT-Checking         -1000  USD                -1000  USD                -1000  USD          ""   
     6 2016-01-01 *     Brokerage   Buy Stock        Equity:Transfer             1000  USD                 1000  USD                 1000  USD          ""   
     7 2016-01-01 *     Brokerage   Buy Stock        Assets:JT-Brokerage            4  SP                  1000  USD                 2000  USD          ""   
     8 2016-01-01 *     Brokerage   Buy Stock        Equity:Transfer            -1000  USD                -1000  USD                -1000  USD          ""   
     9 2016-01-01 *     Supermarket Grocery store    Expenses:Food:Grocery        501. USD                  501. USD                  501. USD          ""   
    10 2016-01-01 *     Supermarket Grocery store    Liabilities:JT-Credit-Card  -501. USD                 -501. USD                 -501. USD          ""   
    # ... with 32 more rows

Here is an example reading in a beancount file generated by ``bean-example``::

    > bean_example_file <- tempfile(fileext = ".beancount")
    > system(paste("bean-example -o", bean_example_file), ignore.stderr=TRUE)
    > df <- register(bean_example_file)
    > options(width=240)
    > print(df)
    # A tibble: 3,544 x 12
       date       mark  payee                description                          account                        amount commodity historical_cost hc_commodity market_value mv_commodity tags 
       <chr>      <chr> <chr>                <chr>                                <chr>                           <dbl> <chr>               <dbl> <chr>               <dbl> <chr>        <chr>
     1 2016-01-01 *     ""                   Opening Balance for checking account Assets:US:BofA:Checking        4459.  USD                4459.  USD                4459.  USD          ""   
     2 2016-01-01 *     ""                   Opening Balance for checking account Equity:Opening-Balances       -4459.  USD               -4459.  USD               -4459.  USD          ""   
     3 2016-01-01 *     ""                   Allowed contributions for one year   Income:US:Federal:PreTax401k -18000   IRAUSD           -18000   IRAUSD           -18000   IRAUSD       ""   
     4 2016-01-01 *     ""                   Allowed contributions for one year   Assets:US:Federal:PreTax401k  18000   IRAUSD            18000   IRAUSD            18000   IRAUSD       ""   
     5 2016-01-02 *     Goba Goba            Eating out                           Liabilities:US:Chase:Slate      -21.7 USD                 -21.7 USD                 -21.7 USD          ""   
     6 2016-01-02 *     Goba Goba            Eating out                           Expenses:Food:Restaurant         21.7 USD                  21.7 USD                  21.7 USD          ""   
     7 2016-01-04 *     BANK FEES            Monthly bank fee                     Assets:US:BofA:Checking          -4   USD                  -4   USD                  -4   USD          ""   
     8 2016-01-04 *     BANK FEES            Monthly bank fee                     Expenses:Financial:Fees           4   USD                   4   USD                   4   USD          ""   
     9 2016-01-05 *     RiverBank Properties Paying the rent                      Assets:US:BofA:Checking       -2400   USD               -2400   USD               -2400   USD          ""   
    10 2016-01-05 *     RiverBank Properties Paying the rent                      Expenses:Home:Rent             2400   USD                2400   USD                2400   USD          ""   
    # ... with 3,534 more rows
    > suppressPackageStartupMessages(library("dplyr"))
    > dplyr::filter(df, grepl("Expenses", account), grepl("trip", tags)) %>% 
    + group_by(trip = tags, account) %>% 
    + summarise(trip_total = sum(amount))
    # A tibble: 5 x 3
    # Groups:   trip [?]
      trip               account                  trip_total
      <chr>              <chr>                         <dbl>
    1 trip-chicago-2017  Expenses:Food:Alcohol         83.4 
    2 trip-chicago-2017  Expenses:Food:Coffee           6.43
    3 trip-chicago-2017  Expenses:Food:Restaurant     540.  
    4 trip-new-york-2017 Expenses:Food:Coffee          87.7 
    5 trip-new-york-2017 Expenses:Food:Restaurant     599.  

Using rio::import and rio::convert
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If one has loaded in the ``ledger`` package one can also use ``rio::import`` to read in the register::

    > df <- rio::import(example_beancount_file)
    > all.equal(register(example_ledger_file), rio::import(example_ledger_file))
    > TRUE

The main advantage of this is that it allows one to use ``rio::convert`` to easily convert plaintext accounting files to several other file formats such as a csv file::

    $ bean-example -o example.beancount
    $ Rscript --default-packages=ledger,rio -e 'convert("example.beancount", "example.csv")'

net_worth
~~~~~~~~~

Some examples of using the ``net_worth`` function using the example files from the ``register`` examples::

    > dates <- seq(as.Date("2016-01-01"), as.Date("2018-01-01"), by="years")
    # A tibble: 3 x 6
      date       commodity net_worth assets liabilities revalued
      <date>     <chr>         <dbl>  <dbl>       <dbl>    <dbl>
    1 2016-01-01 USD           5000    5000          0         0
    2 2017-01-01 USD           4361.   4882       -521.        0
    3 2018-01-01 USD           6743.   6264       -521.     1000
    > net_worth(example_hledger_file, dates)
    # A tibble: 3 x 5
      date       commodity net_worth assets liabilities
      <date>     <chr>         <dbl>  <dbl>       <dbl>
    1 2016-01-01 USD           5000    5000          0 
    2 2017-01-01 USD           4361.   4882       -521.
    3 2018-01-01 USD           6743.   7264       -521.
    > net_worth(example_beancount_file, dates)
    # A tibble: 3 x 5
      date       commodity net_worth assets liabilities
      <date>     <chr>         <dbl>  <dbl>       <dbl>
    1 2016-01-01 USD           5000    5000          0 
    2 2017-01-01 USD           4361.   4882       -521.
    3 2018-01-01 USD           6743.   7264       -521.
    > net_worth(bean_example_file, dates)
    # A tibble: 6 x 5
      date       commodity net_worth assets liabilities
      <date>     <chr>         <dbl>  <dbl>       <dbl>
    1 2017-01-01 IRAUSD           0      0           0 
    2 2017-01-01 USD          45841. 46394.       -553.
    3 2017-01-01 VACHR          130    130           0 
    4 2018-01-01 IRAUSD           0      0           0 
    5 2018-01-01 USD          88593. 90163.      -1569.
    6 2018-01-01 VACHR           12     12           0 

prune_coa
~~~~~~~~~

Some examples using the ``prune_coa`` function to simplify the "Chart of Account" names to a given maximum depth::

    > suppressPackageStartupMessages(library("dplyr"))
    > df <- register(bean_example_file) %>% dplyr::filter(!is.na(commodity))
    > df %>% prune_coa() %>% 
    + group_by(account, mv_commodity) %>% 
    + summarize(market_value = sum(market_value))
    # A tibble: 11 x 3
    # Groups:   account [?]
       account     mv_commodity market_value
       <chr>       <chr>               <dbl>
     1 Assets      IRAUSD                 0 
     2 Assets      USD               121570.
     3 Assets      VACHR                 41 
     4 Equity      USD                -3749.
     5 Expenses    IRAUSD             55000 
     6 Expenses    USD               277815.
     7 Expenses    VACHR                344 
     8 Income      IRAUSD            -55000 
     9 Income      USD              -385823.
    10 Income      VACHR               -385 
    11 Liabilities USD                -2723.
    > df %>% prune_coa(2) %>% 
    + group_by(account, mv_commodity) %>%
    + summarize(market_value = sum(market_value))
    # A tibble: 18 x 3
    # Groups:   account [?]
       account                     mv_commodity market_value
       <chr>                       <chr>               <dbl>
     1 Assets:US                   IRAUSD             0     
     2 Assets:US                   USD           121570.    
     3 Assets:US                   VACHR             41     
     4 Equity:Opening-Balances     USD            -3749.    
     5 Equity:Rounding             USD               -0.0495
     6 Expenses:Financial          USD              609.    
     7 Expenses:Food               USD            20069.    
     8 Expenses:Health             USD             7461.    
     9 Expenses:Home               USD            91181.    
    10 Expenses:Taxes              IRAUSD         55000     
    11 Expenses:Taxes              USD           154414.    
    12 Expenses:Transport          USD             4080     
    13 Expenses:Vacation           VACHR            344     
    14 Income:US                   IRAUSD        -55000     
    15 Income:US                   USD          -385823.    
    16 Income:US                   VACHR           -385     
    17 Liabilities:AccountsPayable USD                0     
    18 Liabilities:US              USD            -2723.
    
Basic personal accounting reports
+++++++++++++++++++++++++++++++++

Here is some examples using the functions in the package to help generate
various personal accounting reports of the 
beancount example generated by ``bean-example``.

First we load the (mainly tidyverse) libraries we'll be using and adjusting terminal output::

    > options(width=240) # tibble output looks better in wide terminal output
    > library("ledger")
    > library("dplyr")
    > filter <- dplyr::filter
    > library("ggplot2")
    > library("scales")
    > library("tidyr")
    > library("zoo")
    > filename <- tempfile(fileext = ".beancount")
    > system(paste("bean-example -o", filename), ignore.stderr=TRUE)
    > df <- register(filename) %>% mutate(yearmon = zoo::as.yearmon(date))
    > nw <- net_worth(filename)

Then we'll write some convenience functions we'll use over and over again::

    > print_tibble_rows <- function(df) {
    +   print(df, n=nrow(df))
    + }
    > count_beans <- function(df, filter_str = "", ..., 
    +                         amount = "amount",
    +                         commodity="commodity", 
    +                         cutoff=1e-3) {
    +     commodity <- sym(commodity)
    +     amount_var <- sym(amount)
    +     filter(df, grepl(filter_str, account)) %>% 
    +         group_by(account, !!commodity, ...) %>%
    +         summarize(!!amount := sum(!!amount_var)) %>% 
    +         filter(abs(!!amount_var) > cutoff & !is.na(!!amount_var)) %>%
    +         arrange(desc(abs(!!amount_var)))
    + }
    
Basic balance sheets
~~~~~~~~~~~~~~~~~~~~

Here is some basic balance sheets (using the market value of our assets)::

    > print_balance_sheet <- function(df) {
    +     assets <- count_beans(df, "^Assets", 
    +                  amount="market_value", commodity="mv_commodity")
    +     print_tibble_rows(assets)
    +     liabilities <- count_beans(df, "^Liabilities", 
    +                        amount="market_value", commodity="mv_commodity")
    +     print_tibble_rows(liabilities)
    + }
    > print(nw)
    # A tibble: 3 x 5
      date       commodity net_worth   assets liabilities
      <date>     <chr>         <dbl>    <dbl>       <dbl>
    1 2018-12-11 IRAUSD           0        0           0 
    2 2018-12-11 USD         136514.  139110.      -2595.
    3 2018-12-11 VACHR          -55      -55           0 
    > print_balance_sheet(prune_coa(df, 2))
    # A tibble: 2 x 3
    # Groups:   account [1]
      account   mv_commodity market_value
      <chr>     <chr>               <dbl>
    1 Assets:US USD               139110.
    2 Assets:US VACHR                -55 
    # A tibble: 1 x 3
    # Groups:   account [1]
      account        mv_commodity market_value
      <chr>          <chr>               <dbl>
    1 Liabilities:US USD                -2595.
    > print_balance_sheet(df)
    # A tibble: 10 x 3
    # Groups:   account [10]
       account                    mv_commodity market_value
       <chr>                      <chr>               <dbl>
     1 Assets:US:Vanguard:RGAGX   USD            65650.    
     2 Assets:US:Vanguard:VBMPX   USD            38918.    
     3 Assets:US:ETrade:Cash      USD            11564.    
     4 Assets:US:ETrade:ITOT      USD             8585.    
     5 Assets:US:ETrade:VHT       USD             7144.    
     6 Assets:US:ETrade:VEA       USD             4457.    
     7 Assets:US:ETrade:GLD       USD             2457     
     8 Assets:US:BofA:Checking    USD              335.    
     9 Assets:US:BayBook:Vacation VACHR            -55     
    10 Assets:US:Vanguard:Cash    USD               -0.0200
    # A tibble: 1 x 3
    # Groups:   account [1]
      account                    mv_commodity market_value
      <chr>                      <chr>               <dbl>
    1 Liabilities:US:Chase:Slate USD                -2595.

Basic net worth chart
~~~~~~~~~~~~~~~~~~~~~

Here is a basic chart of one's net worth from the beginning of the plaintext accounting file to today by month::

    > next_month <- function(date) {
    +     zoo::as.Date(zoo::as.yearmon(date) + 1/12)
    + }
    > nw_dates <- seq(next_month(min(df$date)), next_month(Sys.Date()), by="months")
    > df_nw <- net_worth(filename, nw_dates) %>% filter(!is.na(commodity))
    > ggplot(df_nw, aes(x=date, y=net_worth, colour=commodity, group=commodity)) + 
    +   geom_line() + scale_y_continuous(labels=scales::dollar)

.. image:: https://www.trevorldavis.com/share/ledger/basic_net_worth_plot.svg
   :alt: Monthly net worth chart

Basic income sheets
~~~~~~~~~~~~~~~~~~~

::

    > month_cutoff <- zoo::as.yearmon(Sys.Date()) - 2/12
    > compute_income <- function(df) {
    +     count_beans(df, "^Income", yearmon) %>% 
    +         mutate(income = -amount) %>%
    +         select(-amount) %>% ungroup()
    + }
    > print_income <- function(df) {
    +     compute_income(df) %>% 
    +         filter(yearmon >= month_cutoff) %>%
    +         spread(yearmon, income, fill=0) %>%
    +         print_tibble_rows()
    + }
    > compute_expenses <- function(df) {
    +     count_beans(df, "^Expenses", yearmon) %>% 
    +         mutate(expenses = amount) %>%
    +         select(-amount) %>% ungroup()
    + }
    > print_expenses <- function(df) {
    +     compute_expenses(df) %>%
    +         filter(yearmon >= month_cutoff) %>%
    +         spread(yearmon, expenses, fill=0) %>%
    +         print_tibble_rows()
    + }
    > compute_total <- function(df) {
    + full_join(compute_income(prune_coa(df)) %>% select(-account),
    +           compute_expenses(prune_coa(df)) %>% select(-account), 
    +           by=c("yearmon", "commodity")) %>%
    +     mutate(income = ifelse(is.na(income), 0, income),
    +            expenses = ifelse(is.na(expenses), 0, expenses),
    +            net = income - expenses) %>%
    +     gather(type, amount, -yearmon, -commodity)
    + }
    > print_total <- function(df) {
    +     compute_total(df) %>%
    +         filter(yearmon >= month_cutoff) %>%
    +         spread(yearmon, amount, fill=0) %>%
    +         print_tibble_rows()
    + }
    > print_total(df)
    # A tibble: 6 x 5
      commodity type     `Oct 2018` `Nov 2018` `Dec 2018`
      <chr>     <chr>         <dbl>      <dbl>      <dbl>
    1 USD       expenses      7537.      7335.      2200.
    2 USD       income        9279.      9501.      4640.
    3 USD       net           1742.      2166.      2440.
    4 VACHR     expenses         0          0          0 
    5 VACHR     income          10         10          5 
    6 VACHR     net              0          0          0 
    > print_income(prune_coa(df, 2))
    # A tibble: 2 x 5
      account   commodity `Oct 2018` `Nov 2018` `Dec 2018`
      <chr>     <chr>          <dbl>      <dbl>      <dbl>
    1 Income:US USD            9279.      9501.      4640.
    2 Income:US VACHR            10         10          5 
    > print_expenses(prune_coa(df, 2))
    # A tibble: 6 x 5
      account            commodity `Oct 2018` `Nov 2018` `Dec 2018`
      <chr>              <chr>          <dbl>      <dbl>      <dbl>
    1 Expenses:Financial USD               4        13.0        4  
    2 Expenses:Food      USD             618.      400.       145. 
    3 Expenses:Health    USD             194.      194.        96.9
    4 Expenses:Home      USD            2617.     2624.         0  
    5 Expenses:Taxes     USD            3984.     3984.      1954. 
    6 Expenses:Transport USD             120       120          0  
    > print_income(df)
    # A tibble: 4 x 5
      account                         commodity `Oct 2018` `Nov 2018` `Dec 2018`
      <chr>                           <chr>          <dbl>      <dbl>      <dbl>
    1 Income:US:BayBook:GroupTermLife USD             48.6       48.6       24.3
    2 Income:US:BayBook:Salary        USD           9231.      9231.      4615. 
    3 Income:US:BayBook:Vacation      VACHR           10         10          5  
    4 Income:US:ETrade:Gains          USD              0        221.         0
    > print_expenses(df)
    # A tibble: 19 x 5
       account                            commodity `Oct 2018` `Nov 2018` `Dec 2018`
       <chr>                              <chr>          <dbl>      <dbl>      <dbl>
     1 Expenses:Financial:Commissions     USD             0          8.95       0   
     2 Expenses:Financial:Fees            USD             4          4          4   
     3 Expenses:Food:Groceries            USD           275.       182.        44.4 
     4 Expenses:Food:Restaurant           USD           343.       218.       101.  
     5 Expenses:Health:Dental:Insurance   USD             5.8        5.8        2.9 
     6 Expenses:Health:Life:GroupTermLife USD            48.6       48.6       24.3 
     7 Expenses:Health:Medical:Insurance  USD            54.8       54.8       27.4 
     8 Expenses:Health:Vision:Insurance   USD            84.6       84.6       42.3 
     9 Expenses:Home:Electricity          USD            65         65          0   
    10 Expenses:Home:Internet             USD            80         80.0        0   
    11 Expenses:Home:Phone                USD            72.1       78.5        0   
    12 Expenses:Home:Rent                 USD          2400       2400          0   
    13 Expenses:Taxes:Y2018:US:CityNYC    USD           350.       350.       175.  
    14 Expenses:Taxes:Y2018:US:Federal    USD          2126.      2126.      1063.  
    15 Expenses:Taxes:Y2018:US:Medicare   USD           213.       213.       107.  
    16 Expenses:Taxes:Y2018:US:SDI        USD             2.24       2.24       1.12
    17 Expenses:Taxes:Y2018:US:SocSec     USD           563.       563.       243.  
    18 Expenses:Taxes:Y2018:US:State      USD           730.       730.       365.  
    19 Expenses:Transport:Tram            USD           120        120          0   

And here is a plot of income, expenses, and net income over time::

    > ggplot(compute_total(df), aes(x=yearmon, y=amount, group=commodity, colour=commodity)) +
    +   facet_grid(type ~ .) +
    +   geom_line() + geom_hline(yintercept=0, linetype="dashed") +
    +   scale_x_continuous() + scale_y_continuous(labels=scales::comma) 

.. image:: https://www.trevorldavis.com/share/ledger/basic_income_plot.svg
   :alt: Monthly income chart


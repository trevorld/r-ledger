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

    $ stack install --resolver=lts hledger-lib-1.9 hledger-1.9
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
    > dplyr::filter(df, grepl("Expenses", account), grepl("^trip", tags)) %>% 
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
    

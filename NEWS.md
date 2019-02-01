ledger 2.0.1
============

* For ``ledger`` files ``register`` no longer filters out transactions with amount equal to zero (#13).

ledger 2.0.0
============

Breaking changes
----------------

* Now ``register`` returns a ``tibble`` instead of a ``data.frame``.
* By default now reads in ``beancount`` files using the output from ``bean-query`` 
  instead of ``bean-report`` followed up by ``hledger``.
* Most users of the ``ledger`` R package won't need to change any code.

New functions
-------------

* Now has ``prune_coa`` and ``prune_coa_string`` functions to help simplify plaintext accounting "Chart of Accounts" names to a given maximum depth.
* Lower level ``register_beancount``, ``register_ledger``, and ``register_hledger`` functions are now exported (and documented).

Minor improvements and fixes
----------------------------

* ``register`` now has a ``date`` argument than can be used to exclude transactions 
  (and implicitly price statements) before that date.
* ``register`` now preserves transaction comments when importing ledger files (#16).  Thanks Jenya Sovetkin for patch.
* ``register`` now preserves tags when importing beancount files.

ledger 1.0.1
============

* Initial release on CRAN.

ledger 0.8.0
============

* Implemented a workaround to get ``register`` working with ``ledger `` and ``bean-report`` on Windows (#15).

ledger 0.7.0
============

* Removed ``regex`` argument from ``net_worth`` while adding ``include``, ``exlude``, and ``ignore_case`` arguments.  

ledger 0.6.0
============

* Add ``toolchain`` argument to ``register`` and ``net_worth``.
* Add new columns to ``net_worth``.

ledger 0.5.3
============

* Removed ``include_cleared``, ``include_pending``, ``include_unmarked``, ``convert_to_cost``, and ``convert_to_market_value`` arguments from ``register`` (#6).
* Added ``flags`` arguments to ``register`` (#6).
* Added a new ``mark`` column to imported data frames with values ``"*"``, ``"!"``, or ``""`` (#6).
* For hledger/beancount files added new ``historical_cost``, ``hc_commodity``, ``market_value`` and ``mv_commodity`` columns (#6).
* Wrote and exported S3 methods so can use ``rio::import`` to read in registers (#7).
* Now throws an error if required binaries not found (#8).
* Fixed bug in importing hledger or beancount files (now automatically casts ``amount`` field to numeric).
* Added new ``net_worth`` function.




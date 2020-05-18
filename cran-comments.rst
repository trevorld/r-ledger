**Nota benes**

Depending on the type of plaintext accounting file to be imported this package has run-time system dependencies of ledger (>= 3.1), hledger (>= 1.2), and/or beancount (>= 2.0).  If a dependency isn't found the unit tests will skip those sections of tests - in particular R CMD check should still pass even if none of the system dependencies are available.  

**Test environments**

* local (linux, R 3.6.3) with all of the system dependencies installed
* win-builder (windows, R devel) with none of the system dependencies installed
* travis-ci (linux, R devel) with ledger and beancount installed
* appveyor (windows, R release) with all of the system dependencies installed
* travis-ci (OSX, R release) with ledger and beancount installed
* travis-ci (linux, R release) with ledger and beancount installed

**R CMD check --as-cran results**

Status: OK

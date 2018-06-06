desc "Build files for packaging"
task :default do
    sh "pandoc -o README.md README.rst"
    sh "bean-report inst/extdata/example.beancount ledger > inst/extdata/example.ledger"
    sh "bean-report inst/extdata/example.beancount hledger > inst/extdata/example.hledger"
end


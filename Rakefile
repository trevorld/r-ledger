desc "Build files for packaging"
task :default do
    sh 'Rscript -e "devtools::document()"'
    sh 'Rscript -e "knitr::knit(\"README.Rrst\")"'
    # sh "bean-report inst/extdata/example.beancount ledger > inst/extdata/example.ledger"
    # sh "bean-report inst/extdata/example.beancount hledger > inst/extdata/example.hledger"
    # sh "bean-report inst/extdata/empty.beancount ledger > inst/extdata/empty.ledger"
    # sh "bean-report inst/extdata/empty.beancount hledger > inst/extdata/empty.hledger"
end

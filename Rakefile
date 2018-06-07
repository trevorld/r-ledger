desc "Build files for packaging"
task :default do
    sh 'Rscript -e "suppressMessages(devtools::document())"'
    sh 'sudo Rscript -e "devtools::install(quiet=TRUE, upgrade_dependencies=FALSE, dependencies=FALSE)"'
    sh "bean-report inst/extdata/example.beancount ledger > inst/extdata/example.ledger"
    sh "bean-report inst/extdata/example.beancount hledger > inst/extdata/example.hledger"
    sh "bean-report inst/extdata/empty.beancount ledger > inst/extdata/empty.ledger"
    sh "bean-report inst/extdata/empty.beancount hledger > inst/extdata/empty.hledger"
end


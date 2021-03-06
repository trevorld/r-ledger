% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/prune_coa.r
\name{prune_coa}
\alias{prune_coa}
\alias{prune_coa_string}
\title{Prune plaintext "Chart of Accounts" names to a given maximum depth}
\usage{
prune_coa(df, depth = 1, variable, name)

prune_coa_string(x, depth = 1)
}
\arguments{
\item{df}{A data frame}

\item{depth}{How deep should the account structure be.}

\item{variable}{Which variable to make less deep (default is to use "account")}

\item{name}{New variable name (default is to edit the variable argument in place)}

\item{x}{Character vector}
}
\description{
\code{prune_coa} is a convenience function that modifies a data frame
 by either editing in place or making
  a new variable containing the plaintext "Chart of Accounts" pruned to a given maximum depth
 e.g. "Assets:Checking:Credit-Union:Account1" at a maximum depth of 2 will be converted to "Assets:Checking".
\code{prune_coa} uses tidyverse non-standard evaluation (NSE).
\code{prune_coa_string} is a convenience function which does the pruning operation on character vectors.
}
\examples{
df <- tibble::tribble(~account, ~amount,
                     "Assets:Checking:BankA", 1000,
                     "Assets:Checking:BankB", 1000,
                     "Assets:Savings:BankA", 1000,
                     "Assets:Savings:BankC", 1000)
prune_coa(df)
prune_coa(df, 2)
prune_coa(df, 3)
prune_coa(df, 4)
prune_coa(df, 2, account, account2)
prune_coa(prune_coa(df, 2, account, account2), 3, account2, account3)
prune_coa_string(df$account, 2)

}

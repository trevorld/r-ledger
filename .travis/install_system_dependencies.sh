#!/bin/bash

if [[ $TRAVIS_OS_NAME == 'osx' ]]; then

    brew update
    # Ledger
    brew install ledger
    # HLedger
    mkdir -p ~/.local/bin ~/.stack
    export PATH=$HOME/.local/bin:$PATH
    wget -qO- https://get.haskellstack.org/ | sh -s - -f
    stack install --resolver=lts-12 megaparsec-7.0.4 cassava-megaparsec-2.0.0 config-ini-0.2.3.0 hledger-lib-1.12 hledger-1.12
    # Beancount
    brew upgrade python
    # pip3 install beancount
    sudo -H pip3 install beancount

else

    sudo add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu/ xenial main universe"
    sudo apt-get -qq update
    # Ledger
    sudo apt-get install -y ledger
    # HLedger
    mkdir -p ~/.local/bin ~/.stack
    export PATH=$HOME/.local/bin:$PATH
    wget -qO- https://get.haskellstack.org/ | sh -s - -f
    stack install --resolver=lts-12 megaparsec-7.0.4 cassava-megaparsec-2.0.0 config-ini-0.2.3.0 hledger-lib-1.12 hledger-1.12
    # Beancount
    sudo apt-get install -y python3 python3-pip
    pip3 install beancount

fi

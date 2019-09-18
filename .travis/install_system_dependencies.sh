#!/bin/bash

if [[ $TRAVIS_OS_NAME == 'osx' ]]; then

    brew update
    # Ledger
    brew install ledger
    # HLedger
    # mkdir -p ~/.local/bin ~/.stack
    # export PATH=$HOME/.local/bin:$PATH
    # wget -qO- https://get.haskellstack.org/ | sh -s - -f
    # stack update
    # stack install --resolver=lts-14.3 hledger-lib-1.15.2 hledger-1.15.2 hledger-web-1.15 hledger-ui-1.15 --verbosity=error 
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
    # mkdir -p ~/.local/bin ~/.stack
    # export PATH=$HOME/.local/bin:$PATH
    # wget -qO- https://get.haskellstack.org/ | sh -s - -f
    # stack update
    # stack install --resolver=lts-14.3 hledger-lib-1.15.2 hledger-1.15.2 hledger-web-1.15 hledger-ui-1.15 --verbosity=error 
    # Beancount
    sudo apt-get install -y python3 python3-pip python3-setuptools
    pip3 install beancount

fi

#!/bin/bash

./pmd check -R rulesets/apex/quickstart.xml -d ../../../../target/src/classes/ -f csv 2> /dev/null > report.csv
if [ "$?" -ne 0 ]
then
    echo "Errors/Warnings has beed detected"
    if [ $(cat report.csv | awk -F',' '$4~1 {print $0}' | wc -l) -ne 0 ]
    then
        cat report.csv | awk -F',' '$4~1 {print $0}'
        exit 1
    fi
fi


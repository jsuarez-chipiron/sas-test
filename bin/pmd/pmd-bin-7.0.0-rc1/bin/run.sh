#!/bin/bash

./pmd check -R rulesets/apex/quickstart.xml -d ../../../../target/src/classes/ -f csv 2> result.csv > result.csv
if [ "$?" -ne 0 ]
then
    echo "Errors/Warnings has beed detected"
    cat result.csv
    cat result.csv | awk -F',' '$4~1 {print $0}' 
    cat result.csv | awk -F',' '$4~1 {print $0}' | wc -l
    if [ $(cat result.csv | awk -F',' '$4~1 {print $0}' | wc -l) -ne 0 ]
    then
        exit 1
    fi
fi


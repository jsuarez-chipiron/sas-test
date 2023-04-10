#!/bin/bash

./pmd check -R rulesets/apex/quickstart.xml -d ~/Projects/8_SAS/repos/sfdc/My_FCS_Salesforce/sas-core/main/default/classes/ -f csv 2> /dev/null > report.json
if [ "$?" -ne 0 ]
then
    echo "Errors has beed detected"

    cat report.json | awk -F',' '$4~1 {print $0}'
fi


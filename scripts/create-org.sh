#!/bin/bash

# A script for creating more useful scratch orgs.
# 
# In addition to creating the org and pushing source into it, the script
# also sets up authentication providers and named credentials towards UAT,
# and populates the org with some fake data.
# 
# After running this script you'll still need to authenticate to APIM within
# Salesforce.

scratchDef="config/project-scratch-def.json"
orgName="FCS2020Salesforce"
dataPlan="scripts/create-org-mock-data/plan.json"

echo "Creating Scratch org"
sfdx force:org:create -f $scratchDef -a $orgName --setdefaultusername

echo "Creating auth providers and named credentials"
# Auth provider requires the admin user's username so it cannot be pushed normally.
# The others require the auth provider before they can be pushed.

if [ ! -d sas-core/main/default/authproviders ]; then
  mkdir sas-core/main/default/authproviders
fi
if [ ! -d sas-core/main/default/namedCredentials ]; then
  mkdir sas-core/main/default/namedCredentials
fi

userName=`sfdx auth:list | awk -v user="$orgName" '$1 == user {print $2}'` # Get admin user username
# Create auth provider with username from above
sed 's/'{userName}'/'"$userName"'/' scripts/create-org-templates/APIM_Auth.authprovider-meta-template.xml > sas-core/main/default/authproviders/APIM_Auth.authprovider-meta.xml

# Copy named credentials
cp scripts/create-org-templates/SAS_APIM_Auth.namedCredential-meta-template.xml sas-core/main/default/namedCredentials/SAS_APIM_Auth.namedCredential-meta.xml
cp scripts/create-org-templates/SAS_APIM_TEDS_FCS.namedCredential-meta-template.xml sas-core/main/default/namedCredentials/SAS_APIM_TEDS_FCS.namedCredential-meta.xml

cp scripts/create-org-templates/C_GeneralSetting.APIM_TEDS_Subscription_Key.template.xml sas-core/main/default/customMetadata/C_GeneralSetting.APIM_TEDS_Subscription_Key.md-meta.xml

cp scripts/create-org-templates/LocalAuthProvider.APIM_Auth.template.xml sas-core/main/default/customMetadata/LocalAuthProvider.APIM_Auth.md-meta.xml

# Sleep to ensure sharing rule calculation from org creation has finished before pushing sources
sleep 2m

echo "Pushing source"
sfdx force:source:push -u $orgName

echo "Pushing data"
sfdx force:data:tree:import -u $orgName -p $dataPlan

echo "Org created successfully. Opening..."
echo "Remember to enter authentication credentials."
sfdx force:org:open --path lightning/setup/NamedCredential/home -u $orgName

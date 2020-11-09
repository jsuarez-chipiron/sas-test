# SAS Salesforce

This repository contains the source code for SAS implementation of Salesforce.

## Development process

SAS Salesforce is setup with Scrath Org, VSC and unpackaged development. 

### Getting started

Development is possible also with other editors, but support seems to be best for VS Code. Most importantly,
there's the Salesforce Extension Pack that offers very handy UI to the Salesforce CLI. There's also a bunch of
other helpful extensions and tools, but these will get you started.

#### Install 
1. [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli)
2. [VS Code](https://code.visualstudio.com)
3. [Salesforce Extension Pack for VS Code](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode)

#### In Azure DevOps
Add .ssh keys to https://dev.azure.com/flysas/_usersSettings/keys 

#### In VS Code
Run the following commands from the Command Palette (⇧⌘P):

Authorize SF CLI to access the organization:

Run `SFDX: Authorize a Dev Hub` Might take a few tries to get working. Something caused by the AD auth, probably.


Create an empty scrath org with default settings:

Run `SFDX: Create a default scratch org...`


Push the SAS source code to the scratch org:

Run `SFDX: Push Source to Default Scratch Org`


Open the scratch org with:

Run `SFDX: Open Default Org` or by clicking the window icon in the Status Bar

### Local development

1. Create a branch from `support/master` for features and `master` for hotfixes.
2. Run `SFDX: Create a default scratch org...` to create a new scratch org to work in.
3. Run `SFDX: Push Source to Default Scratch Org` to push current branch's code to the scratch org.
4. Make the changes you need to do in the scratch org.
5. Run `SFDX: Pull Source from Default Scratch Org`
6. Commit, Push and PR.

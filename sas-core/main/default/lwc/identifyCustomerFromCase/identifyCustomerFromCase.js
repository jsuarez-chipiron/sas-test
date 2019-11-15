import { LightningElement, track, api, wire } from "lwc";
import { getRecord, updateRecord } from "lightning/uiRecordApi";
import findCustomer from "@salesforce/apex/IdentifyCustomerFromCaseController.findCustomer";
import getCaseData from "@salesforce/apex/IdentifyCustomerFromCaseController.getCaseData";

export default class App extends LightningElement {
    @api recordId = null; //Record Id for case the component is places

    @api
    showSearchOptions = false; //Property decides if options for value to search for are available to used. Set from Lightning Page. 

    @api
    searchOption = this.searchOptions[0].value; //Property used to determine which field/option to search for, e.g. EuroBonus or Travel Pass

    @track
    searchValue; //Search value from search text field, set by action handler

    @track
    showSpinner = false; //When true, spinner graphic is displayed over compoent

    @track
    customerIdentified = false; //When true, the component declares the customer as identified on the case

    @track
    error; //Property where errors are saved that will be displayed in component

    @track
    noSearchResult = false; //When true, a warning is displayed to the user about not finding a search result

    //Used to wire to case records. Might be used in the future. 
    /* 
    @wire(getRecord, {
        recordId: "$recordId",
        fields: ["Case.AccountId", "Case.EBNumber__c"]
    })
    wiredCase;

    get accountId() {
        return this.wiredCase.data.fields.AccountId.value;
    }

    get ebNumber() {
        return this.wiredCase.data.fields.EBNumber__c.value;
    }*/

    //List of options available to search for. Value should corresponds to field on Frequent_Flyer__x.
    get searchOptions() {
        return [
            { label: "EuroBonus", value: "EBNumber__c" },
            { label: "Email", value: "Email__c" },
            { label: "Customer Id", value: "ExternalId" },
            { label: "Travel Pass", value: "TPAccountNumber__c" }
        ];
    }

    /**
     * Event handler for when a user presses the enter key in the search field
     * @param {*} event 
     */
    handlePressEnterKey(event){
        let enterKeyCode = 13;
        if(event.keyCode === enterKeyCode){
            if (!this.validateSearchInput()) {
                this.noSearchResult = false;
                this.searchForCustomer();
            }
        }
    }

    /**
     * Event handler for changes in search text field 
     * @param {*} event 
     */
    handleSearchValueChange(event) {
        this.searchValue = event.target.value;
    }

    /**
     * Event handler for when a user clicks button to search
     * @param {*} event 
     */
    handleSearchButtonClick(event) {
        if (!this.validateSearchInput()) {
            this.noSearchResult = false;
            this.searchForCustomer();
        }
    }

    /**
     * Event handler for when a used clicks button to change customer related to case
     * Removed valued related to previously connected customer from case record
     * @param {*} event 
     */
    handleChangeCustomer(event) {
        console.log("Triggered change customer");

        this.showSpinner = true;

        const recordInput = {
            fields: {
                Id: this.recordId,
                AccountId: null,
                EBNumber__c: null,
                TPAccountNumber__c: null
            }
        };
        updateRecord(recordInput)
            .then(result => {
                this.error = undefined;
                this.customerIdentified = false;
                this.showSpinner = false;
            })
            .catch(error => {
                this.displayError({ error: error });
            })
    }

    /**
     * Method running when component is inserted in DOM
     * Executes logic to determine if a customer should be automatically identified or if customer is already identified
     */
    connectedCallback() {
        getCaseData({ caseId: this.recordId })
            .then(result => {
                this.error = undefined;
                this.evaluateCaseOnOpen(result);
            })
            .catch(error => {
                this.displayError({ error: error });
            })
    }

    /**
     * Evaluates a case record and performs a new search for customer if conditions evaluates to true
     * Should be run when a case record is opened
     * @param {*} caseRecord 
     */
    evaluateCaseOnOpen(caseRecord){
        //If case already has an account connected, only update account if it was not updated within an hour
        if (caseRecord.AccountId) {
            this.customerIdentified = true;
            if (Date.now() - Date.parse(caseRecord.Account.LastRetrievedFromSource__c) > 3600000) {
                this.searchOption = 'ExternalId';
                this.searchValue = caseRecord.Account.FrequentFlyer__c;
                this.searchForCustomer();
            }
        }
        //If no account is connected and case has EB number, search for customer based on EB number
        else if (caseRecord.EBNumber__c) {        
            this.searchOption = 'EBNumber__c';
            this.searchValue = caseRecord.EBNumber__c;
            this.searchForCustomer();
        }
        //If no account is connected and case has no EB number but TP Account number, search for customer based on TP Account number
        else if (caseRecord.TPAccountNumber__c) {
            this.searchOption = 'TPAccountNumber__c';
            this.searchValue = caseRecord.TPAccountNumber__c;
            this.searchForCustomer();
        }
    }

    /**
     * Validates the value in the search field on component
     * Currently only checks if field is empty but should preferably be extended with futher validations
     */
    validateSearchInput() {
        console.log("Triggered validate input");

        let fieldError = false;
        let inputCmp = this.template.querySelector(".search-field");
        let value = inputCmp.value;
        if (value === "") {
            inputCmp.setCustomValidity("Please provide a valid EuroBonus number");
            fieldError = true;
        } else {
            inputCmp.setCustomValidity(""); // If there was a custom error before, reset it
            fieldError = false;
        }
        inputCmp.reportValidity(); // Tells lightning-input to show the error right away without needing interaction

        return fieldError;
    }

    /**
     * Method used to search for customer 
     * Uses variables in component for determine field and value to search for
     */
    searchForCustomer() {
        console.log("Triggered search for customer");
        this.showSpinner = true;

        findCustomer({
            searchField: this.searchOption,
            searchValue: this.searchValue
        })
            .then(result => {
                this.error = undefined;

                if (!result) {
                    this.showSpinner = false;
                    this.noSearchResult = true;
                } else {
                    let account = result;
                    const recordInput = {
                        fields: {
                            Id: this.recordId,
                            AccountId: account.Id,
                            EBNumber__c: account.EBNumber__c,
                            TPAccountNumber__c: account.TPAccountNumber__c
                        }
                    };

                    updateRecord(recordInput).then(result => {
                        this.error = undefined;
                        this.customerIdentified = true;
                        this.showSpinner = false;
                    })
                        .catch(error => {
                            this.displayError({ error: error });
                        });
                }
            })
            .catch(error => {
                this.displayError({ error: error });
            });
    }

    displayError(error) {
        console.log("An error occured: " + JSON.stringify(error));
        this.showSpinner = false;
        this.error = error;
    }
}
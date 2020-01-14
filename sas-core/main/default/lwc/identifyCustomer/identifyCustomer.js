import { LightningElement, track, api, wire } from "lwc";
import findCustomer from "@salesforce/apex/IdentifyCustomerComponentController.findCustomer";
import getRecordData from "@salesforce/apex/IdentifyCustomerComponentController.getRecordData";
import updateRecordDataWithApex from "@salesforce/apex/IdentifyCustomerComponentController.updateRecordDataWithApex";
import { registerListener, unregisterAllListeners, fireEvent } from './pubsub';

export default class App extends LightningElement {
    /**
     * Record Id for record the component is places
     * @type {string}
     */
    @api recordId;

    /**
     * Property decides if options for value to search for are available to used. Set from Lightning Page.
     * @type {boolean}
     */
    @api showSearchOptions = false;

    /**
     * Property used to determine which field/option to search for, e.g. EuroBonus or Travel Pass
     * @type {string}
     */
    @api searchOption = this.searchOptions[0].value;

    /**
     * Search value from search text field, set by action handler
     * @type {string}
     */
    @track searchValue = undefined;

    /**
     * When true, spinner graphic is displayed over component
     * @type {boolean}
     */
    @track showSpinner = false;

    /**
     * When true, the component declares the customer as identified on the record
     * @type {boolean}
     */
    @track customerIdentified = false;

    /**
     * Property where errors are saved that will be displayed in component
     * @type {object}
     */
    @track error = undefined;

    /**
     * When true, a warning is displayed to the user about not finding a search result.
     * @type {boolean}
     */
    @track noSearchResult = false;

    /**
     * Variable holding data about the current record. Loaded on component initiation.
     * @type {ComponentRecordData}
     */
    currentRecordData = undefined;

    /**
     * List of options available to search for. Value should corresponds to field on Frequent_Flyer__x.
     * @returns {({label: string, value: string}|{label: string, value: string}|{label: string, value: string}|{label: string, value: string})[]}
     */
    get searchOptions() {
        return [
            { label: "EuroBonus", value: "EBNumber__c" },
            { label: "Email", value: "Email__c" },
            { label: "CODS Id", value: "ExternalId" },
            { label: "Travel Pass", value: "TPAccountNumber__c" }
        ];
    }

    /**
     * Event handler for when a user presses the enter key in the search field
     * @param {*} event
     */
    handlePressEnterKey(event){
        if(event.key === 'Enter' && !this.validateSearchInput()){
            this.noSearchResult = false;
            this.findCustomerAsync();
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
            this.findCustomerAsync();
        }
    }

    async handleChangeCustomerButtonClick(event){
        try{
            const recordInput = {
                recordId: this.recordId,
                accountId: null,
                euroBonusNumber: null,
                tpAccountNumber: null,
                codsId: null,
                caseId: this.currentRecordData.caseId
            };
            await updateRecordDataWithApex({ jsonData: JSON.stringify(recordInput) });
            await fireEvent(this.currentRecordData.caseId + '_customerChanged', event );
        } catch (error) {
            this.displayError(error);
        }
    }

    /**
     * Event handler for when a used clicks button to change customer related to record
     * Removed valued related to previously connected customer from record
     * @param {*} event
     */
    async handleChangeCustomer(event) {
        try{
            await this.dispatchEvent(new CustomEvent('refreshView'));
            this.error = undefined;
            this.customerIdentified = false;
            this.showSpinner = false;
        } catch (error){
            this.displayError(error);
        }
    }

    /**
     * Method running when component is inserted in DOM
     * Executes logic to determine if a customer should be automatically identified or if customer is already identified
     */
    async connectedCallback() {
        try{
            this.showSpinner = true;
            this.currentRecordData = await getRecordData({ recordId: this.recordId });
            await registerListener(this.currentRecordData.caseId + '_customerIdentified', this.handleCustomerIdentified, this);
            await registerListener(this.currentRecordData.caseId + '_customerChanged', this.handleChangeCustomer, this);
            await this.evaluateRecordOnOpen();
            this.showSpinner = false;
        } catch (error) {
                this.displayError(error);
        }
    }

    /**
     * Event handler for when a customer has been identified either by the firing component or another component.
     * @param account Account data for identified customer.
     * @returns {Promise<void>}
     */
    async handleCustomerIdentified(account){
        try {
            await this.dispatchEvent(new CustomEvent('refreshView'));
            this.error = undefined;
            this.customerIdentified = true;
            this.showSpinner = false;
        } catch (error) {
            this.displayError(error);
        }
    }

    /**
     * This lifecycle hook fires when a component is removed from the DOM. Unregisters listeners for component.
     */
    disconnectedCallback() {
        unregisterAllListeners(this);
    }

    /**
     * Evaluates a record record and performs a new search for customer if conditions evaluates to true
     * Should be run when a record record is opened
     * @returns {Promise<void>}
     */
    async evaluateRecordOnOpen(){
        console.log('Evaluating on open: ' + JSON.stringify(this.currentRecordData));
        if (this.currentRecordData.accountId) {
            this.customerIdentified = true;
            if (Date.now() - Date.parse(this.currentRecordData.lastRetrievedFromSource) > 3600000) {
                this.searchOption = 'ExternalId';
                this.searchValue = this.currentRecordData.codsId;
                this.findCustomerAsync();
            }
        }
        else if (this.currentRecordData.euroBonusNumber) {
            this.searchOption = 'EBNumber__c';
            this.searchValue = this.currentRecordData.euroBonusNumber;
            this.findCustomerAsync();
        }
        else if (this.currentRecordData.tpAccountNumber) {
            this.searchOption = 'TPAccountNumber__c';
            this.searchValue = this.currentRecordData.tpAccountNumber;
            this.findCustomerAsync();
        }
        this.searchOption = 'EBNumber__c';
    }

    /**
     * Validates the value in the search field on component
     * Currently only checks if field is empty but should preferably be extended with further validations
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
            inputCmp.setCustomValidity("");
            fieldError = false;
        }
        inputCmp.reportValidity();
        return fieldError;
    }

    /**
     * Used to set parameters to display en error to the user.
     * @param error
     */
    displayError(error) {
        console.log("An error occurred: " + JSON.stringify(error));
        this.showSpinner = false;
        this.error = error;
    }

    /**
     * Used to call component controller to search for a customer based on parameters supplied to component.
     * @returns {Promise<void>}
     */
    async findCustomerAsync(){
        console.log("Triggered search for customer");
        this.showSpinner = true;
        try{
            let account = await findCustomer({
                searchField: this.searchOption,
                searchValue: this.searchValue
            });
            if(account){
                const recordInput = {
                    recordId: this.recordId,
                    accountId: account.Id,
                    euroBonusNumber: account.EBNumber__c,
                    tpAccountNumber: account.TPAccountNumber__c,
                    codsId: account.FrequentFlyer__c,
                    personContactId: account.PersonContactId,
                    caseId: this.currentRecordData.caseId
                };
                await updateRecordDataWithApex({ jsonData: JSON.stringify(recordInput) });
                await fireEvent(this.currentRecordData.caseId + '_customerIdentified', account);
            } else{
                this.showSpinner = false;
                this.noSearchResult = true;
            }
        } catch(error){
            this.displayError(error);
        }
    }
}
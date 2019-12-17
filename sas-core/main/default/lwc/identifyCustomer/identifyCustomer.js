import { LightningElement, track, api, wire } from "lwc";
import { updateRecord } from "lightning/uiRecordApi";
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
     * Parameter set from Aura component container, containing the id of the enclosing tab for the current record.
     * This value is used to calculate the Tab Identifier.
     */
    @api enclosingTabId;

    /**
     * Identifier to the group of tabs the record on which the component is shown belongs to.
     * The Tab Identifier is used to contains events to the groups of records under this id.
     * @type {string}
     */
    tabIdentifier;

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

    handleChangeCustomerButtonClick(event){
        fireEvent(this.tabIdentifier + '_customerChanged', event );
    }

    /**
     * Event handler for when a used clicks button to change customer related to record
     * Removed valued related to previously connected customer from record record
     * @param {*} event
     */
    async handleChangeCustomer(event) {
        console.log("Triggered change customer");
        try{
            this.showSpinner = true;
            if(this.currentRecordData.supportsUIApi) {
                const recordInput = {
                    fields: {
                        Id: this.recordId,
                        AccountId: null,
                        EBNumber__c: null,
                        TPAccountNumber__c: null
                    }
                };
                await updateRecord(recordInput);
            }  else {
                const recordInput = {
                    recordId: this.recordId,
                    accountId: null,
                    euroBonusNumber: null,
                    tpAccountNumber: null,
                    codsId: null
                };

                await updateRecordDataWithApex({ jsonData: JSON.stringify(recordInput) });
                this.dispatchEvent(new CustomEvent('connectedCustomerChange'));
            }
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
            await this.setTabIdentifier();
            this.showSpinner = true;
            await registerListener(this.tabIdentifier + '_customerIdentified', this.handleCustomerIdentified, this);
            await registerListener(this.tabIdentifier + '_customerChanged', this.handleChangeCustomer, this);
            this.currentRecordData = await getRecordData({ recordId: this.recordId });
            await this.evaluateRecordOnOpen();
            this.showSpinner = false;
        } catch (error) {
                this.displayError(error);
        }
    }

    /**
     * Used to set identifier to tab group the record showing the component belongs to.
     */
    setTabIdentifier(){
        if(this.enclosingTabId){
            let subTabSeparatorIndex = this.enclosingTabId.search('_');
            if(subTabSeparatorIndex > -1){
                this.tabIdentifier = this.enclosingTabId.slice(0, subTabSeparatorIndex);
            } else{
                this.tabIdentifier = this.enclosingTabId;
            }
        } else {
            this.tabIdentifier = this.recordId;
        }
    }

    /**
     * Event handler for when a customer has been identified either by the firing component or another component.
     * @param account Account data for identified customer.
     * @returns {Promise<void>}
     */
    async handleCustomerIdentified(account){
        try {
            if(this.currentRecordData.supportsUIApi) {
                const recordInput = {
                    fields: {
                        Id: this.currentRecordData.recordId,
                        AccountId: account.Id,
                        EBNumber__c: account.EBNumber__c,
                        TPAccountNumber__c: account.TPAccountNumber__c,
                        CODSId__c: account.FrequentFlyer__c
                    }
                };
                await updateRecord(recordInput);
            } else{
                const recordInput = {
                    recordId: this.recordId,
                    accountId: account.Id,
                    euroBonusNumber: account.EBNumber__c,
                    tpAccountNumber: account.TPAccountNumber__c,
                    codsId: account.FrequentFlyer__c,
                    personContactId: account.PersonContactId
                };
                await updateRecordDataWithApex({ jsonData: JSON.stringify(recordInput) });
                this.dispatchEvent(new CustomEvent('connectedCustomerChange'));
            }
            this.error = undefined;
            this.customerIdentified = true;
            this.showSpinner = false;
        } catch (error) {
            this.displayError(error);
        }
    }

    /**
     * This lifecycle hook fires when a component is removed from the DOM.
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
            inputCmp.setCustomValidity(""); // If there was a custom error before, reset it
            fieldError = false;
        }
        inputCmp.reportValidity(); // Tells lightning-input to show the error right away without needing interaction
        return fieldError;
    }

    /**
     * Used to set parameters to display en error to the user.
     * @param error
     */
    displayError(error) {
        console.log("An error occured: " + JSON.stringify(error));
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
                await fireEvent(this.tabIdentifier + '_customerIdentified', account);
            } else{
                this.showSpinner = false;
                this.noSearchResult = true;
            }
        } catch(error){
            this.displayError(error);
        }
    }
}
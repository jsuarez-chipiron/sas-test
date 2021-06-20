import { LightningElement, track, api, wire } from "lwc";
import getAccountData from "@salesforce/apex/CustomerCardController.getAccountData";
import getBookingData from "@salesforce/apex/CustomerCardController.getBookingData";
import getCaseData from "@salesforce/apex/CustomerCardController.getCaseData";
import Case_ACCOUNTID_FIELD from "@salesforce/schema/Case.AccountId";
import Case_ID_FIELD from "@salesforce/schema/Case.Id";
import { getRecord, updateRecord } from "lightning/uiRecordApi";
import findCustomer from "@salesforce/apex/FCS_IdentifyCustomerController.findCustomer";

export default class CustomerCard extends LightningElement {
  @api recordId;

  // data fields
  @track account = undefined;
  @track bookings = [];
  @track cases = [];

  // properties calculated from data
  @track allCases = 0;
  @track numberOfVisibleCases = 0;
  @track cardTitle = "";
  accountId = undefined;

  // UI state
  @track showSpinner = false;
  @track noSearchResult = false;
  @track error = false;
  @track searchValue = "";

  @wire(getRecord, { recordId: "$recordId", fields: [Case_ACCOUNTID_FIELD] })
  wiredRecord({ error, data }) {
    if (!error && data) {
      this.accountId = data.fields.AccountId.value;
    } else {
      this.accountId = undefined;
    }
  }

  @wire(getAccountData, { accountId: "$accountId" })
  wiredAccount({ error, data }) {
    if (!error && data != undefined && data.length > 0) {
      this.account = data[0];
      this.cardTitle = `${data[0].Name} (EB${data[0].FCS_EBLevel__c}${data[0].FCS_EBNumber__c})`;
    } else {
      this.account = undefined;
      this.cardTitle = "";
    }
  }

  @wire(getCaseData, { accountId: "$accountId" })
  wiredCases({ error, data }) {
    if (!error && data != undefined && data.length > 0) {
      this.cases = data
        .map(function (elem) {
          return {
            ...elem,
            className:
              elem.Status === "Closed"
                ? "slds-item case-bullet closed-case-bullet"
                : "slds-item case-bullet open-case-bullet",
            recordUrl: `/${elem.Id}`,
            StatusOrReason:
              elem.Status === "Closed" ? elem.FCS_CaseReason__c : elem.Status
          };
        })
        .sort((first, second) => {
          if (first.CreatedDate > second.CreatedDate) {
            return -1;
          } else if (first.CreatedDate < second.CreatedDate) {
            return 1;
          } else {
            return 0;
          }
        });
      this.numberOfVisibleCases = this.cases.length;
      this.allCases = this.cases.length;
    } else {
      this.cases = [];
      this.numberOfVisibleCases = 0;
      this.allCases = 0;
    }
  }

  @wire(getBookingData, { accountId: "$accountId" })
  wiredBookings({ error, data }) {
    if (!error && data != undefined && data.length > 0) {
      this.bookings = data;
    } else {
      this.bookings = [];
    }
  }

  async addCustomerToCase(searchString) {
    this.showSpinner = true;
    try {
      let account = await findCustomer({
        searchField: "EBNumber__c",
        searchValue: searchString.trim()
      });
      if (account) {
        const recordInput = {
          fields: {
            [Case_ID_FIELD.fieldApiName]: this.recordId,
            [Case_ACCOUNTID_FIELD.fieldApiName]: account.Id
          }
        };

        try {
          await updateRecord(recordInput);
        } catch (error) {
          this.error = error;
        }
      } else {
        this.noSearchResult = true;
      }
    } catch (error) {
      this.error = error;
    }
    this.showSpinner = false;
  }

  async removeCustomerFromCase() {
    this.showSpinner = true;

    const recordInput = {
      fields: {
        [Case_ID_FIELD.fieldApiName]: this.recordId,
        [Case_ACCOUNTID_FIELD.fieldApiName]: ""
      }
    };

    try {
      await updateRecord(recordInput);
    } catch (error) {
      this.error = error;
    }

    this.searchValue = "";
    this.showSpinner = false;
    this.noSearchResult = false;
  }

  handlePressEnterKey(event) {
    if (event.key === "Enter") {
      this.handleSearchButtonClick();
    }
  }

  handleSearchValueChange(event) {
    this.searchValue = event.target.value;
    this.noSearchResult = false;
  }

  handleSearchButtonClick() {
    if (this.searchValue != "") {
      this.noSearchResult = false;
      this.addCustomerToCase(this.searchValue);
    }
  }
}

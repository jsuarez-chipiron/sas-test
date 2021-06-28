import { LightningElement, track, api, wire } from "lwc";
import getAccountData from "@salesforce/apex/CustomerCardController.getAccountData";
import getBookingData from "@salesforce/apex/CustomerCardController.getBookingData";
import getCaseData from "@salesforce/apex/CustomerCardController.getCaseData";
import Case_ACCOUNTID_FIELD from "@salesforce/schema/Case.AccountId";
import Case_EBNUMBER_FIELD from "@salesforce/schema/Case.FCS_EBNumber__c";
import ChatTranscript_ACCOUNTID_FIELD from "@salesforce/schema/LiveChatTranscript.AccountId";
import ChatTranscript_CASEID_FIELD from "@salesforce/schema/LiveChatTranscript.CaseId";
import ChatTranscript_EBNUMBER_FIELD from "@salesforce/schema/LiveChatTranscript.FCS_EBNumber__c";
import { getRecord } from "lightning/uiRecordApi";
import findCustomer from "@salesforce/apex/FCS_IdentifyCustomerController.findCustomer";
import updateRecordDataWithApex from "@salesforce/apex/FCS_IdentifyCustomerController.updateRecordDataWithApex";

export default class CustomerCard extends LightningElement {
  @api objectApiName;
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
  caseIdForChats = undefined;

  // UI state
  @track showSpinner = false;
  @track noSearchResult = false;
  @track error = false;
  @track searchValue = "";

  @wire(getRecord, {
    recordId: "$recordId",
    optionalFields: [
      // Use optional fields because object type varies
      ChatTranscript_ACCOUNTID_FIELD,
      ChatTranscript_CASEID_FIELD,
      ChatTranscript_EBNUMBER_FIELD,
      Case_ACCOUNTID_FIELD,
      Case_EBNUMBER_FIELD
    ]
  })
  wiredRecord({ error, data }) {
    console.log("apiName", this.objectApiName);
    console.log("data", data);
    if (!error && data) {
      if (!data.fields.AccountId.value) {
        if (!!data.fields.FCS_EBNumber__c.value) {
          // If a case has an EB number, but no linked account, attempt to do that.
          // This is necessary for automatic linking in chat cases. This logic should really be in a trigger
          // FIXME: Move this logic to trigger (if a case has eb number, assign account to it. After fix this so that we don't need eb number in the case.)
          this.addCustomerToCase(data.fields.FCS_EBNumber__c.value);
        } else {
          this.accountId = undefined;
        }
      } else {
        this.accountId = data.fields.AccountId.value;
      }
      if (this.objectApiName === "LiveChatTranscript") {
        this.caseIdForChats = data.fields.CaseId.value;
      }
    } else {
      this.accountId = undefined;
    }
    console.log("accountId", this.accountId);
  }

  @wire(getAccountData, { accountId: "$accountId" })
  wiredAccount({ error, data }) {
    console.log("get account data", data);
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
    console.log("#wiredCases.start");
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
    console.log("#wiredCases.end");
  }

  @wire(getBookingData, { accountId: "$accountId" })
  wiredBookings({ error, data }) {
    console.log("#wiredBookings.start");
    if (!error && data != undefined && data.length > 0) {
      this.bookings = data;
    } else {
      this.bookings = [];
    }
    console.log("#wiredBookings.end");
  }

  async addCustomerToCase(searchString) {
    console.log("#addCustomerToCase.start");
    this.showSpinner = true;
    try {
      let account = await findCustomer({
        searchField: "EBNumber__c",
        searchValue: searchString.trim()
      });
      if (account) {
        try {
          const recordInput = {
            recordId: this.recordId,
            accountId: account.Id,
            euroBonusNumber: account.FCS_EBNumber__c,
            caseId:
              this.objectApiName === "LiveChatTranscript"
                ? this.caseIdForChats
                : this.recordId
          };
          await updateRecordDataWithApex({
            jsonData: JSON.stringify(recordInput)
          });
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
    console.log("#addCustomerToCase.end");
  }

  async removeCustomerFromCase() {
    console.log("#removeCustomerToCase.start");
    this.showSpinner = true;
    try {
      const recordInput = {
        recordId: this.recordId,
        accountId: null,
        euroBonusNumber: null,
        codsId: null,
        caseId:
          this.objectApiName === "LiveChatTranscript"
            ? this.caseIdForChats
            : this.recordId
      };
      await updateRecordDataWithApex({ jsonData: JSON.stringify(recordInput) });
    } catch (error) {
      this.error = error;
    }

    this.searchValue = "";
    this.showSpinner = false;
    this.noSearchResult = false;
    this.accountId = undefined;
    this.account = undefined;
    this.bookings = [];
    this.cases = [];
    this.caseIdForChats = undefined;
    console.log("#removeCustomerToCase.end");
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

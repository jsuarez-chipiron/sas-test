import { LightningElement, track, api, wire } from "lwc";
import getAccountData from "@salesforce/apex/CustomerCardController.getAccountData";
import getBookingData from "@salesforce/apex/CustomerCardController.getBookingData";
import getCaseData from "@salesforce/apex/CustomerCardController.getCaseData";
import Case_ACCOUNTID_FIELD from "@salesforce/schema/Case.AccountId";
import { getRecord } from "lightning/uiRecordApi";

export default class CustomerCard extends LightningElement {
  @api recordId;

  @track account = undefined;
  @track accountName = undefined;
  @track bookings = [];
  @track cases = [];
  @track customerIdentified = false;

  accountId = undefined;

  @wire(getRecord, { recordId: "$recordId", fields: [Case_ACCOUNTID_FIELD] })
  wiredRecord({ error, data }) {
    if (error) {
      console.log("in #wiredRecord.error", error);
      let message = "Unknown error";
      if (Array.isArray(error.body)) {
        message = error.body.map((e) => e.message).join(", ");
      } else if (typeof error.body.message === "string") {
        message = error.body.message;
      }
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error loading wired data",
          message,
          variant: "error"
        })
      );
    } else if (data) {
      console.log("in #wiredRecord.data", data);
      this.accountId = data.fields.AccountId.value;
    }
  }
  @wire(getAccountData, { accountId: "$accountId" })
  wiredAccount({ error, data }) {
    if (error) {
      console.log("#getFullAccountData.error", error);
    } else {
      console.log("#getFullAccountData.data", data);
      if (data != undefined && data.length > 0) {
        this.account = data[0];
        this.accountName = `${data[0].Name} (${data[0].FCS_EBNumber__c})`;
        this.customerIdentified = true;
      } else {
        this.account = undefined;
        this.accountName = undefined;
        this.customerIdentified = false;
      }
    }
  }

  @wire(getCaseData, { accountId: "$accountId" })
  wiredCases({ error, data }) {
    if (error) {
      console.log("#getWiredCases.error", error);
    } else {
      console.log("#getWiredCases.data", data);
      if (data != undefined && data.length > 0) {
        this.cases = data.map(function (elem) {
          return {
            ...elem,
            recordUrl: `/${elem.Id}`,
            StatusOrReason:
              elem.Status === "Closed" ? elem.FCS_CaseReason__c : elem.Status
          };
        });
      } else {
        this.cases = [];
      }
    }
  }

  @wire(getBookingData, { accountId: "$accountId" })
  wiredBookings({ error, data }) {
    if (error) {
      console.log("#getWiredBookings.error", error);
    } else {
      console.log("#getWiredBookings.data", data);
      if (data != undefined && data.length > 0) {
        this.bookings = data;
      } else {
        this.bookings = [];
      }
    }
  }
}

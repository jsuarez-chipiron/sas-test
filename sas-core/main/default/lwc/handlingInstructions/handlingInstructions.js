import { LightningElement, wire, api } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import HANDLING_INSTRUCTIONS from "@salesforce/schema/Case.Handling_Instructions__c";

export default class HandlingInstructions extends LightningElement {
  @api recordId;
  hasHandlingInstructions = false;
  handlingInstructions = "";

  @wire(getRecord, {
    recordId: "$recordId",
    fields: [HANDLING_INSTRUCTIONS]
  })
  wiredCase({ data }) {
    if (data) {
      console.log("fields", data.fields);
      if (data.fields.Handling_Instructions__c.value != null) {
        this.hasHandlingInstructions = true;
        this.handlingInstructions =
          data.fields.Handling_Instructions__c.value.split("|");
      }
    }
  }
}

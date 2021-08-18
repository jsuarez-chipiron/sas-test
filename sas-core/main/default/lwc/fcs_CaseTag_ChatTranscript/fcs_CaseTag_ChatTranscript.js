import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import findCase from "@salesforce/apex/FCS_CaseTag_ChatTranscript_Controller.findCase";
export default class Fcs_CaseTag extends LightningElement {
  @api recordId;
  @track cse;
  @track error = undefined;
  @track RecordTypeId;
  @wire(findCase, {
    recordId: "$recordId"
  })
  wiredcse({ error, data }) {
    if (data) {
      try {
        this.cse = data;
        this.RecordTypeId = this.cse.RecordTypeId;
      } catch (error) {
        this.cse = undefined;
        this.displayError(error);
      }
    } else if (error) {
      this.cse = undefined;
      this.displayError(error);
    }
  }
  displayError(error) {
    this.error = error;
  }
  handleSuccess(event) {
    const evt = new ShowToastEvent({
      title: "Success",
      message: "Submitted Successfully",
      variant: "success"
    });
    this.dispatchEvent(evt);
  }
  handleReset(event) {
    const inputFields = this.template.querySelectorAll("lightning-input-field");
    if (inputFields) {
      inputFields.forEach((field) => {
        field.reset();
      });
    }
  }
}

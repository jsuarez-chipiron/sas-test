import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import findCase from "@salesforce/apex/FCS_CaseTag_Controller.findCase";
import findCaseTag from "@salesforce/apex/FCS_CaseTag_Controller.findCaseTag";
export default class Fcs_CaseTag extends LightningElement {
  @api recordId;
  @track cse;
  @track error = undefined;
  @track RecordTypeId;
  @track hideResolutionComment = false;
  @track caseTagged = false;
  @track caseTag;
  @track reset = false;
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
  @wire(findCaseTag, {
    recordId: "$recordId"
  })
  wiredCaseTag({ error, data }) {
    if (data) {
      try {
        this.caseTag = data;
        this.caseTagged = true;
      } catch (error) {
        this.caseTag = undefined;
      }
    } else {
      this.displayError(error);
    }
  }
  handleDataChange(event) {
    this.reason = event.target.value;
    if (this.reason == "other") {
      this.hideResolutionComment = true;
    } else {
      this.hideResolutionComment = false;
    }
  }
  displayError(error) {
    this.error = error;
  }
  handleSuccess(event) {
    if (!this.reset) {
      const evt = new ShowToastEvent({
        title: "Success",
        message: "Submitted Successfully",
        variant: "success"
      });
      this.caseTagged = true;
      this.dispatchEvent(evt);
    }
    this.reset = false;
  }
  handleReset(event) {
    const inputFields = this.template.querySelectorAll("lightning-input-field");
    if (inputFields) {
      inputFields.forEach((field) => {
        field.reset();
      });
      if (this.caseTagged) {
        this.reset = true;
      }
    }
  }
}

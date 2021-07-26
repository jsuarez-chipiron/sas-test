import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import Case_RECORDTYPE_FIELD from "@salesforce/schema/Case.RecordTypeId";
import { getRecord } from "lightning/uiRecordApi";
import findCaseTag from "@salesforce/apex/FCS_CaseTag_Controller.findCaseTag";
export default class Fcs_CaseTag extends LightningElement {
  @api recordId;
  @track recordTypeId;
  @track case;
  @track error = undefined;
  @track caseTag;
  @track caseTagged = false;
  @track hideResolutionComment = false;
  @track reset = false;
  @wire(getRecord, {
    recordId: "$recordId",
    fields: [Case_RECORDTYPE_FIELD]
  })
  getCase({ error, data }) {
    if (data) {
      var result = JSON.parse(JSON.stringify(data));
      this.account = result;
      this.recordTypeId = result.fields.RecordTypeId.value;
    } else if (error) {
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
}

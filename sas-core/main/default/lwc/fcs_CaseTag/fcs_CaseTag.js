import { LightningElement, api, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import Case_RECORDTYPE_FIELD from "@salesforce/schema/Case.RecordTypeId";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import Case_REASON_FIELD from '@salesforce/schema/Case.FCS_Case_Reason__c';
const fields = [Case_RECORDTYPE_FIELD, Case_REASON_FIELD];
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
    recordId: "$recordId", fields })
  getCase({ error, data }) {
    if (data) {
      var result = JSON.parse(JSON.stringify(data));
      this.recordTypeId = result.fields.RecordTypeId.value; 
      let caseReason =  result.fields.FCS_Case_Reason__c.value; 
      if(caseReason)
      {
        this.caseTagged = true;
      }
    } else if (error) {
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

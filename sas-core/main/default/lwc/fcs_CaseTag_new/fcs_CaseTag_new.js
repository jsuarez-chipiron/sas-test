import { LightningElement, api, wire, track } from "lwc";
import findCase from "@salesforce/apex/FCS_CaseTag_Controller.findCase";
import createCaseRecord from "@salesforce/apex/FCS_CaseTag_Controller.createCaseRecord";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
export default class Fcs_CaseTag_SocialPost extends LightningElement {
  @api recordId;
  @track recordTypeId;
  @track cardTitle = "Tag a Case";
  @track iconName = "action:new_case";
  @track newCase = true;
  @track cse;
  @track caseTagged = false;
  @track reset = false;
  @track showResolutionComment = false;

  department;
  @wire(findCase, {
    recordId: "$recordId"
  })
  wiredcse({ error, data }) {
    if (data) {
      this.cse = data;
      this.department = this.cse.Department__c;
      this.recordTypeId = this.cse.RecordTypeId;
      if (this.cse.Id) {
        this.newCase = false;
        if (this.cse.FCS_Case_Reason__c) {
          this.cardTitle = "Case is Tagged";
          this.iconName = "action:approval";
          this.caseTagged = true;
        }
      }
    } else if (error) {
      this.displayError(error);
    }
  }
  createRecord(event) {
    event.preventDefault();
    var casereason = this.template.querySelector(".reason").value;
    let cont = { sobjectType: "Case" };
    cont.Department__c = this.template.querySelector(".department").value;
    cont.FCS_CaseType__c = this.template.querySelector(".type").value;
    cont.FCS_Case_Reason__c = this.template.querySelector(".reason").value;
    cont.FCS_CaseResolution__c =
      this.template.querySelector(".resolution").value;
    if (casereason == "other") {
      if (this.template.querySelector(".resolutionDetails").value) {
        cont.FCS_CaseResolutionDetails__c =
          this.template.querySelector(".resolutionDetails").value;
      }
    }

    createCaseRecord({ newRecord: cont, recordId: this.recordId })
      .then((result) => {
        this.recordId = result;
        console.log(result);
      })
      .catch((error) => {
        console.log(error);
        this.error = error;
      });
  }
  handleDataChange(event) {
    let reason = event.target.value;
    console.log("******" + reason);
    if (reason == "Other") {
      console.log("reason***" + reason);
      this.showResolutionComment = true;
    } else {
      this.showResolutionComment = false;
    }
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
  handleSuccess(event) {
    if (!this.reset) {
      const evt = new ShowToastEvent({
        title: "Success",
        message: "Submitted Successfully",
        variant: "success"
      });
      this.cardTitle = "Case is Tagged";
      this.iconName = "action:approval";
      this.reset = true;
      this.dispatchEvent(evt);
    }
    this.reset = false;
  }
}

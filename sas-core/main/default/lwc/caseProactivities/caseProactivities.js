import { LightningElement, wire, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getProactivitiesForCase from "@salesforce/apex/ProactivitiesController.getProactivitiesForCase";

export default class CaseProactivities extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  columns = [
    { label: "Note", fieldName: "note" },
    { label: "Match on", fieldName: "matchingReasons", initialWidth: 120 },
    {
      label: "Details",
      fieldName: "url",
      type: "url",
      typeAttributes: { label: "link" },
      initialWidth: 60
    }
  ];

  rows = [];
  showSpinner = true;
  error = undefined;
  proactivitiesFound = false;

  @wire(getProactivitiesForCase, { caseId: "$recordId" })
  wiredProactivities({ error, data }) {
    if (error) {
      this.showSpinner = false;
      this.error = error;
      this.proactivitiesFound = false;
    } else if (data == undefined || data.length === 0) {
      this.rows = [];
      this.showSpinner = false;
      this.proactivitiesFound = false;
    } else {
      this.rows = data.map((proactivity, idx) => {
        return {
          idx,
          id: proactivity.id,
          note: proactivity.note,
          matchingReasons: proactivity.matchingReasons
        };
      });

      this.rows.forEach((row, idx) =>
        this[NavigationMixin.GenerateUrl]({
          type: "standard__recordPage",
          attributes: {
            recordId: row.id,
            objectApiName: "Proactivity__c",
            actionName: "view"
          }
        }).then((url) => {
          this.rows[idx] = { ...this.rows[idx], url };
          let res = [...this.rows];

          res[idx] = { ...res[idx], url };

          this.rows = res;
        })
      );

      this.showSpinner = false;
      this.proactivitiesFound = true;
    }
  }
}

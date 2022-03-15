import { LightningElement, wire, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getCasesForProactivity from "@salesforce/apex/ProactivitiesController.getCasesForProactivity";

export default class CaseProactivities extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  columns = [
    { label: "Case Number", fieldName: "CaseNumber" },
    { label: "Status", fieldName: "Status", initialWidth: 120 },
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
  casesFound = false;

  get cardTitle() {
    return `Matching Cases (${this.rows.length})`;
  }

  @wire(getCasesForProactivity, { proactivityId: "$recordId" })
  wiredCases({ error, data }) {
    if (error) {
      this.showSpinner = false;
      this.error = error;
    } else if (data == undefined || data.length === 0) {
      this.rows = [];
      this.showSpinner = false;
      this.casesFound = false;
    } else {
      this.rows = data.map((caseData, idx) => ({
        ...caseData,
        idx
      }));

      this.rows.forEach((row, idx) =>
        this[NavigationMixin.GenerateUrl]({
          type: "standard__recordPage",
          attributes: {
            recordId: row.Id,
            objectApiName: "Case",
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
      this.casesFound = true;
    }
  }
}

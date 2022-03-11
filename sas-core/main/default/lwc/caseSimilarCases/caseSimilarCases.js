import { LightningElement, wire, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getSimilarCasesForCase from "@salesforce/apex/SimilarCasesController.getSimilarCasesForCase";

export default class CaseSimilarCases extends NavigationMixin(
  LightningElement
) {
  @api recordId;
  columns = [
    {
      label: "Case",
      fieldName: "url",
      type: "url",
      typeAttributes: {
        label: {
          fieldName: "caseNumber"
        }
      }
    },
    { label: "Status", fieldName: "status" },
    { label: "Owner", fieldName: "owner" },
    { label: "Created", fieldName: "date", type: "date" },
    {
      label: "PNR",
      fieldName: "bookingReference",
      cellAttributes: {
        class: {
          fieldName: "classNamePnr"
        }
      }
    },
    {
      label: "PIR",
      fieldName: "pir",
      cellAttributes: {
        class: {
          fieldName: "classNamePir"
        }
      }
    },
    {
      label: "EB",
      fieldName: "EbNumber",
      cellAttributes: {
        class: {
          fieldName: "classNameEbNumber"
        }
      }
    },
    {
      label: "Flight",
      fieldName: "flight",
      cellAttributes: {
        class: {
          fieldName: "classNameFlight"
        }
      }
    },
    {
      label: "Email",
      fieldName: "email",
      cellAttributes: {
        class: {
          fieldName: "classNameEmail"
        }
      }
    }
  ];

  rows = [];
  showSpinner = true;
  error = undefined;
  similarCasesFound = false;

  get cardTitle() {
    return `Similar Cases (${this.rows.length})`;
  }

  // Sorts cases first on number of matches and secondarily on matching field names for a grouped sort.
  sortCasesBySimilarity(first, second) {
    const subSort = (a, b) => {
      if (a.matchingFields[0][0] < b.matchingFields[0][0]) {
        return 1;
      } else if (a.matchingFields[0][0] > b.matchingFields[0][0]) {
        return -1;
      } else if (a.matchingFields.length > 1 && b.matchingFields.length > 1) {
        subSort(
          { ...a, matchingFields: a.matchingFields.slice(1) },
          {
            ...b,
            matchingFields: b.matchingFields.slice(1)
          }
        );
      } else {
        return 0;
      }
    };
    // Sort first by number of matching fields.
    if (first.numberOfMatches > second.numberOfMatches) {
      return -1;
    } else if (first.numberOfMatches < second.numberOfMatches) {
      return 1;
    } else {
      // Equal number of matching fields, sort by sorted list of matching fields so same matches on same fields are next to each other.
      return subSort(first, second);
    }
  }

  @wire(getSimilarCasesForCase, { caseId: "$recordId" })
  wiredCases({ error, data }) {
    if (error) {
      console.log(error.body.message);
      this.showSpinner = false;
      this.error = error;
      this.similarCasesFound = false;
    } else if (data == undefined || data.length === 0) {
      this.rows = [];
      this.showSpinner = false;
      this.similarCasesFound = false;
    } else {
      const getClassName = (caseData, fieldName) =>
        caseData[fieldName] != undefined &&
        caseData[fieldName] === thisCase[fieldName]
          ? "slds-text-color_success"
          : "";

      const fields = ["EbNumber", "email", "flight", "pir", "bookingReference"];

      const getNumMatches = (caseData) =>
        fields.reduce(
          (prev, curr) =>
            caseData[curr] != undefined && caseData[curr] === thisCase[curr]
              ? prev + 1
              : prev,
          0
        );

      const getMatchingFields = (caseData) =>
        fields.reduce(
          (prev, curr) =>
            caseData[curr] != undefined && caseData[curr] === thisCase[curr]
              ? prev.concat(curr)
              : prev,
          []
        );

      const formattedCases = data.map((caseWithClaim, idx) => {
        return {
          idx,
          id: caseWithClaim.Id,
          caseNumber: caseWithClaim.CaseNumber,
          bookingReference: caseWithClaim.Claims__r[0].Liability_PNR__c,
          date: caseWithClaim.CreatedDate,
          EbNumber: caseWithClaim.Claims__r[0].EuroBonus_Number__c,
          email: caseWithClaim.Claims__r[0].Contact_Email__c,
          flight:
            caseWithClaim.Claims__r[0].Flight_Number__c +
            "-" +
            caseWithClaim.Claims__r[0].Flight_Date__c,
          owner: caseWithClaim.Owner.Name,
          pir: caseWithClaim.Claims__r[0].PIR__c,
          status: caseWithClaim.Status
        };
      });

      const thisCase = formattedCases.filter(
        (caseWithClaim) => caseWithClaim.id === this.recordId
      )[0];

      const casesWithDisplayDetails = formattedCases
        .filter((caseWithClaim) => caseWithClaim.id !== this.recordId)
        .map((parsedCase) => ({
          ...parsedCase,
          classNameEbNumber: getClassName(parsedCase, "EbNumber"),
          classNameEmail: getClassName(parsedCase, "email"),
          classNameFlight: getClassName(parsedCase, "flight"),
          classNamePir: getClassName(parsedCase, "pir"),
          classNamePnr: getClassName(parsedCase, "bookingReference"),
          numberOfMatches: getNumMatches(parsedCase),
          matchingFields: getMatchingFields(parsedCase)
        }));

      this.rows = [...casesWithDisplayDetails.sort(this.sortCasesBySimilarity)];

      this.rows.forEach((row, idx) =>
        this[NavigationMixin.GenerateUrl]({
          type: "standard__recordPage",
          attributes: {
            recordId: row.id,
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
      this.similarCasesFound = true;
    }
  }
}

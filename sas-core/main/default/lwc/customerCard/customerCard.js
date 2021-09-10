import { LightningElement, track, api, wire } from "lwc";
import getAccountData from "@salesforce/apex/CustomerCardController.getAccountData";
import getBookingData from "@salesforce/apex/CustomerCardController.getBookingData";
import getCaseData from "@salesforce/apex/CustomerCardController.getCaseData";
import Case_ACCOUNTID_FIELD from "@salesforce/schema/Case.AccountId";
import getAllCommunicationData from "@salesforce/apex/CustomerCardController.getAllCommunicationData";
import Case_EBNUMBER_FIELD from "@salesforce/schema/Case.FCS_EBNumber__c";
import ChatTranscript_ACCOUNTID_FIELD from "@salesforce/schema/LiveChatTranscript.AccountId";
import ChatTranscript_CASEID_FIELD from "@salesforce/schema/LiveChatTranscript.CaseId";
import ChatTranscript_EBNUMBER_FIELD from "@salesforce/schema/LiveChatTranscript.FCS_EBNumber__c";
import { getRecord } from "lightning/uiRecordApi";
import findCustomer from "@salesforce/apex/FCS_IdentifyCustomerController.findCustomer";
import updateRecordDataWithApex from "@salesforce/apex/FCS_IdentifyCustomerController.updateRecordDataWithApex";
import { refreshApex } from "@salesforce/apex";
import { NavigationMixin } from "lightning/navigation";
import { formattedDateString } from "c/utilDate";

export default class CustomerCard extends NavigationMixin(LightningElement) {
  @api objectApiName;
  @api recordId;

  ENTRIES_TO_DISPLAY = 3;

  // data fields
  @track account = undefined;
  @track bookings = [];
  @track cases = [];
  @track communicationLogs = [];
  wiredRecordReference;
  wiredBookingsReference;

  // properties calculated from data
  @track cardTitle = "";
  accountId = undefined;
  caseIdForChats = undefined;

  // UI state
  @track showSpinner = false;
  @track noSearchResult = false;
  @track error = false;
  @track searchValue = "";
  showAllBookings = false;
  showAllLogs = false;

  get bookingsCount() {
    return `${
      this.showAllBookings
        ? this.bookings.length
        : Math.min(ENTRIES_TO_DISPLAY, this.bookings.length)
    } of ${this.bookings.length}`;
  }

  get logsCount() {
    return `${
      this.showAllLogs
        ? this.communicationLogs.length
        : Math.min(this.ENTRIES_TO_DISPLAY, this.communicationLogs.length)
    } of ${this.communicationLogs.length}`;
  }

  get visibleBookings() {
    return this.showAllBookings
      ? this.bookings
      : this.bookings.slice(
          0,
          Math.min(this.ENTRIES_TO_DISPLAY, this.bookings.length)
        );
  }

  get visibleLogs() {
    return this.showAllLogs
      ? this.communicationLogs
      : this.communicationLogs.slice(
          0,
          Math.min(this.ENTRIES_TO_DISPLAY, this.communicationLogs.length)
        );
  }

  get noCommunicationLogs() {
    return this.communicationLogs.length === 0;
  }

  get noBookings() {
    return this.bookings.length === 0;
  }

  // Navigate to view case Page
  navigateToCaseViewPage(event) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: event.target.dataset.id,
        objectApiName: "Case",
        actionName: "view"
      }
    });
  }
  @wire(getRecord, {
    recordId: "$recordId",
    optionalFields: [
      // Use optional fields because object type varies
      ChatTranscript_ACCOUNTID_FIELD,
      ChatTranscript_CASEID_FIELD,
      ChatTranscript_EBNUMBER_FIELD,
      Case_ACCOUNTID_FIELD,
      Case_EBNUMBER_FIELD
    ]
  })
  wiredRecord(value) {
    this.wiredRecordReference = value;
    const { data, error } = value;
    if (!error && data) {
      if (!data.fields.AccountId.value) {
        if (!!data.fields.FCS_EBNumber__c.value) {
          // If a case has an EB number, but no linked account, attempt to do that.
          // This is necessary for automatic linking in chat cases. This logic should really be in a trigger
          // FIXME: Move this logic to trigger (if a case has eb number, assign account to it. After fix this so that we don't need eb number in the case.)
          this.addCustomerToCase(data.fields.FCS_EBNumber__c.value);
        } else {
          this.accountId = undefined;
        }
      } else {
        this.accountId = data.fields.AccountId.value;
      }
      if (this.objectApiName === "LiveChatTranscript") {
        this.caseIdForChats = data.fields.CaseId.value;
      }
    } else {
      this.accountId = undefined;
    }
  }

  @wire(getAccountData, { accountId: "$accountId" })
  wiredAccount({ error, data }) {
    if (!error && data != undefined && data.length > 0) {
      this.account = data[0];
      this.cardTitle = `${data[0].Name} (EB${data[0].FCS_EBLevel__c}${data[0].FCS_EBNumber__c})`;
    } else {
      this.account = undefined;
      this.cardTitle = "";
    }
  }

  @wire(getCaseData, { accountId: "$accountId" })
  wiredCases({ error, data }) {
    if (!error && data != undefined && data.length > 0) {
      this.cases = data;
    } else {
      this.cases = [];
    }
  }

  @wire(getBookingData, { accountId: "$accountId" })
  wiredBookings(value) {
    this.wiredBookingsReference = value;
    const { data, error } = value;
    function getAirportListForBooking(booking) {
      if (!booking.flights || booking.flights.length < 1) {
        return "";
      }
      return booking.flights
        .reduce((acc, curr) => {
          if (acc.length === 0) {
            return [curr.departureAirport, curr.arrivalAirport];
          } else {
            if (acc[acc.length - 1] === curr.departureAirport) {
              return acc.concat(curr.arrivalAirport);
            }
            return acc.concat([curr.departureAirport, curr.arrivalAirport]);
          }
        }, [])
        .join("-");
    }

    if (!error && data != undefined && data.length > 0) {
      const TODAY = new Date();

      this.bookings = data.map((booking) => {
        const scheduledDate = new Date(
          booking.flights[0].scheduledDepartureTime
        );

        return {
          ...booking,
          className:
            scheduledDate >= TODAY
              ? "slds-item booking-bullet future-booking-bullet"
              : "slds-item booking-bullet past-booking-bullet",
          accordionTitle: `${formattedDateString(
            booking.flights[0].scheduledDepartureTimeLocal,
            "date"
          )} ${getAirportListForBooking(booking)}`,
          flights: booking.flights.map((f) => ({
            ...f,
            scheduledDepartureTimeLocal: formattedDateString(
              f.scheduledDepartureTimeLocal,
              "date"
            )
          })),
          passengers: booking.passengers.map((p) => ({
            ...p,
            ssrs:
              p.specialServiceRequests && p.specialServiceRequests.length > 0
                ? p.specialServiceRequests[0]
                : ""
          }))
        };
      });
      if (this.bookings.length <= 3) {
        this.showAllBookings = true;
      }
    } else {
      this.bookings = [];
      this.showAllBookings = true;
    }
  }

  // TODO: Enable when we can get communication logs
  /*@wire(getAllCommunicationData, { accountId: "$accountId" })
  wiredCommunicationLog({ error, data }) {
    if (!error && data != undefined && data.length > 0) {
      this.communicationLogs = data.map((rawLog) => ({
        ...rawLog,
        communicationName: rawLog.IRR_FlightId__c
          ? rawLog.IRR_FlightId__c.substring(
              0,
              Math.min(6, rawLog.IRR_FlightId__c.length)
            )
          : ""
      }));
      if (this.communicationLogs.length <= 3) {
        this.showAllLogs = true;
      }
    } else {
      this.communicationLogs = [];
      this.showAllLogs = true;
    }
  }*/

  async addCustomerToCase(searchString) {
    this.showSpinner = true;
    try {
      let account = await findCustomer({
        searchField: "EBNumber__c",
        searchValue: searchString.trim()
      });
      if (account) {
        try {
          const recordInput = {
            recordId: this.recordId,
            accountId: account.Id,
            euroBonusNumber: account.FCS_EBNumber__c,
            caseId:
              this.objectApiName === "LiveChatTranscript"
                ? this.caseIdForChats
                : this.recordId
          };
          await updateRecordDataWithApex({
            jsonData: JSON.stringify(recordInput)
          });
          refreshApex(this.wiredRecordReference);
          // Force refetch of bookings after 5s so that all fetches and DML have had time to finish
          // FIXME: Make booking data fetches awaitable so that we can remove this hack
          setTimeout(() => refreshApex(this.wiredBookingsReference), 5000);
        } catch (error) {
          this.error = error;
        }
      } else {
        this.noSearchResult = true;
      }
    } catch (error) {
      this.error = error;
    }
    this.showSpinner = false;
  }

  async removeCustomerFromCase() {
    this.showSpinner = true;
    try {
      const recordInput = {
        recordId: this.recordId,
        accountId: null,
        euroBonusNumber: null,
        codsId: null,
        caseId:
          this.objectApiName === "LiveChatTranscript"
            ? this.caseIdForChats
            : this.recordId
      };
      await updateRecordDataWithApex({ jsonData: JSON.stringify(recordInput) });
      refreshApex(this.wiredRecordReference);
    } catch (error) {
      this.error = error;
    }

    this.searchValue = "";
    this.showSpinner = false;
    this.noSearchResult = false;
    this.accountId = undefined;
    this.account = undefined;
    this.bookings = [];
    this.cases = [];
    this.caseIdForChats = undefined;
  }

  handlePressEnterKey(event) {
    if (event.key === "Enter") {
      this.handleSearchButtonClick();
    }
  }

  handleSearchValueChange(event) {
    this.searchValue = event.target.value;
    this.noSearchResult = false;
  }

  handleSearchButtonClick() {
    if (this.searchValue != "") {
      this.noSearchResult = false;
      this.addCustomerToCase(this.searchValue);
    }
  }

  handleDisplayAllBookings() {
    this.showAllBookings = true;
  }

  handleDisplayAllLogs() {
    this.showAllLogs = true;
  }
}

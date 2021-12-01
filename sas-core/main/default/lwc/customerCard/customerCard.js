import { LightningElement, track, api, wire } from "lwc";
import getAccountData from "@salesforce/apex/CustomerCardController.getAccountData";
import getBookingData from "@salesforce/apex/CustomerCardController.getBookingData";
import getCaseData from "@salesforce/apex/CustomerCardController.getCaseData";
import getTPProductsForAccount from "@salesforce/apex/CustomerCardController.getTPProductsForAccount";
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
import { formattedDateString } from "c/utilDate";
import refetchTPProducts from "@salesforce/apex/CustomerCardController.refetchTPProducts";
import { NavigationMixin } from "lightning/navigation";

export default class CustomerCard extends NavigationMixin(LightningElement) {
  @api objectApiName;
  @api recordId;

  ENTRIES_TO_DISPLAY = 3;

  // data fields
  @track account = undefined;
  @track bookings = [];
  @track cases = [];
  @track communicationLogs = [];
  @track tpProducts = [];
  wiredRecordReference;
  wiredBookingsReference;
  wiredTPProductsReference;

  // properties calculated from data
  @track cardTitle = "";
  accountId = undefined;
  caseIdForChats = undefined;
  euroBonusNumber = undefined;
  tpProductsLastModified = "-";

  // UI state
  @track showSpinner = false;
  @track noSearchResult = false;
  @track error = false;
  @track searchValue = "";
  showAllBookings = false;

  get bookingsCount() {
    return `${
      this.showAllBookings
        ? this.bookings.length
        : Math.min(ENTRIES_TO_DISPLAY, this.bookings.length)
    } of ${this.bookings.length}`;
  }

  get visibleBookings() {
    return this.showAllBookings
      ? this.bookings
      : this.bookings.slice(
          0,
          Math.min(this.ENTRIES_TO_DISPLAY, this.bookings.length)
        );
  }

  get noBookings() {
    return this.bookings.length === 0;
  }

  get communicationLogsTabTitle() {
    return `Communication logs (${this.communicationLogs.length})`;
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
      this.account = {
        ...data[0],
        cmpCode: data[0].FCS_CMP__c || "-",
        tpNumber: data[0].FCS_TPAccountNumber__c || "-"
      };
      if (
        data[0].FCS_EBLevel__c != undefined &&
        data[0].FCS_EBNumber__c != undefined
      ) {
        this.cardTitle = `${data[0].Name} (EB${data[0].FCS_EBLevel__c}${data[0].FCS_EBNumber__c})`;
      } else {
        this.cardTitle = data[0].Name;
      }
      if (data[0].FCS_EBNumber__c != undefined) {
        this.euroBonusNumber = data[0].FCS_EBNumber__c;
      }
    } else {
      this.account = undefined;
      this.cardTitle = "";
    }
  }

  @wire(getTPProductsForAccount, { accountId: "$accountId" })
  wiredTPProducts(value) {
    this.wiredTPProductsReference = value;
    const { data, error } = value;
    if (!error && data != undefined && data.length > 0) {
      this.tpProducts = data;
      this.tpProductsLastModified = data[0].LastModifiedDate;
    } else {
      this.tpProducts = [];
      this.tpProductsLastModified = "-";
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
            ),
            segmentStatusCode: f.segmentStatusCode || "-"
          })),
          passengers: booking.passengers.map((p) => ({
            ...p,
            ssrs:
              p.specialServiceRequests && p.specialServiceRequests.length > 0
                ? p.specialServiceRequests[0]
                : ""
          })),
          travelOfficeId:
            booking.createdAtTravelOfficeId &&
            booking.createdAtTravelOfficeId.length > 0
              ? `/${booking.createdAtTravelOfficeId}`
              : ""
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

  @wire(getAllCommunicationData, {
    euroBonusNumber: "$euroBonusNumber"
  })
  wiredCommunicationLog({ error, data }) {
    if (!error && data != undefined && data.length > 0) {
      this.communicationLogs = data;
    } else {
      this.communicationLogs = [];
    }
  }

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

  navigateToTPProductPage(event) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: event.target.dataset.id,
        objectApiName: "Travel_Pass_Product__c",
        actionName: "view"
      }
    });
  }

  async refreshTPProducts() {
    this.showSpinner = true;
    try {
      await refetchTPProducts({
        accountId: this.accountId
      });
    } catch (error) {
      this.error = error;
    }
    setTimeout(() => {
      // Timeout because bookings haven't finished updating during the await
      refreshApex(this.wiredTPProductsReference);
      this.showSpinner = false;
    }, 6000);
  }
}

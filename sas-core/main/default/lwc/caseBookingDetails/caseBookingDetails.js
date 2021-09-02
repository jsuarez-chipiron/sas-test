import { LightningElement, track, api, wire } from "lwc";
import addBookingToCaseApex from "@salesforce/apex/CustomerCardController.addBookingToCase";
import getBookingsForCaseApex from "@salesforce/apex/CustomerCardController.getBookingsForCase";
import removeBookingFromCaseApex from "@salesforce/apex/CustomerCardController.removeBookingFromCase";
import refetchBookingDataApex from "@salesforce/apex/CustomerCardController.refetchBookingData";
import ChatTranscript_CASEID_FIELD from "@salesforce/schema/LiveChatTranscript.CaseId";
import { refreshApex } from "@salesforce/apex";
import { getRecord } from "lightning/uiRecordApi";
import { NavigationMixin } from "lightning/navigation";

export default class CaseBookingDetails extends NavigationMixin(
  LightningElement
) {
  @api objectApiName;
  @api recordId;

  ENTRIES_TO_DISPLAY = 3;

  // data fields
  bookings = undefined;
  caseId = undefined;

  get visibleBookingData() {
    // Get only the booking data which should be visible

    return this.bookings
      ? this.bookings.map((booking) => {
          const caseCount = booking.relatedCases
            ? booking.relatedCases.filter((c) => c.Id !== this.caseId).length
            : 0;

          return {
            ...booking,
            caseTabTitle: `Related cases (${caseCount})`,
            noCases: caseCount === 0,
            relatedCases: booking.relatedCases.filter(
              (c) => c.Id !== this.caseId
            ),
            displayDetails: {
              ...booking.displayDetails,
              passengersVisible: `${
                booking.displayDetails.showAllPassengers
                  ? booking.passengers.length
                  : this.ENTRIES_TO_DISPLAY
              } of ${booking.passengers.length}`,
              flightsVisible: `${
                booking.displayDetails.showAllFlights
                  ? booking.trips.reduce(
                      (acc, curr) => acc + curr.flights.length,
                      0
                    )
                  : Math.min(
                      this.ENTRIES_TO_DISPLAY,
                      booking.trips[0].flights.length
                    )
              } of ${booking.trips.reduce(
                (acc, curr) => acc + curr.flights.length,
                0
              )}`
            },
            passengers: booking.displayDetails.showAllPassengers
              ? booking.passengers
              : booking.passengers.slice(
                  0,
                  Math.min(booking.passengers.length, this.ENTRIES_TO_DISPLAY)
                ),

            trips: booking.displayDetails.showAllFlights
              ? booking.trips
              : [
                  // If we display only some flights, display only flights from the first trip
                  {
                    ...booking.trips[0],
                    flights: booking.trips[0].flights.slice(
                      0,
                      Math.min(
                        booking.trips[0].flights.length,
                        this.ENTRIES_TO_DISPLAY
                      )
                    )
                  }
                ]
          };
        })
      : undefined;
  }

  wiredRecordReference;
  wiredBookingsReference;

  // UI state
  @track showSpinner = false;
  @track noSearchResult = false;
  @track error = false;
  @track searchValue = "";
  displayAddAnotherBookingForm = false;

  @wire(getRecord, {
    recordId: "$recordId",
    optionalFields: [
      // Use optional fields because object type varies
      ChatTranscript_CASEID_FIELD
    ]
  })
  wiredRecord(value) {
    this.wiredRecordReference = value;
    const { data, error } = value;
    if (!error && data) {
      if (this.objectApiName === "LiveChatTranscript") {
        this.caseId = data.fields.CaseId.value;
      } else {
        this.caseId = this.recordId;
      }
    }
  }

  @wire(getBookingsForCaseApex, { caseId: "$caseId" })
  wiredBookings(value) {
    this.wiredBookingsReference = value;
    const { data, error } = value;

    if (error) {
      this.error = error;
      this.bookings = undefined;
      return;
    }

    const toCapitalCase = (s) => {
      if (typeof s !== "string" || s.length < 1) {
        return s;
      } else {
        return s.charAt(0).toUpperCase() + s.slice(1).toLowerCase();
      }
    };

    const minutesToHoursAndMinutes = (s) => {
      if (!s) {
        return "0h 00m";
      } else {
        const hours = Math.floor(s / 60);
        const minutes = s - hours * 60;

        return `${hours}h ${minutes < 10 ? "0" : ""}${minutes}m`;
      }
    };

    if (data != undefined && data.length > 0) {
      console.log("data", data);

      this.bookings = data.map((b) => {
        const caseCount = b.relatedCases
          ? b.relatedCases.filter((c) => c.Id !== "$caseId").length
          : 0;

        return {
          ...b,
          displayDetails: {
            showAllPassengers: b.passengers.length <= this.ENTRIES_TO_DISPLAY,
            showAllFlights: b.flights.length <= this.ENTRIES_TO_DISPLAY
          },
          relatedCases: b.relatedCases
            ? b.relatedCases.map((c) => ({
                ...c,
                className:
                  c.Status === "Closed"
                    ? "slds-item case-bullet closed-case-bullet"
                    : "slds-item case-bullet open-case-bullet",
                StatusOrReason:
                  c.Status === "Closed" ? c.FCS_CaseReason__c : c.Status
              }))
            : [],
          trips: Object.entries(
            b.flights
              .map((f) => {
                const arrivalDelayed =
                  f.arrivalStatus === "delayed" ||
                  f.arrivalStatus === "cancelled";
                const departureDelayed =
                  f.departureStatus === "delayed" ||
                  f.departureStatus === "cancelled";

                return {
                  ...f,
                  arrivalDelayed,
                  arrivalDelayedMinutes: minutesToHoursAndMinutes(
                    f.arrivalDelayedMinutes
                  ),
                  arrivalTimeClassName: arrivalDelayed ? "delayedTime" : "",
                  arrivalGate: f.arrivalGate || "-",
                  arrivalTerminal: f.arrivalTerminal || "-",
                  bookingClass: f.bookingClass || "-",
                  departureDelayed,
                  departureDelayedMinutes: minutesToHoursAndMinutes(
                    f.departureDelayedMinutes
                  ),
                  departureTimeClassName: departureDelayed ? "delayedTime" : "",
                  departureGate: f.departureGate || "-",
                  departureTerminal: f.departureTerminal || "-",
                  fareBasis: f.fareBasis || "-",
                  bulletClassName: departureDelayed
                    ? "flight-bullet-delayed"
                    : "flight-bullet-on-time",
                  serviceClass: f.serviceClass || "-"
                };
              })
              .reduce(
                (acc, curr) => ({
                  ...acc,
                  [curr.tripType]: (acc[curr.tripType] || []).concat(curr)
                }),
                {}
              )
          ).map((pair) => ({ type: pair[0], flights: pair[1] })),
          passengers: b.passengers.map((p) => ({
            ...p,
            bags: p.bags ? p.bags.join(", ") : "-",
            email: p.email || "-",
            euroBonusNumber:
              p.euroBonusNumber && p.euroBonusNumber.length > 0
                ? p.euroBonusNumber
                : "-",
            name: `${toCapitalCase(p.firstName)} ${toCapitalCase(p.lastName)}`,
            phone: p.phone || "-",
            seats: p.seats ? p.seats.join(", ") : "-",
            ssrs: p.specialServiceRequests,
            ticketNumbers:
              p.ticketNumbers && p.ticketNumbers.length > 0
                ? p.ticketNumbers.join(", ")
                : "-"
          }))
        };
      });
    } else {
      this.bookings = undefined;
    }
  }

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

  async addBookingToCase(searchString) {
    this.showSpinner = true;
    try {
      await addBookingToCaseApex({
        caseId: this.caseId,
        bookingReference: searchString
      });
    } catch (error) {
      this.error = error;
    }
    setTimeout(() => {
      // Timeout because bookings haven't finished updating during the await
      refreshApex(this.wiredBookingsReference);
      this.displayAddAnotherBookingForm = false;
      this.showSpinner = false;
    }, 3000);
  }

  async removeBookingFromCase(event) {
    this.showSpinner = true;
    try {
      await removeBookingFromCaseApex({
        caseId: this.caseId,
        bookingReference:
          event.target.dataset.id === "last"
            ? this.bookings[this.bookings.length - 1].bookingReference
            : event.target.dataset.id
      });
    } catch (error) {
      this.error = error;
    }
    setTimeout(() => {
      // Timeout because bookings haven't finished updating during the await
      refreshApex(this.wiredBookingsReference);
      this.displayAddAnotherBookingForm = false;
      this.showSpinner = false;
    }, 3000);
  }

  async refreshBooking(event) {
    this.showSpinner = true;
    try {
      await refetchBookingDataApex({
        bookingReference: event.target.dataset.id
      });
    } catch (error) {
      this.error = error;
    }
    setTimeout(() => {
      // Timeout because bookings haven't finished updating during the await
      refreshApex(this.wiredBookingsReference);
      this.displayAddAnotherBookingForm = false;
      this.showSpinner = false;
    }, 6000);
  }

  handleDisplayAllFlights(event) {
    this.bookings = this.bookings.map((booking) =>
      booking.bookingReference === event.target.dataset.id
        ? {
            ...booking,
            displayDetails: {
              ...booking.displayDetails,
              showAllFlights: true
            }
          }
        : booking
    );
  }

  handleDisplayAllPassengers(event) {
    this.bookings = this.bookings.map((booking) =>
      booking.bookingReference === event.target.dataset.id
        ? {
            ...booking,
            displayDetails: {
              ...booking.displayDetails,
              showAllPassengers: true
            }
          }
        : booking
    );
  }

  flipDisplayAddAnotherBookingForm() {
    this.displayAddAnotherBookingForm = !this.displayAddAnotherBookingForm;
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
      this.addBookingToCase(this.searchValue);
    }
  }
}

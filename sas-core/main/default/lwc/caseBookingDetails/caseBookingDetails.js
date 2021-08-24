import { LightningElement, track, api, wire } from "lwc";
import addBookingToCaseApex from "@salesforce/apex/CustomerCardController.addBookingToCase";
import getBookingsForCaseApex from "@salesforce/apex/CustomerCardController.getBookingsForCase";
import removeBookingFromCaseApex from "@salesforce/apex/CustomerCardController.removeBookingFromCase";
import refetchBookingDataApex from "@salesforce/apex/CustomerCardController.refetchBookingData";
import { refreshApex } from "@salesforce/apex";

export default class CaseBookingDetails extends LightningElement {
  @api objectApiName;
  @api recordId;

  ENTRIES_TO_DISPLAY = 3;

  // data fields
  bookings = undefined;

  get visibleBookingData() {
    // Get only the booking data which should be visible

    return this.bookings
      ? this.bookings.map((booking) => ({
          ...booking,
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
                : this.ENTRIES_TO_DISPLAY
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
        }))
      : undefined;
  }

  wiredBookingsReference;

  // UI state
  @track showSpinner = false;
  @track noSearchResult = false;
  @track error = false;
  @track searchValue = "";
  displayAddAnotherBookingForm = false;

  @wire(getBookingsForCaseApex, { caseId: "$recordId" })
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

    if (data != undefined && data.length > 0) {
      this.bookings = data.map((b) => ({
        ...b,
        displayDetails: {
          showAllPassengers: b.passengers.length <= this.ENTRIES_TO_DISPLAY,
          showAllFlights: b.flights.length <= this.ENTRIES_TO_DISPLAY
        },
        trips: Object.entries(
          b.flights
            .map((f) => ({
              ...f,
              bookingClass: f.bookingClass || "-",
              fareBasis: f.fareBasis || "-",
              serviceClass: f.serviceClass || "-"
            }))
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
      }));
    } else {
      this.bookings = undefined;
    }
  }

  async addBookingToCase(searchString) {
    this.showSpinner = true;
    try {
      await addBookingToCaseApex({
        caseId: this.recordId,
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

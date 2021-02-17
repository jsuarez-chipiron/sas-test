/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description Passenger retrieve panel for the Manual Communication app.
 */

import TimeSegment__c from '@salesforce/schema/SBS_ScheduledBatchComponent__mdt.TimeSegment__c';
import {LightningElement, track} from 'lwc';

const DATE_TODAY = new Date().toJSON().slice(0,10);

export default class irr_RetrievePanel extends LightningElement {

    retrievalMode = "FLIGHT_REFERENCE";

    @track retrieveParameters = {};

    @track flights = [];

    @track bookings = [];

    flightKeyTracker = 0;

    bookingsKeyTracker = 0;

    showBookingFiltersTab = false;

    showBookingReferenceInput =true;

    connectedCallback() {
        //Initialize component with first flight
        this.handleFlightAdd();
    }

    handleKeyPress(event) {
        if (event.key === 'Enter') {
            this.handleRetrieve();
        }
    }

    handleAdvanceFilterChange(event) {
        if (event.target.checked){
            this.showBookingFiltersTab = true;
            this.showBookingReferenceInput = false;
            this.retrieveParameters = {};
            this.handleBookingAdd();
        }
        else {
            this.showBookingReferenceInput = true;
            this.showBookingFiltersTab = false;
            this.bookings = [];
        }
        
    }

    handleParameterChange(event) {
        //Text parameters should automatically be upper case
        this.retrieveParameters[event.target.name] = event.target.type === "text" ?
            event.target.value.toUpperCase() : event.target.value;

        this.retrievalMode = event.currentTarget.dataset.tabGroup;
    }

    handleFlightChange(event) {
        const { name, value, dataset: { flightIdx} } = event.target;
        this.flights[flightIdx][name] = event.target.type === "text" ? value.toUpperCase() : value;

    }

    handleBookingsFilter(event) {
        const { name, value, dataset: { bookingIdx } } = event.target;
        this.bookings[bookingIdx][name] = event.target.type === "text" ? value.toUpperCase() : value;
        this.retrievalMode = event.currentTarget.dataset.tabGroup;

    }

    handleFlightAdd() {
            const flightKey = ++this.flightKeyTracker;
            this.flights.push( { key: `flight-${flightKey}`, departureDate: DATE_TODAY } );
    }

    handleBookingAdd(){
        const bookingsKey = ++this.bookingsKeyTracker;
        this.bookings.push( { key: `bookings-${bookingsKey}` } );

    }

    handleFlightRemove(event) {
        const index = parseInt(event.currentTarget.dataset.flightIdx);
        this.flights.splice(index, 1);
    }
    handleBookingsRemove(event) {
        const index = parseInt(event.currentTarget.dataset.bookingIdx);
        this.bookings.splice(index, 1);

    }

    handleTabSwitch(event) {
        this.retrievalMode = event.target.value;
        this.showBookingFiltersTab = false;
        this.showBookingReferenceInput = true;

            let advanceFilterCheckbox = this.template.querySelector('[data-advance-filter = "checkbox"]');
            // when you query checkbox right after you switched the tab, the element
            // is stil not available in DOM at that time hence put a timeout 
            if (advanceFilterCheckbox != null) {
                setTimeout(()=>this.template.querySelector('[data-advance-filter = "checkbox"]').checked=false);
            }
            this.bookings = [];
    }
    validateFields() {
        return [...this.template.querySelectorAll(`lightning-input[data-tab-group="${this.retrievalMode}"]`)]
            .reduce((previousValue, cmp) => cmp.reportValidity() && previousValue, true);
    }

    handleRetrieve() {
        if (!this.validateFields()) return;
        if (this.retrievalMode === "FLIGHT_REFERENCE") this.constructFlightIds();
        if (this.retrievalMode === "BOOKING_FILTER") this.constructBookingIds();
        const retrievalEvent = new CustomEvent('retrieve' , {
            detail: { parameters: this.retrieveParameters, retrievalMode: this.retrievalMode }
        });
        this.dispatchEvent(retrievalEvent);
    }

    constructFlightIds() {
        this.retrieveParameters.flightIds = this.flights.map(flight => {
            const { flightNumber, departureDate, stationDeparture, stationArrival } = flight;
            return `SK${flightNumber.padStart(4, '0')}-${departureDate.replace(/-/g,'')}-${stationDeparture}-${stationArrival}`;
        }).join(',');
    }
    constructBookingIds(){
        this.retrieveParameters.bookingIds = this.bookings.map(booking => {
            const { departureStation, arrivalStation, departureDate, arrivalDate } = booking;
            return `${departureStation}!${arrivalStation}!${departureDate}!${arrivalDate}`;
        }).join(',');
    }

    handleBypass() {
        const retrievalEvent = new CustomEvent('retrieve' , {
            detail: { retrievalMode: 'BYPASS' }
        });
        this.dispatchEvent(retrievalEvent);
    }
}
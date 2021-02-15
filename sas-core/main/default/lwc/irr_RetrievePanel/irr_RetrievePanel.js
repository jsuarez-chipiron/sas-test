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
    // @track checkboxVal = false;

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
            this.handleFlightAdd();
        }
        else {
            this.showBookingReferenceInput = true;
            this.showBookingFiltersTab = false;
            this.bookings = [];
        }
        
    }

    handleParameterChange(event) {
        //Text parameters should automatically be upper case
        console.log(`retrieveParameters: ${JSON.stringify(this.retrieveParameters)}`);
        this.retrieveParameters[event.target.name] = event.target.type === "text" ?
            event.target.value.toUpperCase() : event.target.value;

        console.log(`retrieveParameters: ${JSON.stringify(this.retrieveParameters)}`);
        this.retrievalMode = event.currentTarget.dataset.tabGroup;
    }

    handleFlightChange(event) {
        const { name, value, dataset: { flightIdx} } = event.target;
        console.log(`dataset: ${JSON.stringify(event.target)}`);
        this.flights[flightIdx][name] = event.target.type === "text" ? value.toUpperCase() : value;
        console.log(`flights: ${JSON.stringify(this.flights)}`);

    }

    
    handleBookingsFilter(event) {
        const { name, value, dataset: { bookingIdx } } = event.target;
        this.bookings[bookingIdx][name] = event.target.type === "text" ? value.toUpperCase() : value;
        this.retrievalMode = event.currentTarget.dataset.tabGroup;

    }

    handleFlightAdd() {
        if(this.retrievalMode === "FLIGHT_REFERENCE"){
            const flightKey = ++this.flightKeyTracker;
            this.flights.push( { key: `flight-${flightKey}`, departureDate: DATE_TODAY } );
        }
        else {
            const bookingsKey = ++this.bookingsKeyTracker;
            this.bookings.push( { key: `bookings-${bookingsKey}`, departureDate: DATE_TODAY } );
        }
    }

    handleFlightRemove(event) {
        const index = parseInt(event.currentTarget.dataset.flightIdx);
        if (index >0){
            this.flights.splice(index, 1);
        }
    }
    handleBookingsRemove(event) {
        const index = parseInt(event.currentTarget.dataset.bookingIdx);
        this.bookings.splice(index, 1);

    }

    handleTabSwitch(event) {
        this.retrievalMode = event.target.value;
        this.showBookingFiltersTab = false;
        this.showBookingReferenceInput = true;
        // this.checkboxVal = false;

        let advanceFilterCheckbox =this.template.querySelectorAll('[data-advance-filter = "checkbox"]');
            console.log(`advanceFilterCheckbox: ${advanceFilterCheckbox.checked}`);
            advanceFilterCheckbox.checked = false;
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
        console.log(`retrievalEvent : ${JSON.stringify(retrievalEvent)}`);
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
            console.log(`retrieveParameters: ${JSON.stringify(this.retrieveParameters)}`);
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
/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description Passenger retrieve panel for the Manual Communication app.
 */

import {LightningElement, track} from 'lwc';

const DATE_TODAY = new Date().toJSON().slice(0,10);

export default class irr_RetrievePanel extends LightningElement {

    retrievalMode = "FLIGHT_REFERENCE";

    @track retrieveParameters = {};

    @track flights = [];

    flightKeyTracker = 0;

    connectedCallback() {
        //Initialize component with first flight
        this.handleFlightAdd();
    }

    handleKeyPress(event) {
        if (event.key === 'Enter') {
            this.handleRetrieve();
        }
    }

    handleParameterChange(event) {
        //Text parameters should automatically be upper case
        this.retrieveParameters[event.target.name] = event.target.type === "text" ?
            event.target.value.toUpperCase() : event.target.value;
    }

    handleFlightChange(event) {
        const { name, value, dataset: { flightIdx} } = event.target;
        this.flights[flightIdx][name] = event.target.type === "text" ? value.toUpperCase() : value;
    }

    handleFlightAdd() {
        const flightKey = ++this.flightKeyTracker;
        this.flights.push( { key: `flight-${flightKey}`, departureDate: DATE_TODAY } );
    }

    handleFlightRemove(event) {
        const index = parseInt(event.currentTarget.dataset.flightIdx);
        this.flights.splice(index, 1);
    }

    handleTabSwitch(event) {
        this.retrievalMode = event.target.value;
    }

    validateFields() {
        return [...this.template.querySelectorAll(`lightning-input[data-tab-group="${this.retrievalMode}"]`)]
            .reduce((previousValue, cmp) => cmp.reportValidity() && previousValue, true);
    }

    handleRetrieve() {
        if (!this.validateFields()) return;
        if (this.retrievalMode === "FLIGHT_REFERENCE") this.constructFlightIds();
        const retrievalEvent = new CustomEvent('retrieve' , {
            detail: { parameters: this.retrieveParameters, retrievalMode: this.retrievalMode }
        });
        this.dispatchEvent(retrievalEvent);
    }

    constructFlightIds() {
        this.retrieveParameters.flightIds = this.flights.map(flight => {
            const { flightNumber, departureDate, stationDeparture, stationArrival } = flight;
            return `SK${flightNumber}-${departureDate.replace(/-/g,'')}-${stationDeparture}-${stationArrival}`;
        }).join(',');
    }

    handleBypass() {
        const retrievalEvent = new CustomEvent('retrieve' , {
            detail: { retrievalMode: 'BYPASS' }
        });
        this.dispatchEvent(retrievalEvent);
    }
}
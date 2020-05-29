/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description Passenger retrieve panel for the Manual Communication app.
 */

import {LightningElement, track} from 'lwc';

export default class irr_RetrievePanel extends LightningElement {

    retrievalMode = "FLIGHT_REFERENCE";

    @track retrieveParameters = {departureDate: new Date().toJSON().slice(0,10)};

    handleKeyPress(event) {
        if (event.key === 'Enter') {
            this.handleRetrieve();
        }
    }

    handleParameterChange(event) {
        this.retrieveParameters[event.target.name] = event.target.type === "text" ?
            event.target.value.toUpperCase() : event.target.value;
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
        if (this.retrievalMode === "FLIGHT_REFERENCE") this.constructFlightId();
        const retrievalEvent = new CustomEvent('retrieve' , {
            detail: { parameters: this.retrieveParameters, retrievalMode: this.retrievalMode }
        });
        this.dispatchEvent(retrievalEvent);
    }

    constructFlightId() {
        const { flightNumber, departureDate, stationDeparture, stationArrival } = this.retrieveParameters;
        this.retrieveParameters.flightId =
            `${flightNumber}-${departureDate.replace(/-/g,'')}-${stationDeparture}-${stationArrival}`;
    }

    handleBypass() {
        const retrievalEvent = new CustomEvent('retrieve' , {
            detail: { retrievalMode: 'BYPASS' }
        });
        this.dispatchEvent(retrievalEvent);
    }
}
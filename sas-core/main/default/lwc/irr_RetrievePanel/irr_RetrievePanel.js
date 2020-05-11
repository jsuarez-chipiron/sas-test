/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description TODO
 */

import {LightningElement, track} from 'lwc';

export default class irr_RetrievePanel extends LightningElement {

    retrievalMode = "FLIGHT_REFERENCE";

    @track retrieveParameters = {};

    handleKeyPress(event) {
        if (event.key === 'Enter') {
            this.handleRetrieve();
        }
    }

    handleParameterChange(event) {
        this.retrieveParameters[event.target.name] = typeof event.target.value === 'string' ?
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
        const retrievalEvent = new CustomEvent('retrieve' , {
            detail: { parameters: this.retrieveParameters, retrievalMode: this.retrievalMode }
        });
        this.dispatchEvent(retrievalEvent);
    }
}
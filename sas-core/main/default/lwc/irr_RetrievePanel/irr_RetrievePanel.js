/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description TODO
 */

import {LightningElement} from 'lwc';

export default class irr_RetrievePanel extends LightningElement {

    retrievalMode = "FLIGHT_REFERENCE";

    retrieveParameters = {};

    handleParameterChange(event) {
        this.retrieveParameters[event.target.name] = event.target.value;
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
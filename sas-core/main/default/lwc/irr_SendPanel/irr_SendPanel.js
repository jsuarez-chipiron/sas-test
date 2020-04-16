/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description TODO
 */

import {LightningElement, api, track} from 'lwc';

export default class irr_SendPanel extends LightningElement {

    @api templatesBySendMode = {};

    @api flightId = '';

    @track showTemplatePicklist = false;

    manualTemplate = {};

    sendMode = "CUSTOM";

    sendParameters = {};

    connectedCallback() {
        this.setSendMode(this.sendMode);
        if (this.flightId) this.sendParameters.flightId = this.flightId;
    }

    handleParameterChange(event) {
        this.sendParameters[event.target.name] = event.target.value;
        console.log(JSON.stringify(this.sendParameters));
    }

    handleTabSwitch(event) {
        this.setSendMode(event.target.value);
    }

    setSendMode(sendMode) {
        this.sendMode = sendMode;
        if (this.templatesBySendMode[this.sendMode] && this.templatesBySendMode[this.sendMode].length === 1) {
            this.manualTemplate = this.templatesBySendMode[this.sendMode][0];
            this.showTemplatePicklist = false;
        }
        else {
            this.showTemplatePicklist = true;
        }
        console.log(JSON.stringify(this.manualTemplate));
    }

    handleSend() {
        const sendEvent = new CustomEvent('send', {
            detail: { sendMode: this.sendMode, parameters: this.sendParameters, manualTemplate: this.manualTemplate }
        });
        this.dispatchEvent(sendEvent);
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}
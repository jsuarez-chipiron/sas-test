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

    @track sendParameters = {};

    get customContentLabel() {
        const length = this.sendParameters && this.sendParameters.content ? this.sendParameters.content.length : 0;
        const smsMessages =  Math.ceil(length / 160);
        return length === 0 ? 'Content' : `Content - ${length} characters - ${smsMessages} SMS`;
    }

    connectedCallback() {
        this.setSendMode(this.sendMode);
        if (this.flightId) this.sendParameters.flightId = this.flightId;
    }

    handleParameterChange(event) {
        this.sendParameters[event.target.name] = event.target.value;
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
    }

    validateFields() {
        return [...this.template.querySelectorAll(`lightning-input[data-tab-group="${this.sendMode}"]`)]
            .reduce((previousValue, cmp) => cmp.reportValidity() && previousValue, true);
    }

    handleSend() {
        if (!this.validateFields()) return;
        const sendEvent = new CustomEvent('send', {
            detail: { sendMode: this.sendMode, parameters: this.sendParameters, manualTemplate: this.manualTemplate }
        });
        this.dispatchEvent(sendEvent);
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }
}
/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description TODO
 */

import {LightningElement, api, track} from 'lwc';

import { loadStyle } from 'lightning/platformResourceLoader';

import c_ComboBoxInlineGrid from '@salesforce/resourceUrl/c_ComboBoxInlineGrid'

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

    get templatePicklistOptions() {
        return this.templatesBySendMode[this.sendMode].map((template => {
            return { label: template.MasterLabel, value: template.DeveloperName };
        }));
    }

    handleTemplateChange(event) {
        this.manualTemplate = this.templatesBySendMode[this.sendMode]
            .find(template => template.DeveloperName === event.detail.value);
    }

    get cancelButtonClass() {
        return this.showTemplatePicklist ? "slds-p-right_small" : "";
    }

    connectedCallback() {
        loadStyle(this, c_ComboBoxInlineGrid);
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
        this.manualTemplate = this.templatesBySendMode[this.sendMode][0];
        this.showTemplatePicklist = this.templatesBySendMode[this.sendMode].length !== 1;
    }

    validateFields() {
        const inputArray = [...this.template.querySelectorAll(`lightning-input[data-tab-group="${this.sendMode}"]`)];
        inputArray.push(...this.template.querySelectorAll(`lightning-textarea[data-tab-group="${this.sendMode}"]`));
        return inputArray.reduce((previousValue, cmp) => cmp.reportValidity() && previousValue, true);
    }

    handleShowRecipientModal() {
        const event = new CustomEvent('showrecipientmodal');
        this.dispatchEvent(event);
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
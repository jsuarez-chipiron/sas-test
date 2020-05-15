/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description Send confirmation modal for the Manual Communication web app.
 */

import {LightningElement, api, track} from 'lwc';

export default class IRR_ConfirmationModal extends LightningElement {

    _confirmDetail;

    @api selectedCount;

    @api showConfirmation;

    @track sendSMS = false;

    @track sendEmail = false;

    @api
    get confirmDetail() {
        return this._confirmDetail;
    }

    set confirmDetail(value) {
        if (value && value.manualTemplate &&
                (!this._confirmDetail || value.manualTemplate !== this._confirmDetail.manualTemplate)) {
            this.sendEmail = value.manualTemplate.defaultSendEmail
            this.sendSMS = value.manualTemplate.defaultSendEmail;
        }
        this._confirmDetail = value;
    }

    get recipientText() {
        return this.selectedCount > 1 ? 'recipients' : 'recipient';
    }

    get modalClass() {
        return this.showConfirmation ? 'slds-modal slds-fade-in-open' : 'slds-modal';
    }

    get backdropClass() {
        return this.showConfirmation ? 'slds-backdrop slds-backdrop--open' : 'slds-backdrop';
    }

    get disableSMS() {
        return this.confirmDetail.manualTemplate && !this.confirmDetail.manualTemplate.smsTemplate;
    }

    get disableEmail() {
        return this.confirmDetail.manualTemplate && !this.confirmDetail.manualTemplate.emailTemplate;
    }

    handleChange(event) {
        this[event.target.name] = event.detail.checked;
    }

    reset() {
        this.sendSMS = false;
        this.sendEmail = false;
    }

    handleCancel() {
        const event = new CustomEvent("hideconfirm");
        this.dispatchEvent(event);
    }

    handleSend() {
        const event = new CustomEvent("sendconfirm", { detail: { sendSMS: this.sendSMS, sendEmail: this.sendEmail } });
        this.dispatchEvent(event);
        this.reset();
    }
}
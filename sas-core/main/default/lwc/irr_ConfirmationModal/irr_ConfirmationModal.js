/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description TODO
 */

import {LightningElement, api} from 'lwc';

export default class IRR_ConfirmationModal extends LightningElement {

    @api showConfirmation;

    @api confirmDetail;

    @api selectedCount;

    sendSMS = false;

    sendEmail = false;

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
        return this.confirmDetail.manualTemplate && !this.confirmDetail.manualTemplate.IRR_SMSTemplate__c;
    }

    get disableEmail() {
        return this.confirmDetail.manualTemplate && !this.confirmDetail.manualTemplate.IRR_EmailTemplate__c;
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
        this.reset();
    }

    handleSend() {
        const event = new CustomEvent("sendconfirm", { detail: { sendSMS: this.sendSMS, sendEmail: this.sendEmail } });
        this.dispatchEvent(event);
        this.reset();
    }
}
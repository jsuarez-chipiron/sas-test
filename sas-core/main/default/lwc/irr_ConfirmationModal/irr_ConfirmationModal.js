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

    @track displayScheduleTime = false;

    @track value = '';

    @track scheduleTime = '';

    @api
    get confirmDetail() {
        return this._confirmDetail;
    }

    set confirmDetail(value) {
        if (value && value.manualTemplate &&
                (!this._confirmDetail || value.manualTemplate !== this._confirmDetail.manualTemplate)) {
            this.sendEmail = value.manualTemplate.defaultSendEmail
            this.sendSMS = value.manualTemplate.defaultSendSMS;
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

    get sendOptions() {
        return [
            { label: 'Send Now', value: 'Now' },
            { label: 'Schedule Message', value: 'Schedule' },
        ];
    }

    handleChange(event) {
        this[event.target.name] = event.detail.checked;
    }

    reset() {
        this.sendEmail = this.confirmDetail ? this.confirmDetail.manualTemplate.defaultSendEmail : false;
        this.sendSMS = this.confirmDetail ? this.confirmDetail.manualTemplate.defaultSendSMS : false;
    }

    handleScheduleOptions(event){
        this.value = event.detail.value;
        if(event.detail.value == 'Schedule'){
            this.displayScheduleTime = true;
        }else{
            this.displayScheduleTime = false;
            this.scheduleTime = null;
        }
    }
    validateFields() {
        let dateCmp = this.template.querySelector(".dateCmp");
        let dtValue =  dateCmp.value;

        if(this.scheduleTime == null) {
            dateCmp.setCustomValidity("Date value is required");
            dateCmp.reportValidity();
            return false;
        }else {
            dateCmp.setCustomValidity("");
            dateCmp.reportValidity();
            return true;
        }
    }

    handleScheduleSendTime(event){
        this.scheduleTime = event.detail.value;
    }

    handleCancel() {
        const event = new CustomEvent("hideconfirm");
        this.dispatchEvent(event);
    }

    handleSend() {
        if (!this.validateFields()) return;
        const event = new CustomEvent("sendconfirm", { detail: {sendTime : this.scheduleTime, sendSMS: this.sendSMS, sendEmail: this.sendEmail } });
        this.dispatchEvent(event);
        this.reset();
    }
}
/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description TODO
 */

import {LightningElement, track} from 'lwc';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getFlightPassengerInfos from '@salesforce/apex/IRR_CON_ManualCommunication.getFlightPassengerInfos';
import sendManualCommunication from '@salesforce/apex/IRR_CON_ManualCommunication.sendManualCommunication';
import getManualTemplatesBySendMode from '@salesforce/apex/IRR_CON_ManualCommunication.getManualTemplatesBySendMode';
import getBookingPassengerInfos from '@salesforce/apex/IRR_CON_ManualCommunication.getBookingPassengerInfos';

import * as tableUtil from 'c/c_TableUtil';
import { reduceErrors } from 'c/c_LdsUtils';

const columns = [
    { label: 'PNR', fieldName: 'bookingReference', sortable: true, initialWidth: 75 },
    { label: 'Name', fieldName: 'lastNameSlashFirstName', sortable: true },
    { label: 'Phone', fieldName: 'phoneNumber', sortable: true, initialWidth: 115 },
    { label: 'Email', fieldName: 'emailAddress', sortable: true },
    { label: 'Serv Class', fieldName: 'thisSegment.serviceClass', sortable: true, initialWidth: 60 },
    { label: 'Bkg Class', fieldName: 'thisSegment.bookingClass', sortable: true, initialWidth: 60 },
    { label: 'Status', fieldName: 'thisSegment.status', sortable: true },
    { label: 'Code', fieldName: 'thisSegment.statusCode', sortable: true, initialWidth: 70 },
    { label: 'SSR', fieldName: 'SSR', sortable: true, initialWidth: 70 },
    { label: 'EB', fieldName: 'ebLevel', sortable: true, initialWidth: 50  },
    { label: 'FQTV', fieldName: 'otherFQTVCarrier', sortable: true, initialWidth: 70 },
];

export default class IRR_ManualCommunication extends LightningElement {

    @track columns = columns;

    @track passengerResult = [];

    @track sortBy = "bookingReference";

    @track sortDirection = "asc";

    @track hasResults;

    @track processedTable = [];

    @track showRetrieve = true;

    @track loadCount = 0;

    @track errors = [];
    @track criticalError = false;

    @track confirmDetail = {};
    @track showConfirmation = false;

    @track showSuccess = false;

    @track showRecipientModal = false;
    @track additionalRecipients = [];

    retrieveParameters = {};

    templatesBySendMode = {};

    selectedRows = [];

    filterParameters = {};

    connectedCallback() {
        const _ = this.init();
    }

    get noPassengersFoundText() {
        return this.passengerResult.length === 0 ?
            'No passengers found, or flight does not exist. Please check Flight ID.' : 'No passengers matching filter';
    }

    async init() {
        try {
            this.templatesBySendMode = await getManualTemplatesBySendMode();
        }
        catch (e) {
            this.handleError(e, true);
        }
    }

    get tableHeading() {
        const params = Object.values(this.retrieveParameters).join(' - ');
        return `Results for ${params}`;
    }

    handleLoad(finished) {
        if (finished && this.loadCount === 0) return;
        this.loadCount += finished ? -1 : 1;
    }

    handleError(error, critical) {
        this.loadCount = 0;
        if (critical) this.criticalError = critical;
        this.errors = reduceErrors(error);
    }

    clearErrors(_) {
        this.errors = [];
    }

    handleTableSelection(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    handleHideRecipientModal() {
        this.showRecipientModal = false;
    }

    handleShowRecipientModal() {
        this.showRecipientModal = true;
    }

    handleUpdateAdditionalRecipients(event) {
        this.additionalRecipients = event.detail;
        this.showRecipientModal = false;
    }

    handleFilterApplyEvent(event) {
        this.filterParameters = event.detail;
        this.processTable();
    }

    handleHideSuccessEvent() {
        this.showSuccess = false;
    }

    processTable() {
        let filteredList = tableUtil.filterData(this.passengerResult, this.filterParameters);
        tableUtil.sortData(filteredList, this.sortBy, this.sortDirection);
        this.hasResults = filteredList.length > 0;
        this.processedTable = filteredList;
    }

    handleTableSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.processTable();
    }

    handleHideConfirmEvent(_) {
        this.showConfirmation = false;
    }

    get recipientCount() {
        const additionalRecipients = this.additionalRecipients ?
            this.additionalRecipients.filter(r => r.phoneNumber || r.emailAddress).length : 0;
        const recipients = this.selectedRows ? this.selectedRows.length : 0;
        return additionalRecipients + recipients;
    }

    handleSendEvent(event) {
        if (this.recipientCount === 0){
            const toastEvent = new ShowToastEvent({
                title: 'No Recipients',
                message: 'Please select at least one recipient in order to continue.',
            });
            this.dispatchEvent(toastEvent);
            return;
        }
        this.confirmDetail = event.detail;
        this.showConfirmation = true;
    }

    async handleSendConfirmEvent(event) {
        try {
            this.showConfirmation = false;
            this.handleLoad(false);
            const { sendSMS, sendEmail } = event.detail;
            const { parameters, sendMode, manualTemplate } = this.confirmDetail;
            const passengerInfos = this.selectedRows.map(row => tableUtil.unFlatten(row));
            passengerInfos.push(...this.additionalRecipients.map((rec) => {
                return {
                    thisSegment: { flightId: this.retrieveParameters.flightId },
                    lastNameSlashFirstName: 'ADDITIONAL/RECIPIENT',
                    hasPhoneNumber: !!rec.phoneNumber,
                    hasEmailAddress: !!rec.emailAddress,
                    phoneNumber: rec.phoneNumber,
                    emailAddress: rec.emailAddress
                };
            }));
            const payload = {
                responseMessage: manualTemplate.IRR_ResponseTemplate__c,
                passengerInfos: passengerInfos,
                sendSMSMessages: sendSMS,
                sendEmailMessages: sendEmail,
                emailTemplate: manualTemplate.IRR_EmailTemplate__c,
                smsTemplate: manualTemplate.IRR_SMSTemplate__c
            };
            switch (sendMode) {
                case "CUSTOM":
                    payload.customInfo = parameters;
                    break;
                case "DELAY":
                    payload.delayInfo = parameters;
                    break;
                default:
                    return;
            }
            await sendManualCommunication({ manualRequest: payload });
            this.handleLoad(true);
            this.showSuccess = true;
        }
        catch (e) {
            this.handleError(e);
        }
    }

    handleResetEvent(_) {
        this.flightId = '';
        this.filterParameters = {};
        this.retrieveParameters = {};
        this.processedTable = [];
        this.passengerResult = [];
        this.additionalRecipients = [];
        this.template.querySelector('c-irr_-recipient-modal').reset();
        this.showRetrieve = true;
        this.showSuccess = false;
    }

    async handleRetrieveEvent(event) {
        try {
            this.handleLoad(false);
            const { parameters, retrievalMode }  = event.detail;
            let result;
            let eventParameters;
            switch (retrievalMode) {
                case "FLIGHT_REFERENCE":
                    eventParameters = {flightId: parameters.flightId};
                    result = await getFlightPassengerInfos(eventParameters);
                    break;
                case "BOOKING_REFERENCE":
                    eventParameters = {bookingId: parameters.bookingId};
                    result = await getBookingPassengerInfos(eventParameters);
                    break;
                default:
                    return;
            }
            this.retrieveParameters = eventParameters;
            this.passengerResult = result.map(item => tableUtil.flatten(item));
            this.processTable();
            this.showRetrieve = false;
            this.handleLoad(true);
        }
        catch (e) {
            this.handleError(e);
        }
    }
}
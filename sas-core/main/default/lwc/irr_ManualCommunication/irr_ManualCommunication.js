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
    { label: 'Booking Ref', fieldName: 'bookingReference', sortable: true },
    { label: 'Name', fieldName: 'lastName', sortable: true },
    { label: 'Phone', fieldName: 'phoneNumber', sortable: true },
    { label: 'Email Address', fieldName: 'emailAddress', sortable: true },
    { label: 'Status', fieldName: 'thisSegment.status', sortable: true },
    { label: 'Booking Class', fieldName: 'thisSegment.bookingClass', sortable: true },
    { label: 'SSR', fieldName: 'SSR', sortable: true  },
    { label: 'EB', fieldName: 'ebLevel', sortable: true, initialWidth: 50  },
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

    flightId = '';

    templatesBySendMode = {};

    selectedRows = [];

    filterParameters = {};

    connectedCallback() {
        const _ = this.init();
    }

    async init() {
        try {
            this.templatesBySendMode = await getManualTemplatesBySendMode();
            console.log(JSON.stringify(this.templatesBySendMode));
        }
        catch (e) {
            this.handleError(e, true);
        }
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

    handleFilterParameterChange(event) {
        this.filterParameters[event.target.name] = event.target.value;
        this.processTable();
    }

    handleHideSuccessEvent() {
        this.showSuccess = false;
    }

    processTable() {
        console.log(JSON.stringify(this.passengerResult));
        let filteredList = tableUtil.filterData(this.passengerResult, this.filterParameters);
        console.log(JSON.stringify(filteredList));
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

    handleSendEvent(event) {
        if (!this.selectedRows || this.selectedRows.length === 0){
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
                    hasPhoneNumber: !!rec.phoneNumber,
                    hasEmailAddress: !!rec.emailAddress,
                    phoneNumber: rec.phoneNumber,
                    emailAddress: rec.emailAddress
                };
            }));
            const payload = {
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
            console.log(JSON.stringify(payload));
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
        this.processedTable = [];
        this.passengerResult = [];
        this.showRetrieve = true;
        this.showSuccess = false;
    }

    async handleRetrieveEvent(event) {
        try {
            this.handleLoad(false);
            const { parameters, retrievalMode }  = event.detail;
            let result;
            switch (retrievalMode) {
                case "FLIGHT_REFERENCE":
                    this.flightId = parameters.flightId;
                    result = await getFlightPassengerInfos({flightId: parameters.flightId});
                    break;
                case "BOOKING_REFERENCE":
                    result = await getBookingPassengerInfos({bookingId: parameters.bookingId});
                    break;
                default:
                    return;
            }
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
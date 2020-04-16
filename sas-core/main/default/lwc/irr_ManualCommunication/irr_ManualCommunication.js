/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description TODO
 */

import {LightningElement, track} from 'lwc';

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
    { label: 'Booking Class', fieldName: 'thisSegment.bookingClass', sortable: true },
    { label: 'SSR', fieldName: 'thisSegment.SSR', sortable: true  },
    { label: 'EB', fieldName: 'ebLevel', sortable: true  },
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
        console.log(JSON.stringify(error));
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
        this.confirmDetail = event.detail;
        this.showConfirmation = true;
    }

    async handleSendConfirmEvent(event) {
        try {
            this.showConfirmation = false;
            this.handleLoad(false);
            const { sendSMS, sendEmail } = event.detail;
            const { parameters, sendMode, manualTemplate } = this.confirmDetail;
            const unFlattenedPassengers = this.selectedRows.map(row => tableUtil.unFlatten(row));
            const payload = {
                passengerInfos: unFlattenedPassengers,
                sendSMSMessages: sendSMS,
                sendEmailMessages: sendEmail,
                emailTemplate: manualTemplate.IRR_EmailTemplate__c,
                smsTemplate: manualTemplate.IRR_SMSTemplate__c
            };
            console.log(JSON.stringify(manualTemplate));
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
/**
 * @author Niklas Lundkvist, Deloitte
 * @date 2020
 *
 * @description LWC App for IRR Manual Communication.
 */

import {LightningElement, track, api} from 'lwc';
import { convertToCSV } from 'c/c_Json2CsvUtils';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getFlightPassengerInfos from '@salesforce/apex/IRR_CON_ManualCommunication.getFlightPassengerInfos';
import sendManualCommunication from '@salesforce/apex/IRR_CON_ManualCommunication.sendManualCommunication';
import getManualTemplatesBySendMode from '@salesforce/apex/IRR_CON_ManualCommunication.getManualTemplatesBySendMode';
import getBookingPassengerInfos from '@salesforce/apex/IRR_CON_ManualCommunication.getBookingPassengerInfos';
import getAdvancedFilterPassengerInfos from "@salesforce/apex/IRR_CON_ManualCommunication.getAdvancedFilterPassengerInfos";
import distributionList from '@salesforce/label/c.Distribution_Lists';

import * as tableUtil from 'c/c_TableUtil';
import { reduceErrors } from 'c/c_LdsUtils';

import { FLIGHT_COLUMNS, PREVIOUS_FLIGHT_COLUMNS, NEXT_FLIGHT_COLUMNS, BOOKING_COLUMNS, BOOKING_FILTER_COLUMNS} from './passengerTableColumns';

export default class IRR_ManualCommunication extends LightningElement {

    @track COLUMNS = [];

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

    @track showScheduleSuccess = false;

    @track showRecipientModal = false;

    @track additionalRecipients = [];

    @track additionalHotelRecipients = []

    @track leftPanelTab = "LEFT_FILTER";

    @track templatePreview = "";

    @track isDisabled = false;

    @api emailPicklistOptions = [];

    @track isHotelModel= false;

    @track passData;

    @track fileName;

    showEmailPicklist = false;

    retrieveParameters = {};

    templatesBySendMode = {};

    sendEmailResult = {};

    selectedRows = [];

    toAddresses = []; ;

    filterParameters = {};

    flightHeaders = {
        "thisSegment.flightId" :"Flight",
        "bookingReference":"PNR",
        "lastNameSlashFirstName":"Name",
        "phoneNumber":"Phone",
        "emailAddress":"Email",
        "thisSegment.serviceClass":"Service Class",
        "thisSegment.status":"Status",
        "SSR":"SSR",
        "ebLevel":"EB",
        "otherFQTVCarrier":"FQTV"
        
    };

    connectedCallback() {
        const _ = this.init();
        for(const emailList of distributionList.split(';')){
            const option = {
                label: emailList,
                value: emailList
            };
            this.emailPicklistOptions = [ ...this.emailPicklistOptions, option ];
        }
    }

    async init() {
        try {
            this.templatesBySendMode = await getManualTemplatesBySendMode();
        }
        catch (e) {
            this.handleError(e, true);
        }
    }

    get noPassengersFoundText() {
        return this.passengerResult.length === 0 ?
            'No passengers found, or flight does not exist. Please check Flight ID.' : 'No passengers matching filter';
    }

    get leftPanelTitle() {
        return this.leftPanelTab === "LEFT_FILTER" ? "Apply Filters" : "Preview Template";
    }

    get leftPanelIcon() {
        return this.leftPanelTab === "LEFT_FILTER" ? "utility:filterList" : "utility:preview";
    }

    get tableHeading() {
        if (Object.keys(this.retrieveParameters).length === 0) return "No filters active";
        if (this.retrieveParameters.hasOwnProperty('flightIds') || this.retrieveParameters.hasOwnProperty('bookings')) {
            const params = Object.values(this.retrieveParameters).join(" - ");
            return `Results for ${params}`;
        }
        else{
            const params = Object.values(this.retrieveParameters).join(" - ");
            const param = params.split(",");
            const tableHeadings = [];
            for(const p of param){
                const inputparam = p.split("!");
                const tableHeading = ` From:${inputparam[0]} To:${inputparam[1]}-
                ${inputparam[2].replaceAll(/-/g,'').replaceAll(/:00.000Z/g,'')}-${inputparam[3].replaceAll(/-/g,'').replaceAll(/:00.000Z/g,'')} `;
                tableHeadings.push(tableHeading);
            }
            const tableHeadingContent = tableHeadings.join('||');
            const trimmedTableHeading = tableHeadingContent.replaceAll('From:undefined','From:ALL');
            const trimmedTableHeadingFinal = trimmedTableHeading.replaceAll('To:undefined','To:ALL');

            return `Results for Bookings => ${trimmedTableHeadingFinal}`;
        }
       
    }

    get recipientCount() {
        const additionalRecipients = this.additionalRecipients ?
            this.additionalRecipients.filter(r => r.phoneNumber || r.emailAddress).length : 0;
        const recipients = this.selectedRows ? this.selectedRows.length : 0;
        return additionalRecipients + recipients;
    }

    handleGlobalKeyUp(event) {
        if (event.key === 'Escape') {
            if (this.errors && this.errors.length > 0 && !this.criticalError) this.clearErrors();
            else if (this.showConfirmation) this.handleHideConfirmEvent();
            else if (this.showRecipientModal) this.template.querySelector('c-irr_-recipient-modal').handleCancel();
            else if (this.showSuccess) this.handleHideSuccessEvent();
            else if (this.showScheduleSuccess) this.handleHideScheduleEvent();
            else if (!this.showRetrieve) this.handleResetEvent();
        }
    }

    handleEmailChange(event) {
        this.toAddresses = event.detail.value;
    }

    handleTabSwitch(event) {
        this.leftPanelTab = event.target.value;
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
        this.COLUMNS = [];
        if (this.filterParameters.hasNextSegment) {
            this.COLUMNS = NEXT_FLIGHT_COLUMNS;
        }
        else if (this.filterParameters.hasPrevSegment) {
            this.COLUMNS = PREVIOUS_FLIGHT_COLUMNS;
        }
        else if (!this.filterParameters.hasNextSegment && !this.filterParameters.hasPrevSegment) {
            this.COLUMNS = FLIGHT_COLUMNS;
        }
        else if (this.retrieveParameters.flightIds) {
            this.COLUMNS = FLIGHT_COLUMNS;
        }
        
        this.processTable();
    }

    handleHideSuccessEvent() {
        this.showSuccess = false;
        this.emailPicklistOptions = '';
    }

    handleHideScheduleEvent() {
        this.showScheduleSuccess = false;
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

    handleTemplateChange(event) {
        const { template } = event.detail;
        this.templatePreview = template.templatePreview;
        if (this.leftPanelTab !== "LEFT_PREVIEW") this.leftPanelTab = "LEFT_PREVIEW";
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
            const { sendTime, sendSMS, sendEmail } = event.detail;
            const { parameters, sendMode, manualTemplate } = this.confirmDetail;
            const passengerInfos = this.selectedRows.map(row => tableUtil.unFlatten(row));
            passengerInfos.push(...this.additionalRecipients.map((rec) => {
                return {
                    thisSegment: { flightId: this.retrieveParameters.flightIds },
                    lastNameSlashFirstName: 'ADDITIONAL/RECIPIENT',
                    hasPhoneNumber: !!rec.phoneNumber,
                    hasEmailAddress: !!rec.emailAddress,
                    phoneNumber: rec.phoneNumber,
                    emailAddress: rec.emailAddress
                };
            }));
            const payload = {
                responseMessage: manualTemplate.responseTemplate,
                passengerInfos: passengerInfos,
                sendSMSMessages: sendSMS,
                sendEmailMessages: sendEmail,
                sendMessageTime: sendTime,
                emailTemplate: manualTemplate.emailTemplate,
                smsTemplate: manualTemplate.smsTemplate
            };
            switch (sendMode) {
                case "CUSTOM":
                    payload.customInfo = parameters;
                    break;
                case "DELAY":
                    payload.delayInfo = parameters;
                    break;
                case "NEW_INFO":
                    payload.newInfo = parameters;
                    break;
                case "CANCEL":
                    payload.cancelInfo = parameters;
                    break;
                case "CHECKIN":
                    payload.checkinInfo = parameters;
                    break;
                case "SCHEDULED_CHANGE":
                    payload.scheduledChangeInfo = parameters;
                    break;
                case "REBOOK":
                    break;
                case "TEMPLATE":
                    break;
                default:
                    return;
            }
            await sendManualCommunication({ manualRequest: payload });
            this.handleLoad(true);

            if(sendTime !== null){
                this.showScheduleSuccess = true;
            }else{
                this.showSuccess = true;
            }
            
        }
        catch (e) {
            this.handleError(e);
        }
    }

    handleResetEvent(_) {
        this.flightId = '';
        this.retrieveParameters = {};
        this.processedTable = [];
        this.passengerResult = [];
        this.additionalRecipients = [];
        this.template.querySelector('c-irr_-recipient-modal').reset();
        this.leftPanelTab = "LEFT_FILTER";
        this.showRetrieve = true;
        this.showSuccess = false;
        this.showScheduleSuccess = false;
        this.emailPicklistOptions = '';
    }

    async handleRetrieveEvent(event) {
        try {
            this.handleLoad(false);
            const { parameters, retrievalMode }  = event.detail;
            let result;
            let eventParameters;
            switch (retrievalMode) {
                case "FLIGHT_REFERENCE":
                    this.COLUMNS = FLIGHT_COLUMNS;
                    eventParameters = {flightIds: parameters.flightIds};
                    result = await getFlightPassengerInfos(eventParameters);
                    this.filterParameters = {'thisSegment.status': ['Confirmed', 'SpaceAvailable', 'Waitlisted']};
                    break;
                case "BOOKING_REFERENCE":
                    this.COLUMNS = BOOKING_COLUMNS;
                    eventParameters = {bookings: parameters.bookingId};
                    result = await getBookingPassengerInfos(eventParameters);
                    this.filterParameters = {};
                    break;
                case "BOOKING_FILTER":
                    this.COLUMNS = BOOKING_FILTER_COLUMNS;
                    eventParameters = {bookingIds: parameters.bookingIds};
                    result = await getAdvancedFilterPassengerInfos(eventParameters);
                    this.filterParameters = {'thisSegment.status': ['Confirmed', 'SpaceAvailable', 'Waitlisted']};
                    break;
                case "BYPASS":
                    this.COLUMNS = [];
                    this.filterParameters = {};
                    break;
                default:
                    return;
            }
            if (eventParameters) this.retrieveParameters = eventParameters;
            if (result) this.passengerResult = result.map(item => tableUtil.flatten(item));
            if (result) this.passengerResultunflatten = result;
            this.processTable();
            //Focus container div to capture keyboard events
            this.template.querySelector('div[focusable=""]').focus();
            this.showRetrieve = false;
            this.handleLoad(true);
        }
        catch (e) {
            this.handleError(e);
        }
    }

    handleFileSend() {
        const passengerInfos = this.selectedRows.map(row => tableUtil.flatten(row));
        const params = Object.values(this.retrieveParameters).join(" - ");
        const param =  params.split('-');
        const [ flight,date,departureStation ] = param;
        this.fileName = `${flight}_${departureStation}_${date}`;
        if(this.selectedRows.length > 0) {
            this.isHotelModel  = true
            const csvData = convertToCSV(passengerInfos,this.flightHeaders);
            if(csvData == null) return;
            this.paxData = csvData;
            this.passengerCount = this.selectedRows.length;
        } else {
            const toastEvent = new ShowToastEvent({
                title: 'No Recipients Selected',
                message: 'Please select at least one recipient in order to email the Attachment.',
            });
           this.dispatchEvent(toastEvent);
           return;
        }
    

    }
    hideHotelModel(event){
        this.isHotelModel = event.detail;
    }

}